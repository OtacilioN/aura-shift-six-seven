import 'package:aura_shift_six_seven/core/rewarded_ads.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('non-release builds use only official Google test IDs', () {
    final config = AdMobConfig.forRelease(false);

    expect(config.appId, AdMobConfig.testAppId);
    expect(
      config.unitIdFor(RewardedPlacement.returnBonus),
      AdMobConfig.testRewardedUnitId,
    );
    expect(
      config.unitIdFor(RewardedPlacement.shopUpgrade),
      AdMobConfig.testRewardedUnitId,
    );
    expect(config.isProduction, isFalse);
  });

  test('release resolves the two production rewarded placements', () {
    final config = AdMobConfig.forRelease(true);

    expect(config.appId, AdMobConfig.productionAppId);
    expect(config.returnUnitId, AdMobConfig.productionReturnUnitId);
    expect(
      config.shopUpgradeUnitId,
      AdMobConfig.productionShopUpgradeUnitId,
    );
    expect(config.returnUnitId, isNot(config.shopUpgradeUnitId));
    expect(config.isProduction, isTrue);
  });

  test('production configuration rejects Google test inventory', () {
    const invalid = AdMobConfig(
      appId: AdMobConfig.testAppId,
      returnUnitId: AdMobConfig.testRewardedUnitId,
      shopUpgradeUnitId: AdMobConfig.testRewardedUnitId,
      isProduction: true,
    );

    expect(invalid.validate, throwsStateError);
  });

  test('malformed identifiers are rejected', () {
    const invalid = AdMobConfig(
      appId: 'not-an-app-id',
      returnUnitId: 'not-a-unit-id',
      shopUpgradeUnitId: 'also-invalid',
      isProduction: false,
    );

    expect(invalid.validate, throwsStateError);
  });
}
