import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardedPlacement { returnBonus, shopUpgrade }

/// Observable lifecycle of the rewarded inventory for one placement.
enum RewardedAdAvailability {
  disabled,
  initializing,
  loading,
  ready,
  presenting,
  showing,
  unavailable,
}

enum RewardedAdDiagnosticKind {
  loadError,
  showError,
  consentError,
  timeout,
  internalError,
}

/// A privacy-safe copy of one mediation adapter response.
///
/// Request extras and ad-unit mappings are deliberately not retained.
@immutable
class RewardedAdAdapterDiagnostic {
  const RewardedAdAdapterDiagnostic({
    required this.adapterClassName,
    required this.latencyMillis,
    required this.adSourceName,
    required this.adSourceId,
    this.errorCode,
    this.errorDomain,
    this.errorMessage,
  });

  final String adapterClassName;
  final int latencyMillis;
  final String adSourceName;
  final String adSourceId;
  final int? errorCode;
  final String? errorDomain;
  final String? errorMessage;
}

/// Privacy-safe subset of AdMob's [ResponseInfo].
///
/// Values from `responseExtras` are intentionally omitted. Their keys are
/// enough to understand which diagnostic metadata was available without
/// retaining arbitrary platform-provided values.
@immutable
class RewardedAdResponseInfoDiagnostic {
  RewardedAdResponseInfoDiagnostic({
    required this.responseId,
    required this.mediationAdapterClassName,
    required List<RewardedAdAdapterDiagnostic> adapterResponses,
    required this.loadedAdapterClassName,
    required List<String> responseExtraKeys,
  })  : adapterResponses = List.unmodifiable(adapterResponses),
        responseExtraKeys = List.unmodifiable(responseExtraKeys);

  factory RewardedAdResponseInfoDiagnostic.fromResponseInfo(
    ResponseInfo info,
  ) {
    final extraKeys = info.responseExtras.keys.toList()..sort();
    return RewardedAdResponseInfoDiagnostic(
      responseId: info.responseId,
      mediationAdapterClassName: info.mediationAdapterClassName,
      adapterResponses: [
        for (final adapter in info.adapterResponses ?? const [])
          RewardedAdAdapterDiagnostic(
            adapterClassName: adapter.adapterClassName,
            latencyMillis: adapter.latencyMillis,
            adSourceName: adapter.adSourceName,
            adSourceId: adapter.adSourceId,
            errorCode: adapter.adError?.code,
            errorDomain: adapter.adError?.domain,
            errorMessage: adapter.adError?.message,
          ),
      ],
      loadedAdapterClassName: info.loadedAdapterResponseInfo?.adapterClassName,
      responseExtraKeys: extraKeys,
    );
  }

  final String? responseId;
  final String? mediationAdapterClassName;
  final List<RewardedAdAdapterDiagnostic> adapterResponses;
  final String? loadedAdapterClassName;
  final List<String> responseExtraKeys;
}

/// Structured diagnostic for the latest failure of a rewarded placement.
///
/// This object is kept in memory only and is never logged automatically.
@immutable
class RewardedAdDiagnostic {
  const RewardedAdDiagnostic({
    required this.kind,
    required this.domain,
    required this.code,
    required this.message,
    this.responseInfo,
  });

  factory RewardedAdDiagnostic.fromLoadAdError(LoadAdError error) {
    return RewardedAdDiagnostic(
      kind: RewardedAdDiagnosticKind.loadError,
      domain: error.domain,
      code: error.code,
      message: error.message,
      responseInfo: error.responseInfo == null
          ? null
          : RewardedAdResponseInfoDiagnostic.fromResponseInfo(
              error.responseInfo!,
            ),
    );
  }

  factory RewardedAdDiagnostic.fromAdError(AdError error) {
    return RewardedAdDiagnostic(
      kind: RewardedAdDiagnosticKind.showError,
      domain: error.domain,
      code: error.code,
      message: error.message,
    );
  }

  factory RewardedAdDiagnostic.timeout(String operation, Duration timeout) {
    return RewardedAdDiagnostic(
      kind: RewardedAdDiagnosticKind.timeout,
      domain: 'com.otaciliomaia.aurashiftsixseven.rewarded.timeout',
      code: 408,
      message: '$operation timed out after ${timeout.inMilliseconds} ms.',
    );
  }

