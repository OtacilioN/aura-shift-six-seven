import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardedPlacement { returnBonus, shopUpgrade }

class AdMobConfig {
  const AdMobConfig({
    required this.appId,
    required this.returnUnitId,
    required this.shopUpgradeUnitId,
    required this.isProduction,
  });

  static const testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const testRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const productionAppId = 'ca-app-pub-1879801690271355~3301040623';
  static const productionReturnUnitId =
      'ca-app-pub-1879801690271355/8535542665';
  static const productionShopUpgradeUnitId =
      'ca-app-pub-1879801690271355/7922811916';

  factory AdMobConfig.forRelease(bool release) {
    final config = release
        ? const AdMobConfig(
            appId: productionAppId,
            returnUnitId: productionReturnUnitId,
            shopUpgradeUnitId: productionShopUpgradeUnitId,
            isProduction: true,
          )
        : const AdMobConfig(
            appId: testAppId,
            returnUnitId: testRewardedUnitId,
            shopUpgradeUnitId: testRewardedUnitId,
            isProduction: false,
          );
    config.validate();
    return config;
  }

  factory AdMobConfig.current() {
    const config = kReleaseMode
        ? AdMobConfig(
            appId: productionAppId,
            returnUnitId: productionReturnUnitId,
            shopUpgradeUnitId: productionShopUpgradeUnitId,
            isProduction: true,
          )
        : AdMobConfig(
            appId: testAppId,
            returnUnitId: testRewardedUnitId,
            shopUpgradeUnitId: testRewardedUnitId,
            isProduction: false,
          );
    config.validate();
    return config;
  }

  final String appId;
  final String returnUnitId;
  final String shopUpgradeUnitId;
  final bool isProduction;

  String unitIdFor(RewardedPlacement placement) => switch (placement) {
        RewardedPlacement.returnBonus => returnUnitId,
        RewardedPlacement.shopUpgrade => shopUpgradeUnitId,
      };

  void validate() {
    final appIdPattern = RegExp(r'^ca-app-pub-\d{16}~\d{10}$');
    final unitIdPattern = RegExp(r'^ca-app-pub-\d{16}/\d{10}$');
    if (!appIdPattern.hasMatch(appId) ||
        !unitIdPattern.hasMatch(returnUnitId) ||
        !unitIdPattern.hasMatch(shopUpgradeUnitId)) {
      throw StateError('Invalid AdMob configuration.');
    }
    if (isProduction &&
        (appId != productionAppId ||
            returnUnitId != productionReturnUnitId ||
            shopUpgradeUnitId != productionShopUpgradeUnitId)) {
      throw StateError('A production build must use this app\'s AdMob IDs.');
    }
  }
}

abstract class RewardedAds extends ChangeNotifier {
  Future<void> initialize();
  Future<void> setEnabled(bool enabled);
  Future<bool> show(RewardedPlacement placement);
  bool get privacyOptionsRequired;
  Future<bool> showPrivacyOptions();
}

/// Consent-aware rewarded ads with one preloaded ad per placement.
///
/// Debug and profile builds always use Google's official test inventory.
/// Release builds use this app's public AdMob identifiers.
class GoogleRewardedAds extends RewardedAds {
  GoogleRewardedAds({AdMobConfig? config})
      : config = config ?? AdMobConfig.current();

  static const _privacyChannel =
      MethodChannel('com.otaciliomaia.aurashiftsixseven/ad_privacy');
  static const _rewardedCacheLifetime = Duration(minutes: 55);

  final AdMobConfig config;
  final Map<RewardedPlacement, RewardedAd> _loadedAds = {};
  final Map<RewardedPlacement, int> _loadedAtMillis = {};
  final Map<RewardedPlacement, Future<RewardedAd?>> _loads = {};
  Future<void>? _initialization;
  bool _privacyConfigured = false;
  bool _consentUpdateSucceeded = false;
  bool _mobileAdsInitialized = false;
  Future<void>? _mobileAdsInitialization;
  bool _canRequestAds = false;
  bool _enabled = false;
  bool _privacyOptionsRequired = false;
  bool _showing = false;
  bool _disposed = false;

