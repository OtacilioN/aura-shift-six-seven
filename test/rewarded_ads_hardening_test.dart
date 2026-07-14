import 'package:aura_shift_six_seven/core/rewarded_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  test('rewarded placements start disabled with no diagnostic', () {
    final ads = GoogleRewardedAds(config: AdMobConfig.forRelease(false));

    for (final placement in RewardedPlacement.values) {
      expect(
        ads.availabilityFor(placement),
        RewardedAdAvailability.disabled,
      );
      expect(ads.lastDiagnosticFor(placement), isNull);
    }

    ads.dispose();
  });

  test('load errors retain safe response information', () {
    // These constructors are protected for plugin implementers, but creating
    // the value objects directly keeps this diagnostic test platform-free.
    // ignore: invalid_use_of_protected_member
    const responseInfo = ResponseInfo(
      responseId: 'response-id',
      mediationAdapterClassName: 'adapter.Class',
      adapterResponses: [],
      loadedAdapterResponseInfo: null,
      responseExtras: {
        'safe-key-b': 'value-that-must-not-be-retained',
        'safe-key-a': 42,
      },
    );
    // ignore: invalid_use_of_protected_member
    final error = LoadAdError(
      3,
      'com.google.android.gms.ads',
      'No fill.',
      responseInfo,
    );

    final diagnostic = RewardedAdDiagnostic.fromLoadAdError(error);

    expect(diagnostic.kind, RewardedAdDiagnosticKind.loadError);
    expect(diagnostic.code, 3);
    expect(diagnostic.domain, 'com.google.android.gms.ads');
    expect(diagnostic.message, 'No fill.');
    expect(diagnostic.responseInfo?.responseId, 'response-id');
    expect(
      diagnostic.responseInfo?.responseExtraKeys,
      ['safe-key-a', 'safe-key-b'],
    );
  });

  test('timeout diagnostics are deterministic and structured', () {
    final diagnostic = RewardedAdDiagnostic.timeout(
      'admob.rewarded_load',
      const Duration(seconds: 20),
    );

    expect(diagnostic.kind, RewardedAdDiagnosticKind.timeout);
    expect(diagnostic.code, 408);
    expect(
      diagnostic.message,
      'admob.rewarded_load timed out after 20000 ms.',
    );
    expect(diagnostic.responseInfo, isNull);
  });

  test('load watchdog completes show and exposes unavailable state', () async {
    final loader = _FakeRewardedLoader();
    final ads = GoogleRewardedAds.forTesting(
      rewardedAdLoader: loader.load,
      loadTimeout: const Duration(milliseconds: 5),
    );

    final result = await ads.show(RewardedPlacement.returnBonus);

    expect(result, isFalse);
    expect(loader.requests, hasLength(1));
    expect(
      ads.availabilityFor(RewardedPlacement.returnBonus),
      RewardedAdAvailability.unavailable,
    );
    expect(
      ads.lastDiagnosticFor(RewardedPlacement.returnBonus)?.kind,
      RewardedAdDiagnosticKind.timeout,
    );
    ads.dispose();
  });

  test('late loaded callback is disposed and cannot revive timed-out load',
      () async {
    final loader = _FakeRewardedLoader();
    final ads = GoogleRewardedAds.forTesting(
      rewardedAdLoader: loader.load,
      loadTimeout: const Duration(milliseconds: 5),
    );
    final lateAd = _FakeRewardedAdHandle();

    expect(await ads.show(RewardedPlacement.shopUpgrade), isFalse);
    loader.requests.single.onLoaded(lateAd);
    await Future<void>.delayed(Duration.zero);

    expect(lateAd.disposeCount, 1);
    expect(
      ads.availabilityFor(RewardedPlacement.shopUpgrade),
      RewardedAdAvailability.unavailable,
    );
    expect(
      ads.lastDiagnosticFor(RewardedPlacement.shopUpgrade)?.kind,
      RewardedAdDiagnosticKind.timeout,
    );
    ads.dispose();
  });

  test('no-fill callback completes show with the SDK diagnostic', () async {
    final loader = _FakeRewardedLoader();
    final ads = GoogleRewardedAds.forTesting(
      rewardedAdLoader: loader.load,
      loadTimeout: const Duration(seconds: 1),
    );

    final result = ads.show(RewardedPlacement.returnBonus);
    await _waitUntil(() => loader.requests.isNotEmpty);
    // ignore: invalid_use_of_protected_member
    loader.requests.single.onFailedToLoad(
      LoadAdError(3, 'com.google.android.gms.ads', 'No fill.', null),
    );

    expect(await result, isFalse);
    expect(
      ads.availabilityFor(RewardedPlacement.returnBonus),
      RewardedAdAvailability.unavailable,
    );
    final diagnostic = ads.lastDiagnosticFor(RewardedPlacement.returnBonus);
    expect(diagnostic?.kind, RewardedAdDiagnosticKind.loadError);
    expect(diagnostic?.code, 3);
    expect(diagnostic?.message, 'No fill.');
    ads.dispose();
  });

  test('fullscreen callbacks pause and resume exactly once', () async {
    final loader = _FakeRewardedLoader();
    final ads = GoogleRewardedAds.forTesting(
      rewardedAdLoader: loader.load,
      loadTimeout: const Duration(seconds: 1),
      showTimeout: const Duration(seconds: 1),
    );
    final ad = _FakeRewardedAdHandle();
    var opened = 0;
    var closed = 0;

    final result = ads.show(
      RewardedPlacement.returnBonus,
      onAdShowed: () => opened += 1,
      onAdClosed: () => closed += 1,
    );
    await _waitUntil(() => loader.requests.isNotEmpty);
    loader.requests.first.onLoaded(ad);
    await _waitUntil(() => ad.onShowed != null);
    ad
      ..emitShowed()
      ..emitReward()
      ..emitDismissed()
      ..emitDismissed();

    expect(await result, isTrue);
    expect(opened, 1);
    expect(closed, 1);
    expect(ad.disposeCount, 1);
    ads.dispose();
  });

  test('fullscreen watchdog preserves an already earned reward', () async {
    final loader = _FakeRewardedLoader();
    final ads = GoogleRewardedAds.forTesting(
      rewardedAdLoader: loader.load,
      loadTimeout: const Duration(seconds: 1),
      showTimeout: const Duration(seconds: 1),
      fullscreenTimeout: const Duration(milliseconds: 5),
    );
    final ad = _FakeRewardedAdHandle();
    var opened = 0;
    var closed = 0;

    final result = ads.show(
      RewardedPlacement.shopUpgrade,
      onAdShowed: () => opened += 1,
      onAdClosed: () => closed += 1,
    );
    await _waitUntil(() => loader.requests.isNotEmpty);
    loader.requests.first.onLoaded(ad);
    await _waitUntil(() => ad.onShowed != null);
    ad
      ..emitShowed()
      ..emitReward();

    expect(await result, isTrue);
    ad.emitDismissed();
    expect(opened, 1);
    expect(closed, 1);
    expect(ad.disposeCount, 1);
    ads.dispose();
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt += 1) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(condition(), isTrue);
}

