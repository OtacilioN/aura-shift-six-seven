import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardedPlacement { returnBonus, auraComplement }

abstract interface class RewardedAds {
  Future<bool> show(RewardedPlacement placement);
}

/// Uses test IDs by default. Production unit IDs are injected at build time;
/// without one, the placement remains quietly unavailable to the player.
class GoogleRewardedAds implements RewardedAds {
  GoogleRewardedAds({String? returnUnitId, String? complementUnitId})
      : _unitIds = {
          RewardedPlacement.returnBonus: returnUnitId ??
              const String.fromEnvironment('RETURN_REWARDED_AD_UNIT_ID'),
          RewardedPlacement.auraComplement: complementUnitId ??
              const String.fromEnvironment('COMPLEMENT_REWARDED_AD_UNIT_ID'),
        };

  final Map<RewardedPlacement, String> _unitIds;
  bool _initialized = false;

  @override
  Future<bool> show(RewardedPlacement placement) async {
    final unitId = _unitIds[placement];
    if (unitId == null || unitId.isEmpty) return false;
    if (!_initialized) {
      await MobileAds.instance.initialize();
      _initialized = true;
    }
    final result = Completer<bool>();
    await RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(nonPersonalizedAds: true),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!result.isCompleted) result.complete(false);
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (!result.isCompleted) result.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (_, __) {
            if (!result.isCompleted) result.complete(true);
          });
        },
        onAdFailedToLoad: (_) {
          if (!result.isCompleted) result.complete(false);
        },
      ),
    );
    return result.future;
  }
}
