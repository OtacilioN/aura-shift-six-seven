import 'dart:convert';

import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final appearanceIds = upgrades
      .where((upgrade) => !upgrade.isTechnique)
      .map((upgrade) => upgrade.id)
      .toList(growable: false);

  Future<GameController> controllerWith(Map<String, dynamic> state) async {
    SharedPreferences.setMockInitialValues({'save-v1': jsonEncode(state)});
    return GameController.loadForTesting();
  }

  test('conflicting legacy slots can be active and toggled independently',
      () async {
    final controller = await controllerWith({
      'available': '540',
      'journey': '540',
      'total': '540',
      'levels': {'TECH-01': 1},
    });
    final button = upgrades.firstWhere((u) => u.id == 'ITEM-A-01');
    final badge = upgrades.firstWhere((u) => u.id == 'ITEM-C-01');

    expect(controller.buy(button, 1), isTrue);
    expect(controller.buy(badge, 1), isTrue);
    expect(
      controller.equippedAppearances,
      containsAll(<String>{button.id, badge.id}),
    );

    expect(
      controller.setAppearanceEquipped(button.id, equipped: false),
      isTrue,
    );
    expect(controller.equippedAppearances, {badge.id});
    expect(controller.appearances, containsAll([button.id, badge.id]));
    controller.dispose();
  });

  test('all 18 owned appearances remain active in canonical order', () async {
    final controller = await controllerWith({
      'appearances': [...appearanceIds.reversed, appearanceIds.first],
      'equippedAppearances': [...appearanceIds.reversed, appearanceIds.first],
    });

    expect(controller.appearances, appearanceIds);
    expect(controller.equippedAppearances, appearanceIds.toSet());
    final exported = controller.captureSaveState();
    expect(exported['equippedAppearances'], appearanceIds);
    expect(exported.containsKey('equipped'), isFalse);
    controller.dispose();
  });

  test('legacy singular equipment migrates without activating other items',
      () async {
    final controller = await controllerWith({
      'appearances': ['ITEM-A-01', 'ITEM-C-01'],
      'equipped': 'ITEM-C-01',
    });

    expect(controller.equippedAppearances, {'ITEM-C-01'});
    final exported = controller.captureSaveState();
    expect(exported['equippedAppearances'], ['ITEM-C-01']);
    expect(exported.containsKey('equipped'), isFalse);
    controller.dispose();
  });

  test('unknown and unowned appearances cannot be activated', () async {
    final controller = await controllerWith({
      'appearances': ['ITEM-A-01'],
      'equippedAppearances': ['ITEM-A-01'],
    });

    expect(
      controller.setAppearanceEquipped('ITEM-C-01', equipped: true),
      isFalse,
    );
    expect(
      controller.setAppearanceEquipped('ITEM-UNKNOWN', equipped: true),
      isFalse,
    );
    expect(controller.equippedAppearances, {'ITEM-A-01'});
    controller.dispose();
  });

  test('invalid plural cloud state is rejected atomically', () async {
    final controller = await controllerWith({
      'available': '7',
      'journey': '7',
      'total': '7',
      'appearances': ['ITEM-A-01'],
      'equippedAppearances': ['ITEM-A-01'],
    });
    final before = controller.captureSaveState()..remove('totalPlayTimeMillis');

    final restored = await controller.replaceAuthoritativeState({
      'saveVersion': 1,
      'arithVersion': 'arith-v1',
      'available': '0',
      'journey': '0',
      'total': '0',
      'remainder': '0',
      'multiplier': '100',
      'ascensions': 0,
      'appearances': ['ITEM-A-01'],
      'equippedAppearances': ['ITEM-C-01'],
    });
    final after = controller.captureSaveState()..remove('totalPlayTimeMillis');

    expect(restored, isFalse);
    expect(after, before);
    controller.dispose();
  });

  test('Ascension preserves every active appearance', () async {
    final controller = await controllerWith({
      'journey': '1000000000000000',
      'total': '1000000000000000',
      'levels': {'ITEM-A-01': 25, 'ITEM-C-01': 10},
      'appearances': appearanceIds,
      'equippedAppearances': appearanceIds,
    });

    expect(controller.canAscend, isTrue);
    controller.ascend();
    expect(controller.levels, isEmpty);
    expect(controller.appearances, appearanceIds);
    expect(controller.equippedAppearances, appearanceIds.toSet());
    controller.dispose();
  });

  test('readquisition preserves a hidden preference', () async {
    final controller = await controllerWith({
      'available': '270',
      'journey': '270',
      'total': '270',
      'levels': {'TECH-01': 1},
      'appearances': ['ITEM-A-01'],
      'equippedAppearances': <String>[],
    });
    final item = upgrades.firstWhere((u) => u.id == 'ITEM-A-01');

    expect(controller.buy(item, 1), isTrue);
    expect(controller.equippedAppearances, isEmpty);
    controller.dispose();
  });
}