  factory RewardedAdDiagnostic.consent(FormError error) {
    return RewardedAdDiagnostic(
      kind: RewardedAdDiagnosticKind.consentError,
      domain: 'com.google.android.ump',
      code: error.errorCode,
      message: error.message,
    );
  }

  factory RewardedAdDiagnostic.internal(String operation) {
    return RewardedAdDiagnostic(
      kind: RewardedAdDiagnosticKind.internalError,
      domain: 'com.otaciliomaia.aurashiftsixseven.rewarded',
      code: -1,
      message: '$operation failed.',
    );
  }

  final RewardedAdDiagnosticKind kind;
  final String domain;
  final int code;
  final String message;
  final RewardedAdResponseInfoDiagnostic? responseInfo;
}

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
  static const isExplicitTestMode = bool.fromEnvironment(
    'ADMOB_TEST_MODE',
    defaultValue: false,
  );

  factory AdMobConfig.forRelease(bool release) {
    return AdMobConfig.forBuild(release: release);
  }

  factory AdMobConfig.forBuild({
    required bool release,
    bool explicitTestMode = false,
  }) {
    final config = release && !explicitTestMode
        ? const AdMobConfig(
            appId: productionAppId,
            returnUnitId: productionReturnUnitId,
            shopUpgradeUnitId: productionShopUpgradeUnitId,
            isProduction: true,
          )
        : release
            ? const AdMobConfig(
                appId: productionAppId,
                returnUnitId: testRewardedUnitId,
                shopUpgradeUnitId: testRewardedUnitId,
                isProduction: false,
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
    // The explicit test branch is compile-time constant, so release AOT builds
    // retain only the selected inventory. Production remains the default.
    const config = !kReleaseMode
        ? AdMobConfig(
            appId: testAppId,
            returnUnitId: testRewardedUnitId,
            shopUpgradeUnitId: testRewardedUnitId,
            isProduction: false,
          )
        : isExplicitTestMode
            ? AdMobConfig(
                appId: productionAppId,
                returnUnitId: testRewardedUnitId,
                shopUpgradeUnitId: testRewardedUnitId,
                isProduction: false,
              )
            : AdMobConfig(
                appId: productionAppId,
                returnUnitId: productionReturnUnitId,
                shopUpgradeUnitId: productionShopUpgradeUnitId,
                isProduction: true,
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
  Future<bool> show(
    RewardedPlacement placement, {
    VoidCallback? onAdShowed,
    VoidCallback? onAdClosed,
  });
  RewardedAdAvailability availabilityFor(RewardedPlacement placement);
  RewardedAdDiagnostic? lastDiagnosticFor(RewardedPlacement placement);
  bool get privacyOptionsRequired;
  Future<bool> showPrivacyOptions();
}

/// Minimal seam around the plugin's rewarded object.
///
/// It is public only so deterministic tests can drive native callback order
/// without constructing plugin-owned [RewardedAd] instances.
@visibleForTesting
abstract interface class RewardedAdHandle {
  void setFullScreenCallbacks({
    required VoidCallback onShowed,
    required VoidCallback onDismissed,
    required ValueChanged<AdError> onFailedToShow,
  });

  Future<void> show({required VoidCallback onUserEarnedReward});
  Future<void> dispose();
}

@visibleForTesting
typedef RewardedAdLoader = Future<void> Function({
  required String adUnitId,
  required AdRequest request,
  required ValueChanged<RewardedAdHandle> onLoaded,
  required ValueChanged<LoadAdError> onFailedToLoad,
});

class _GoogleRewardedAdHandle implements RewardedAdHandle {
  _GoogleRewardedAdHandle(this.ad);

  final RewardedAd ad;

  @override
  void setFullScreenCallbacks({
    required VoidCallback onShowed,
    required VoidCallback onDismissed,
    required ValueChanged<AdError> onFailedToShow,
  }) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => onShowed(),
      onAdDismissedFullScreenContent: (_) => onDismissed(),
      onAdFailedToShowFullScreenContent: (_, error) => onFailedToShow(error),
    );
  }

  @override
  Future<void> show({required VoidCallback onUserEarnedReward}) {
    return ad.show(onUserEarnedReward: (_, __) => onUserEarnedReward());
  }

  @override
  Future<void> dispose() => ad.dispose();
}