  @override
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  @override
  Future<void> initialize() async {
    final existing = _initialization;
    if (existing != null) {
      try {
        await existing;
      } catch (_) {}
      return;
    }
    final attempt = _initialize();
    _initialization = attempt;
    var completed = false;
    try {
      await attempt;
      completed = true;
    } catch (_) {
      // Ads fail closed; a later player action can retry in this process.
    } finally {
      if (identical(_initialization, attempt) &&
          (!completed || !_privacyConfigured || !_consentUpdateSucceeded)) {
        _initialization = null;
      }
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    final changed = enabled != _enabled;
    final wasInitialized = _initialization != null;
    _enabled = enabled;
    if (!_enabled) {
      _disposeCachedAds();
      return;
    }
    await initialize();
    if (changed && wasInitialized) await _syncConsentAndInitializeAds();
  }

  Future<void> _initialize() async {
    config.validate();
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.t),
      );
      if (defaultTargetPlatform == TargetPlatform.android) {
        // The Flutter wrapper does not yet expose TFAT TEEN or the publisher
        // personalization switch. The native bridge augments (rather than
        // replaces) the request configuration above.
        await _privacyChannel.invokeMethod<void>('configureTeenAds');
        unawaited(_refreshAgeSignalsInIsolation());
      }
    } catch (_) {
      // No request is made if the platform privacy configuration fails.
      return;
    }
    _privacyConfigured = true;

    final updated = await _requestConsentUpdate();
    var consentFlowSucceeded = updated;
    if (updated) {
      FormError? formError;
      try {
        await ConsentForm.loadAndShowConsentFormIfRequired(
          (error) => formError = error,
        );
      } catch (_) {
        consentFlowSucceeded = false;
      }
      if (formError != null) consentFlowSucceeded = false;
    }
    _consentUpdateSucceeded = consentFlowSucceeded;
    await _refreshPrivacyOptionsRequirement();
    await _syncConsentAndInitializeAds();
  }

  Future<void> _refreshAgeSignalsInIsolation() async {
    try {
      // The result is deliberately not returned to Dart, logged, persisted,
      // analyzed, or used by the advertising system.
      await _privacyChannel.invokeMethod<void>('refreshAgeSignals');
    } catch (_) {}
  }

  Future<bool> _requestConsentUpdate() async {
    final result = Completer<bool>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!result.isCompleted) result.complete(true);
        },
        (_) {
          if (!result.isCompleted) result.complete(false);
        },
      );
      return await result.future;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshPrivacyOptionsRequirement() async {
    var required = false;
    try {
      required = await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {}
    if (required == _privacyOptionsRequired) return;
    _privacyOptionsRequired = required;
    if (!_disposed) notifyListeners();
  }

  Future<void> _syncConsentAndInitializeAds() async {
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      _canRequestAds = false;
    }
    if (!_canRequestAds || !_enabled) {
      _disposeCachedAds();
      return;
    }
    if (!_mobileAdsInitialized) {
      final initialization = _mobileAdsInitialization ??=
          MobileAds.instance.initialize().then((_) {
        _mobileAdsInitialized = true;
      });
      try {
        await initialization;
      } catch (_) {
        if (identical(_mobileAdsInitialization, initialization)) {
          _mobileAdsInitialization = null;
        }
        rethrow;
      }
    }
    for (final placement in RewardedPlacement.values) {
      unawaited(_load(placement));
    }
  }

  Future<RewardedAd?> _load(RewardedPlacement placement) {
    final cached = _loadedAds[placement];
    final loadedAt = _loadedAtMillis[placement];
    final age = loadedAt == null
        ? _rewardedCacheLifetime.inMilliseconds
        : DateTime.now().millisecondsSinceEpoch - loadedAt;
    if (cached != null &&
        age >= 0 &&
        age < _rewardedCacheLifetime.inMilliseconds) {
      return Future.value(cached);
    }
    if (cached != null) {
      _loadedAds.remove(placement);
      _loadedAtMillis.remove(placement);
      cached.dispose();
    }
    final inFlight = _loads[placement];
    if (inFlight != null) return inFlight;
    if (!_enabled || !_canRequestAds || !_mobileAdsInitialized || _disposed) {
      return Future.value(null);
    }

    final completer = Completer<RewardedAd?>();
    _loads[placement] = completer.future;

    void failLoad() {
      if (identical(_loads[placement], completer.future)) {
        _loads.remove(placement);
      }
      if (!completer.isCompleted) completer.complete(null);
    }

    Future<void> startLoad() async {
      try {
        await RewardedAd.load(
          adUnitId: config.unitIdFor(placement),
          request: const AdRequest(nonPersonalizedAds: true),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              if (_disposed || !_enabled || !_canRequestAds) {
                ad.dispose();
                failLoad();
                return;
              }
              _loadedAds[placement] = ad;
              _loadedAtMillis[placement] =
                  DateTime.now().millisecondsSinceEpoch;
              if (identical(_loads[placement], completer.future)) {
                _loads.remove(placement);
              }
              if (!completer.isCompleted) completer.complete(ad);
            },
            onAdFailedToLoad: (_) => failLoad(),
          ),
        );
      } catch (_) {
        failLoad();
      }
    }

    unawaited(startLoad());
    return completer.future;
  }

  @override
  Future<bool> show(RewardedPlacement placement) async {
    if (!_enabled) return false;
    await initialize();
    if (!_enabled ||
        !_canRequestAds ||
        !_mobileAdsInitialized ||
        _showing ||
        _disposed) {
      return false;
    }
    final ad = await _load(placement);
    if (ad == null) return false;
    if (_showing || !_enabled || !_canRequestAds || _disposed) {
      if (!_showing) {
        _loadedAds.remove(placement);
        _loadedAtMillis.remove(placement);
        ad.dispose();
      }
      return false;
    }
    _loadedAds.remove(placement);
    _loadedAtMillis.remove(placement);
    _showing = true;
    var earned = false;
    var finished = false;
    final result = Completer<bool>();

    void finish(bool value) {
      if (finished) return;
      finished = true;
      ad.dispose();
      _showing = false;
      if (!result.isCompleted) result.complete(value);
      if (!_disposed && _enabled && _canRequestAds) {
        unawaited(_load(placement));
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(earned),
      onAdFailedToShowFullScreenContent: (_, __) => finish(false),
    );
    try {
      await ad.show(onUserEarnedReward: (_, __) => earned = true);
    } catch (_) {
      finish(false);
    }
    return result.future;
  }

  @override
  Future<bool> showPrivacyOptions() async {
    FormError? error;
    try {
      await ConsentForm.showPrivacyOptionsForm(
          (formError) => error = formError);
    } catch (_) {
      return false;
    }
    await _refreshPrivacyOptionsRequirement();
    await _syncConsentAndInitializeAds();
    return error == null;
  }

  void _disposeCachedAds() {
    for (final ad in _loadedAds.values) {
      ad.dispose();
    }
    _loadedAds.clear();
    _loadedAtMillis.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _disposeCachedAds();
    super.dispose();
  }
}