class _FakeRewardedLoader {
  final List<_FakeLoadRequest> requests = [];

  Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required ValueChanged<RewardedAdHandle> onLoaded,
    required ValueChanged<LoadAdError> onFailedToLoad,
  }) async {
    requests.add(
      _FakeLoadRequest(
        onLoaded: onLoaded,
        onFailedToLoad: onFailedToLoad,
      ),
    );
  }
}

class _FakeLoadRequest {
  const _FakeLoadRequest({
    required this.onLoaded,
    required this.onFailedToLoad,
  });

  final ValueChanged<RewardedAdHandle> onLoaded;
  final ValueChanged<LoadAdError> onFailedToLoad;
}

class _FakeRewardedAdHandle implements RewardedAdHandle {
  VoidCallback? onShowed;
  VoidCallback? onDismissed;
  ValueChanged<AdError>? onFailedToShow;
  VoidCallback? onReward;
  int disposeCount = 0;

  @override
  void setFullScreenCallbacks({
    required VoidCallback onShowed,
    required VoidCallback onDismissed,
    required ValueChanged<AdError> onFailedToShow,
  }) {
    this.onShowed = onShowed;
    this.onDismissed = onDismissed;
    this.onFailedToShow = onFailedToShow;
  }

  @override
  Future<void> show({required VoidCallback onUserEarnedReward}) async {
    onReward = onUserEarnedReward;
  }

  void emitShowed() => onShowed?.call();
  void emitDismissed() => onDismissed?.call();
  void emitReward() => onReward?.call();

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}