Future<void> _loadGoogleRewardedAd({
  required String adUnitId,
  required AdRequest request,
  required ValueChanged<RewardedAdHandle> onLoaded,
  required ValueChanged<LoadAdError> onFailedToLoad,
}) {
  return RewardedAd.load(
    adUnitId: adUnitId,
    request: request,
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (ad) => onLoaded(_GoogleRewardedAdHandle(ad)),
      onAdFailedToLoad: onFailedToLoad,
    ),
  );
}

/// Consent-aware rewarded ads with one preloaded ad per placement.
///
/// Debug and profile builds always use Google's official test inventory.
/// Release builds use this app's public AdMob identifiers.
class GoogleRewardedAds extends RewardedAds {
  GoogleRewardedAds({
    AdMobConfig? config,
    RewardedAdLoader rewardedAdLoader = _loadGoogleRewardedAd,
    Duration umpTimeout = const Duration(seconds: 15),
    Duration consentFormTimeout = const Duration(minutes: 10),
    Duration loadTimeout = const Duration(seconds: 20),
    Duration showTimeout = const Duration(seconds: 15),
    Duration fullscreenTimeout = const Duration(minutes: 10),
  })  : assert(umpTimeout > Duration.zero),
        assert(consentFormTimeout > Duration.zero),
        assert(loadTimeout > Duration.zero),
        assert(showTimeout > Duration.zero),
        assert(fullscreenTimeout > Duration.zero),
        config = config ?? AdMobConfig.current(),
        _rewardedAdLoader = rewardedAdLoader,
        _umpTimeout = umpTimeout,
        _consentFormTimeout = consentFormTimeout,
        _loadTimeout = loadTimeout,
        _showTimeout = showTimeout,
        _fullscreenTimeout = fullscreenTimeout;

  @visibleForTesting
  factory GoogleRewardedAds.forTesting({
    required RewardedAdLoader rewardedAdLoader,
    Duration loadTimeout = const Duration(milliseconds: 10),
    Duration showTimeout = const Duration(milliseconds: 10),
    Duration fullscreenTimeout = const Duration(milliseconds: 10),
  }) {
    final ads = GoogleRewardedAds(
      config: AdMobConfig.forRelease(false),
      rewardedAdLoader: rewardedAdLoader,
      loadTimeout: loadTimeout,
      showTimeout: showTimeout,
      fullscreenTimeout: fullscreenTimeout,
    );
    ads
      .._privacyConfigured = true
      .._consentUpdateSucceeded = true
      .._mobileAdsInitialized = true
      .._canRequestAds = true
      .._enabled = true
      .._initialization = Future<void>.value();
    for (final placement in RewardedPlacement.values) {
      ads._availability[placement] = RewardedAdAvailability.unavailable;
    }
    return ads;
  }

  static const _privacyChannel =
      MethodChannel('com.otaciliomaia.aurashiftsixseven/ad_privacy');
  static const _rewardedCacheLifetime = Duration(minutes: 55);

  final AdMobConfig config;
  final RewardedAdLoader _rewardedAdLoader;
  final Duration _umpTimeout;
  final Duration _consentFormTimeout;
  final Duration _loadTimeout;
  final Duration _showTimeout;
  final Duration _fullscreenTimeout;
  final Map<RewardedPlacement, RewardedAdHandle> _loadedAds = {};
  final Map<RewardedPlacement, int> _loadedAtMillis = {};
  final Map<RewardedPlacement, Timer> _expiryTimers = {};
  final Map<RewardedPlacement, _RewardedLoadOperation> _loads = {};
  final Map<RewardedPlacement, RewardedAdAvailability> _availability = {
    for (final placement in RewardedPlacement.values)
      placement: RewardedAdAvailability.disabled,
  };
  final Map<RewardedPlacement, RewardedAdDiagnostic?> _diagnostics = {
    for (final placement in RewardedPlacement.values) placement: null,
  };
  Future<void>? _initialization;
  bool _privacyConfigured = false;
  bool _consentUpdateSucceeded = false;
  bool _mobileAdsInitialized = false;
  Future<void>? _mobileAdsInitialization;
  bool _canRequestAds = false;
  bool _enabled = false;
  bool _privacyOptionsRequired = false;
  bool _showing = false;
  VoidCallback? _cancelActiveShow;
  bool _disposed = false;

  @override
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  @override
  RewardedAdAvailability availabilityFor(RewardedPlacement placement) {
    return _availability[placement] ?? RewardedAdAvailability.unavailable;
  }

