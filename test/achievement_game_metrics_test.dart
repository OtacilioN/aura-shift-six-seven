import 'dart:convert';

import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('old saves reconstruct Six Seven and manual counts without resetting',
      () async {
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({
        'cycles': 2,
        'phase': 'seven',
      }),
    });

    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);

    expect(controller.sixMovements, 3);
    expect(controller.sevenMovements, 2);
    expect(controller.manualMovements, 5);
    expect(controller.auraProducingMovements, 2);
    expect(controller.distinctPlayDays, hasLength(1));
  });

  test('opening twice on the same local day never duplicates day progress',
      () async {
    SharedPreferences.setMockInitialValues({});
    final first = await GameController.loadForTesting();
    await first.flushLocal();
    final firstDays = first.distinctPlayDays;
    first.dispose();

    final second = await GameController.loadForTesting();
    addTearDown(second.dispose);
    expect(second.distinctPlayDays, firstDays);
    expect(second.distinctPlayDays, hasLength(1));
  });

  test('offline achievement records only an actually applied positive reward',
      () async {
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({
        'returnReward': {
          'id': 'offline-1',
          'awayMilliseconds': 700000,
          'creditedMilliseconds': 700000,
          'baseQuanta': '10000000',
          'bonusQuanta': '0',
          'baseStatus': 'available',
          'bonusStatus': 'ineligible',
          'adsEligibilityVersion': 1,
        },
      }),
    });
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);

    expect(controller.offlineRewardsCollected, 0);
    expect(controller.claimReturnBase(), isTrue);
    expect(controller.offlineRewardsCollected, 1);
    expect(controller.claimReturnBase(), isFalse);
    expect(controller.offlineRewardsCollected, 1);
  });

  test('zero offline reward never records collection', () async {
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({
        'returnReward': {
          'id': 'offline-zero',
          'awayMilliseconds': 700000,
          'creditedMilliseconds': 700000,
          'baseQuanta': '0',
          'bonusQuanta': '0',
          'baseStatus': 'available',
          'bonusStatus': 'ineligible',
          'adsEligibilityVersion': 1,
        },
      }),
    });
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);

    expect(controller.claimReturnBase(), isTrue);
    expect(controller.offlineRewardsCollected, 0);
  });

  test('FortyTwo history survives the level reset caused by Ascension',
      () async {
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({
        'available': '0',
        'total': '1000000000000000',
        'journey': '1000000000000000',
        'remainder': '0',
        'multiplier': '100',
        'ascensionAura': '0',
        'ascensions': 0,
        'levels': {'TECH-06': 1},
      }),
    });
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);

    expect(controller.unlockedTechniqueIds, contains('TECH-06'));
    expect(controller.canAscend, isTrue);
    controller.ascend();
    expect(controller.level('TECH-06'), 0);
    expect(controller.unlockedTechniqueIds, contains('TECH-06'));
  });

  test('authoritative restore does not leak metrics from another profile',
      () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);
    for (var index = 0; index < 10; index++) {
      controller.tap();
    }
    expect(controller.manualMovements, 10);

    final candidate = controller.captureSaveState()
      ..['cycles'] = 0
      ..['manualMovements'] = 0
      ..['auraProducingMovements'] = 0
      ..['sixMovements'] = 0
      ..['sevenMovements'] = 0
      ..['purchaseCount'] = 0
      ..['offlineRewardsCollected'] = 0
      ..['levels'] = <String, int>{}
      ..['unlockedTechniqueIds'] = <String>[];

    expect(await controller.replaceAuthoritativeState(candidate), isTrue);
    expect(controller.manualMovements, 0);
    expect(controller.sixMovements, 0);
    expect(controller.sevenMovements, 0);
  });
}