  @override
  RewardedAdDiagnostic? lastDiagnosticFor(RewardedPlacement placement) {
    return _diagnostics[placement];
  }

  @override
  Future<void> initialize() async {
    if (_disposed) return;
    final existing = _initialization;
    if (existing != null) {
      await existing;
      return;
    }
    final attempt = _initialize();
    _initialization = attempt;
    await attempt;
    if (identical(_initialization, attempt) &&
        (!_privacyConfigured ||
            !_consentUpdateSucceeded ||
            (_enabled && (!_canRequestAds || !_mobileAdsInitialized)))) {
      _initialization = null;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (_disposed) return;
    final changed = enabled != _enabled;
    final wasInitialized = _initialization != null;
    _enabled = enabled;
    if (!_enabled) {
      _cancelActiveShow?.call();
      _cancelPendingLoads();
      _disposeCachedAds();
      _setAllAvailability(RewardedAdAvailability.disabled);
      return;
    }
    if (changed) {
      _setAllAvailability(RewardedAdAvailability.initializing);
    }
    await initialize();
    if (changed && wasInitialized) await _syncConsentAndInitializeAds();
  }

  Future<void> _initialize() async {
    try {
      config.validate();
    } catch (_) {
      _failAll(RewardedAdDiagnostic.internal('admob.configuration'));
      return;
    }
    final requestConfigured = await _runRequiredOperation(
      () => MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.t),
      ),
      'admob.request_configuration',
      _umpTimeout,
    );
    if (!requestConfigured) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      // The Flutter wrapper does not yet expose TFAT TEEN or the publisher
      // personalization switch. The native bridge augments (rather than
      // replaces) the request configuration above.
      final teenConfigured = await _runRequiredOperation(
        () => _privacyChannel.invokeMethod<void>('configureTeenAds'),
        'privacy.configure_teen_ads',
        _umpTimeout,
      );
      if (!teenConfigured) return;
      unawaited(_refreshAgeSignalsInIsolation());
    }
    _privacyConfigured = true;

    final consentDiagnostic = await _requestConsentUpdate();
    if (consentDiagnostic != null) {
      _consentUpdateSucceeded = false;
      _failAll(consentDiagnostic);
      return;
    }
    FormError? formError;
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired(
        (error) => formError = error,
      ).timeout(_consentFormTimeout);
    } on TimeoutException {
      _consentUpdateSucceeded = false;
      _failAll(
        RewardedAdDiagnostic.timeout(
          'ump.consent_form',
          _consentFormTimeout,
        ),
      );
      return;
    } catch (_) {
      _consentUpdateSucceeded = false;
      _failAll(RewardedAdDiagnostic.internal('ump.consent_form'));
      return;
    }
    if (formError != null) {
      _consentUpdateSucceeded = false;
      _failAll(RewardedAdDiagnostic.consent(formError!));
      return;
    }
    _consentUpdateSucceeded = true;
    if (!await _refreshPrivacyOptionsRequirement()) return;
    await _syncConsentAndInitializeAds();
  }

  Future<bool> _runRequiredOperation(
    Future<void> Function() operation,
    String name,
    Duration timeout,
  ) async {
    try {
      await operation().timeout(timeout);
      return true;
    } on TimeoutException {
      _failAll(RewardedAdDiagnostic.timeout(name, timeout));
      return false;
    } catch (_) {
      _failAll(RewardedAdDiagnostic.internal(name));
      return false;
    }
  }

  Future<void> _refreshAgeSignalsInIsolation() async {
    try {
      // The result is deliberately not returned to Dart, logged, persisted,
      // analyzed, or used by the advertising system.
      await _privacyChannel
          .invokeMethod<void>('refreshAgeSignals')
          .timeout(_umpTimeout);
    } catch (_) {}
  }

  Future<RewardedAdDiagnostic?> _requestConsentUpdate() async {
    final result = Completer<RewardedAdDiagnostic?>();
    final watchdog = Timer(
      _umpTimeout,
      () {
        if (!result.isCompleted) {
          result.complete(
            RewardedAdDiagnostic.timeout(
              'ump.consent_update',
              _umpTimeout,
            ),
          );
        }
      },
    );
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!result.isCompleted) result.complete(null);
        },
        (error) {
          if (!result.isCompleted) {
            result.complete(RewardedAdDiagnostic.consent(error));
          }
        },
      );
      return await result.future;
    } catch (_) {
      if (!result.isCompleted) {
        result.complete(
          RewardedAdDiagnostic.internal('ump.consent_update'),
        );
      }
      return await result.future;
    } finally {
      watchdog.cancel();
    }
  }

  Future<bool> _refreshPrivacyOptionsRequirement() async {
    late final PrivacyOptionsRequirementStatus status;
    try {
      status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus()
          .timeout(_umpTimeout);
    } on TimeoutException {
      _failAll(
        RewardedAdDiagnostic.timeout('ump.privacy_status', _umpTimeout),
      );
      return false;
    } catch (_) {
      _failAll(RewardedAdDiagnostic.internal('ump.privacy_status'));
      return false;
    }
    final required = status == PrivacyOptionsRequirementStatus.required;
    if (required == _privacyOptionsRequired) return true;
    _privacyOptionsRequired = required;
    if (!_disposed) notifyListeners();
    return true;
  }

  Future<void> _syncConsentAndInitializeAds() async {
    if (!_enabled || _disposed || !_consentUpdateSucceeded) {
      _cancelPendingLoads();
      _disposeCachedAds();
      if (!_disposed) {
        _setAllAvailability(
          _enabled
              ? RewardedAdAvailability.unavailable
              : RewardedAdAvailability.disabled,
        );
      }
      return;
    }
    try {
      _canRequestAds = await ConsentInformation.instance
          .canRequestAds()
          .timeout(_umpTimeout);
    } on TimeoutException {
      _canRequestAds = false;
      _failAll(
        RewardedAdDiagnostic.timeout('ump.can_request_ads', _umpTimeout),
      );
      return;
    } catch (_) {
      _canRequestAds = false;
      _failAll(RewardedAdDiagnostic.internal('ump.can_request_ads'));
      return;
    }
    if (!_canRequestAds) {
      _cancelPendingLoads();
      _disposeCachedAds();
      _setAllAvailability(RewardedAdAvailability.unavailable);
      return;
    }
    if (!_mobileAdsInitialized) {
      final initialization = _mobileAdsInitialization ??=
          MobileAds.instance.initialize().then((_) {
        _mobileAdsInitialized = true;
      });
      try {
        await initialization.timeout(_umpTimeout);
      } on TimeoutException {
        if (identical(_mobileAdsInitialization, initialization)) {
          _mobileAdsInitialization = null;
        }
        _failAll(
          RewardedAdDiagnostic.timeout(
            'admob.mobile_ads_initialize',
            _umpTimeout,
          ),
        );
        return;
      } catch (_) {
        if (identical(_mobileAdsInitialization, initialization)) {
          _mobileAdsInitialization = null;
        }
        _failAll(
          RewardedAdDiagnostic.internal('admob.mobile_ads_initialize'),
        );
        return;
      }
    }
    for (final placement in RewardedPlacement.values) {
      unawaited(_load(placement));
    }
  }

  Future<RewardedAdHandle?> _load(RewardedPlacement placement) {
    final cached = _loadedAds[placement];
    final loadedAt = _loadedAtMillis[placement];
    final age = loadedAt == null
        ? _rewardedCacheLifetime.inMilliseconds
        : DateTime.now().millisecondsSinceEpoch - loadedAt;
    if (cached != null &&
        age >= 0 &&
        age < _rewardedCacheLifetime.inMilliseconds) {
      _setAvailability(placement, RewardedAdAvailability.ready);
      return Future.value(cached);
    }
    if (cached != null) {
      _loadedAds.remove(placement);
      _loadedAtMillis.remove(placement);
      _expiryTimers.remove(placement)?.cancel();
      _disposeAd(cached);
    }
    final inFlight = _loads[placement];
    if (inFlight != null) return inFlight.completer.future;
    if (!_enabled || !_canRequestAds || !_mobileAdsInitialized || _disposed) {
      _setAvailability(
        placement,
        _enabled
            ? RewardedAdAvailability.unavailable
            : RewardedAdAvailability.disabled,
      );
      return Future.value(null);
    }

    final operation = _RewardedLoadOperation();
    _loads[placement] = operation;
    _setAvailability(placement, RewardedAdAvailability.loading);

    bool isCurrent() => identical(_loads[placement], operation);

    void failLoad(RewardedAdDiagnostic diagnostic) {
      if (!isCurrent()) return;
      _loads.remove(placement);
      operation.watchdog?.cancel();
      _setDiagnostic(placement, diagnostic);
      _setAvailability(
        placement,
        _enabled
            ? RewardedAdAvailability.unavailable
            : RewardedAdAvailability.disabled,
      );
      if (!operation.completer.isCompleted) {
        operation.completer.complete(null);
      }
    }

    operation.watchdog = Timer(
      _loadTimeout,
      () => failLoad(
        RewardedAdDiagnostic.timeout('admob.rewarded_load', _loadTimeout),
      ),
    );

    Future<void> startLoad() async {
      try {
        await _rewardedAdLoader(
          adUnitId: config.unitIdFor(placement),
          request: AdRequest(
            nonPersonalizedAds: true,
            httpTimeoutMillis: _loadTimeout.inMilliseconds,
          ),
          onLoaded: (ad) {
            if (!isCurrent() || _disposed || !_enabled || !_canRequestAds) {
              _disposeAd(ad);
              if (isCurrent()) {
                failLoad(
                  RewardedAdDiagnostic.internal(
                    'admob.rewarded_load_cancelled',
                  ),
                );
              }
              return;
            }
            _loads.remove(placement);
            operation.watchdog?.cancel();
            _loadedAds[placement] = ad;
            _loadedAtMillis[placement] = DateTime.now().millisecondsSinceEpoch;
            _setDiagnostic(placement, null);
            _setAvailability(placement, RewardedAdAvailability.ready);
            _expiryTimers.remove(placement)?.cancel();
            _expiryTimers[placement] = Timer(
              _rewardedCacheLifetime,
              () => _expireCachedAd(placement, ad),
            );
            if (!operation.completer.isCompleted) {
              operation.completer.complete(ad);
            }
          },
          onFailedToLoad: (error) {
            failLoad(RewardedAdDiagnostic.fromLoadAdError(error));
          },
        );
      } catch (_) {
        failLoad(RewardedAdDiagnostic.internal('admob.rewarded_load'));
      }
    }

    unawaited(startLoad());
    return operation.completer.future;
  }

  @override
  Future<bool> show(
    RewardedPlacement placement, {
    VoidCallback? onAdShowed,
    VoidCallback? onAdClosed,
  }) async {
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
        _expiryTimers.remove(placement)?.cancel();
        _disposeAd(ad);
      }
      return false;
    }
    _loadedAds.remove(placement);
    _loadedAtMillis.remove(placement);
    _expiryTimers.remove(placement)?.cancel();
    _showing = true;
    _setAvailability(placement, RewardedAdAvailability.presenting);
    var earned = false;
    var opened = false;
    var finished = false;
    final result = Completer<bool>();
    Timer? watchdog;

    void finish(bool value) {
      if (finished) return;
      finished = true;
      watchdog?.cancel();
      _disposeAd(ad);
      _showing = false;
      _cancelActiveShow = null;
      if (opened) _invokeSafely(onAdClosed);
      if (!result.isCompleted) result.complete(value);
      if (!_disposed && _enabled && _canRequestAds) {
        _setAvailability(placement, RewardedAdAvailability.unavailable);
        unawaited(_load(placement));
      } else if (!_disposed) {
        _setAvailability(
          placement,
          _enabled
              ? RewardedAdAvailability.unavailable
              : RewardedAdAvailability.disabled,
        );
      }
    }

    ad.setFullScreenCallbacks(
      onShowed: () {
        if (finished || opened) return;
        opened = true;
        watchdog?.cancel();
        _setAvailability(placement, RewardedAdAvailability.showing);
        _invokeSafely(onAdShowed);
        watchdog = Timer(
          _fullscreenTimeout,
          () {
            if (finished) return;
            _setDiagnostic(
              placement,
              RewardedAdDiagnostic.timeout(
                'admob.rewarded_fullscreen',
                _fullscreenTimeout,
              ),
            );
            finish(earned);
          },
        );
      },
      onDismissed: () => finish(earned),
      onFailedToShow: (error) {
        if (finished) return;
        _setDiagnostic(
          placement,
          RewardedAdDiagnostic.fromAdError(error),
        );
        finish(false);
      },
    );

    _cancelActiveShow = () => finish(false);
    watchdog = Timer(
      _showTimeout,
      () {
        if (finished) return;
        _setDiagnostic(
          placement,
          RewardedAdDiagnostic.timeout(
            'admob.rewarded_present',
            _showTimeout,
          ),
        );
        finish(false);
      },
    );
    Future<void> invokeShow() async {
      try {
        await ad.show(onUserEarnedReward: () {
          if (!finished) earned = true;
        });
      } catch (_) {
        if (finished) return;
        _setDiagnostic(
          placement,
          RewardedAdDiagnostic.internal('admob.rewarded_show'),
        );
        finish(false);
      }
    }

    unawaited(invokeShow());
    return result.future;
  }

  @override
  Future<bool> showPrivacyOptions() async {
    FormError? error;
    try {
      await ConsentForm.showPrivacyOptionsForm(
        (formError) => error = formError,
      ).timeout(_consentFormTimeout);
    } on TimeoutException {
      _recordAllDiagnostic(
        RewardedAdDiagnostic.timeout(
          'ump.privacy_options_form',
          _consentFormTimeout,
        ),
      );
      return false;
    } catch (_) {
      _recordAllDiagnostic(
        RewardedAdDiagnostic.internal('ump.privacy_options_form'),
      );
      return false;
    }
    if (error != null) {
      _recordAllDiagnostic(RewardedAdDiagnostic.consent(error!));
      return false;
    }
    if (!await _refreshPrivacyOptionsRequirement()) return false;
    await _syncConsentAndInitializeAds();
    return true;
  }

  void _expireCachedAd(
    RewardedPlacement placement,
    RewardedAdHandle ad,
  ) {
    if (!identical(_loadedAds[placement], ad)) return;
    _loadedAds.remove(placement);
    _loadedAtMillis.remove(placement);
    _expiryTimers.remove(placement)?.cancel();
    _disposeAd(ad);
    if (!_disposed && _enabled && _canRequestAds) {
      _setAvailability(placement, RewardedAdAvailability.unavailable);
      unawaited(_load(placement));
    }
  }

  void _cancelPendingLoads() {
    final operations = _loads.values.toList();
    _loads.clear();
    for (final operation in operations) {
      operation.watchdog?.cancel();
      if (!operation.completer.isCompleted) {
        operation.completer.complete(null);
      }
    }
  }

  void _disposeCachedAds() {
    for (final timer in _expiryTimers.values) {
      timer.cancel();
    }
    _expiryTimers.clear();
    for (final ad in _loadedAds.values) {
      _disposeAd(ad);
    }
    _loadedAds.clear();
    _loadedAtMillis.clear();
  }

  void _setAvailability(
    RewardedPlacement placement,
    RewardedAdAvailability availability,
  ) {
    if (_availability[placement] == availability) return;
    _availability[placement] = availability;
    if (!_disposed) notifyListeners();
  }

  void _setAllAvailability(RewardedAdAvailability availability) {
    for (final placement in RewardedPlacement.values) {
      _setAvailability(placement, availability);
    }
  }

  void _setDiagnostic(
    RewardedPlacement placement,
    RewardedAdDiagnostic? diagnostic,
  ) {
    if (identical(_diagnostics[placement], diagnostic)) return;
    if (_diagnostics[placement] == null && diagnostic == null) return;
    _diagnostics[placement] = diagnostic;
    if (!_disposed) notifyListeners();
  }

  void _recordAllDiagnostic(RewardedAdDiagnostic diagnostic) {
    for (final placement in RewardedPlacement.values) {
      _setDiagnostic(placement, diagnostic);
    }
  }

  void _failAll(RewardedAdDiagnostic diagnostic) {
    _canRequestAds = false;
    _cancelPendingLoads();
    _disposeCachedAds();
    _recordAllDiagnostic(diagnostic);
    if (!_disposed) {
      _setAllAvailability(
        _enabled
            ? RewardedAdAvailability.unavailable
            : RewardedAdAvailability.disabled,
      );
    }
  }

  void _invokeSafely(VoidCallback? callback) {
    if (callback == null) return;
    try {
      callback();
    } catch (_) {}
  }

  void _disposeAd(RewardedAdHandle ad) {
    Future<void> disposeSafely() async {
      try {
        await ad.dispose();
      } catch (_) {}
    }

    unawaited(disposeSafely());
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelActiveShow?.call();
    _cancelActiveShow = null;
    _cancelPendingLoads();
    _disposeCachedAds();
    super.dispose();
  }
}

class _RewardedLoadOperation {
  final Completer<RewardedAdHandle?> completer = Completer<RewardedAdHandle?>();
  Timer? watchdog;
}
