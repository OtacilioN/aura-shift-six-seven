import 'dart:convert';

import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<GameController> controllerWith(Map<String, dynamic> state) async {
    SharedPreferences.setMockInitialValues({'save-v1': jsonEncode(state)});
    return GameController.loadForTesting();
  }

  test('Six is non-economic and Seven credits exact base cycle power',
      () async {
    final controller = await controllerWith({});
    controller.tap();
    expect(controller.available, BigInt.zero);
    expect(controller.phase, CyclePhase.seven);
    controller.tap();
    expect(controller.available, BigInt.one);
    expect(controller.total, BigInt.one);
    expect(controller.journey, BigInt.one);
    controller.dispose();
  });

  test('cost is calculated independently from the base at each level',
      () async {
    final controller = await controllerWith({});
    final root = upgrades.firstWhere((u) => u.id == 'ITEM-A-01');
    expect(controller.price(root, 0), BigInt.from(270));
    expect(controller.price(root, 1), BigInt.from(311));
    expect(controller.price(root, 2), BigInt.from(358));
    controller.dispose();
  });

  test('batch quotes use cumulative cost and MAX reports exact quantity',
      () async {
    final root = upgrades.firstWhere((u) => u.id == 'ITEM-A-01');
    final controller = await controllerWith({
      'available': '581',
      'total': '581',
      'levels': {'TECH-01': 1},
    });

    final ten = controller.purchaseQuote(root, 10);
    expect(ten.cost, BigInt.from(5487));
    expect(ten.affordable, isFalse);

    final max = controller.purchaseQuote(root, -1);
    expect(max.quantity, 2);
    expect(max.cost, BigInt.from(581));
    expect(max.affordable, isTrue);

    expect(controller.buy(root, -1), isTrue);
    expect(controller.level(root.id), 2);
    expect(controller.available, BigInt.zero);
    controller.dispose();
  });

  test('zero quantity is rejected instead of behaving like MAX', () async {
    final root = upgrades.firstWhere((u) => u.id == 'ITEM-A-01');
    final controller = await controllerWith({
      'available': '581',
      'total': '581',
      'levels': {'TECH-01': 1},
    });

    final quote = controller.purchaseQuote(root, 0);
    expect(quote.quantity, 0);
    expect(quote.cost, BigInt.zero);
    expect(quote.affordable, isFalse);
    expect(controller.buy(root, 0), isFalse);
    expect(controller.level(root.id), 0);
    expect(controller.available, BigInt.from(581));
    controller.dispose();
  });

  test('batch purchase enforces the exact cumulative ten-level boundary',
      () async {
    final root = upgrades.firstWhere((u) => u.id == 'ITEM-A-01');
    final below = await controllerWith({
      'available': '5486',
      'total': '5486',
      'journey': '5486',
      'levels': {'TECH-01': 1},
    });
    expect(below.buy(root, 10), isFalse);
    expect(below.available, BigInt.from(5486));
    expect(below.total, BigInt.from(5486));
    expect(below.journey, BigInt.from(5486));
    expect(below.level(root.id), 0);
    expect(below.appearances, isEmpty);
    below.dispose();

    final exact = await controllerWith({
      'available': '5487',
      'total': '5487',
      'journey': '5487',
      'levels': {'TECH-01': 1},
    });
    expect(exact.buy(root, 10), isTrue);
    expect(exact.available, BigInt.zero);
    expect(exact.total, BigInt.from(5487));
    expect(exact.journey, BigInt.from(5487));
    expect(exact.level(root.id), 10);
    expect(exact.appearances, contains(root.id));
    exact.dispose();
  });

  test('MAX quote is disabled when the next level is unaffordable', () async {
    final root = upgrades.firstWhere((u) => u.id == 'ITEM-A-01');
    final controller = await controllerWith({
      'available': '269',
      'total': '269',
      'levels': {'TECH-01': 1},
    });
    final quote = controller.purchaseQuote(root, -1);
    expect(quote.quantity, 0);
    expect(quote.cost, BigInt.zero);
    expect(quote.affordable, isFalse);
    expect(controller.buy(root, -1), isFalse);
    controller.dispose();
  });

  test('Convergence exposes and evaluates all branch requirements separately',
      () async {
    final convergence = upgrades.firstWhere((u) => u.id == 'ITEM-CONV-01');
    final controller = await controllerWith({
      'total': '1000',
      'levels': {
        'ITEM-A-01': 10,
        'ITEM-B-01': 10,
        'ITEM-C-01': 9,
      },
    });

    final requirements = controller.requirementsFor(convergence);
    expect(requirements, hasLength(4));
    expect(requirements.where(controller.requirementMet), hasLength(3));
    expect(controller.isUnlocked(convergence), isFalse);
    expect(
      requirements
          .where((requirement) => !controller.requirementMet(requirement))
          .single
          .upgradeId,
      'ITEM-C-01',
    );
    controller.dispose();
  });

  test('later Techniques use the nerfed balance-v0.2 contributions', () async {
    expect(
      upgrades.where((upgrade) => upgrade.isTechnique).map((u) => u.base20),
      [
        BigInt.from(20),
        BigInt.from(100),
        BigInt.from(100000),
        BigInt.from(100000000),
        BigInt.from(100000000000),
        BigInt.from(100000000000000),
      ],
    );

    final levelOne = await controllerWith({
      'levels': {'TECH-02': 1},
    });
    expect(levelOne.power20, BigInt.from(120));
    expect(levelOne.powerNumerator, BigInt.from(12000));
    levelOne.dispose();

    final levelNine = await controllerWith({
      'levels': {'TECH-02': 9},
    });
    final levelTen = await controllerWith({
      'levels': {'TECH-02': 10},
    });
    expect(levelNine.power20, BigInt.from(920));
    expect(levelTen.power20, BigInt.from(2020));
    expect(
      levelTen.powerNumerator - levelNine.powerNumerator,
      BigInt.from(110000),
    );
    levelNine.dispose();
    levelTen.dispose();
  });

  test('first Ascension adds rather than compounds the multiplier', () async {
    final controller = await controllerWith({
      'journey': '1000000000000000',
      'total': '1000000000000000',
      'multiplier': 100
    });
    expect(controller.canAscend, isTrue);
    controller.ascend();
    expect(controller.multiplier, BigInt.from(200));
    expect(controller.available, BigInt.zero);
    expect(controller.journey, BigInt.zero);
    expect(controller.total, BigInt.parse('1000000000000000'));
    controller.dispose();
  });

  test('Ascension uses cumulative sacrificed Aura with diminishing returns',
      () async {
    final secondAscension = await controllerWith({
      'journey': '1000000000000000',
      'total': '2000000000000000',
      'multiplier': '200',
      'ascensions': 1,
    });
    expect(secondAscension.ascensionAura, BigInt.parse('1000000000000000'));
    expect(secondAscension.ascensionGain(), BigInt.from(41));
    secondAscension.ascend();
    expect(secondAscension.multiplier, BigInt.from(241));
    expect(secondAscension.ascensionAura, BigInt.parse('2000000000000000'));
    secondAscension.dispose();

    const expectedMultipliers = [
      200,
      241,
      273,
      300,
      323,
      344,
      364,
      382,
      400,
      416
    ];
    for (var ascension = 1;
        ascension <= expectedMultipliers.length;
        ascension++) {
      final previousAura =
          BigInt.from(ascension - 1) * BigInt.parse('1000000000000000');
      final previousMultiplier =
          ascension == 1 ? 100 : expectedMultipliers[ascension - 2];
      final controller = await controllerWith({
        'journey': '1000000000000000',
        'total': '${BigInt.from(ascension) * BigInt.parse('1000000000000000')}',
        'multiplier': '$previousMultiplier',
        'ascensions': ascension - 1,
        'ascensionAura': '$previousAura',
      });
      controller.ascend();
      expect(
        controller.multiplier,
        BigInt.from(expectedMultipliers[ascension - 1]),
        reason: 'unexpected multiplier after Ascension $ascension',
      );
      controller.dispose();
    }
  });

  test('Ascension reward is invariant to partitioning the same Aura', () async {
    final oneLongJourney = await controllerWith({
      'journey': '4000000000000000',
      'total': '4000000000000000',
    });
    expect(oneLongJourney.ascensionGain(), BigInt.from(200));

    final fourthShortJourney = await controllerWith({
      'journey': '1000000000000000',
      'total': '4000000000000000',
      'multiplier': '273',
      'ascensions': 3,
      'ascensionAura': '3000000000000000',
    });
    expect(fourthShortJourney.ascensionGain(), BigInt.from(27));

    oneLongJourney.ascend();
    fourthShortJourney.ascend();
    expect(oneLongJourney.multiplier, BigInt.from(300));
    expect(fourthShortJourney.multiplier, BigInt.from(300));
    oneLongJourney.dispose();
    fourthShortJourney.dispose();
  });

  test('legacy repeated-Ascension saves migrate to the cumulative curve',
      () async {
    final controller = await controllerWith({
      'available': '0',
      'journey': '0',
      'total': '10000000000000000',
      'multiplier': '1100',
      'ascensions': 10,
    });

    expect(controller.ascensionAura, BigInt.parse('10000000000000000'));
    expect(controller.multiplier, BigInt.from(416));

    final exported =
        jsonDecode(controller.exportState()) as Map<String, dynamic>;
    expect(exported['balanceVersion'], balanceVersion);
    expect(exported['ascensionAura'], '10000000000000000');
    controller.dispose();

    final longerJourneys = await controllerWith({
      'total': '8000000000000000',
      'multiplier': '500',
      'ascensions': 2,
    });
    expect(longerJourneys.ascensionAura, BigInt.parse('8000000000000000'));
    expect(longerJourneys.multiplier, BigInt.from(382));
    longerJourneys.dispose();
  });

  test('balance-v0.1 backups remain importable and migrate once', () async {
    final controller = await controllerWith({});
    final imported = await controller.restoreState(jsonEncode({
      'saveVersion': 1,
      'arithVersion': 'arith-v1',
      'balanceVersion': 'balance-v0.1',
      'available': '123',
      'journey': '456',
      'total': '2000000000000456',
      'remainder': '999',
      'multiplier': '300',
      'ascensions': 2,
      'levels': {'TECH-01': 2},
      'appearances': ['ITEM-A-01'],
      'achievements': ['ACH-V-01'],
    }));

    expect(imported, isTrue);
    expect(controller.ascensionAura, BigInt.parse('2000000000000000'));
    expect(controller.multiplier, BigInt.from(241));
    expect(controller.available, BigInt.from(123));
    expect(controller.journey, BigInt.from(456));
    expect(controller.remainder, BigInt.from(999));
    expect(controller.level('TECH-01'), 2);
    expect(controller.appearances, ['ITEM-A-01']);
    expect(controller.achievements, {'ACH-V-01'});
    final reexported =
        jsonDecode(controller.exportState()) as Map<String, dynamic>;
    expect(reexported['balanceVersion'], balanceVersion);
    expect(await controller.restoreState(jsonEncode(reexported)), isTrue);
    expect(controller.ascensionAura, BigInt.parse('2000000000000000'));
    expect(controller.multiplier, BigInt.from(241));
    controller.dispose();
  });

  test('balance-v0.2 backups require their canonical Ascension pool', () async {
    final controller = await controllerWith({
      'available': '7',
      'journey': '7',
      'total': '7',
    });
    final before = jsonDecode(controller.exportState()) as Map<String, dynamic>
      ..remove('exportedAt');
    final imported = await controller.restoreState(jsonEncode({
      'saveVersion': 1,
      'arithVersion': 'arith-v1',
      'balanceVersion': balanceVersion,
      'available': '0',
      'journey': '0',
      'total': '2000000000000000',
      'remainder': '0',
      'multiplier': '241',
      'ascensions': 2,
    }));
    final after = jsonDecode(controller.exportState()) as Map<String, dynamic>
      ..remove('exportedAt');

    expect(imported, isFalse);
    expect(after, before);
    controller.dispose();
  });

  test('cumulative Ascension square-root boundaries are exact', () async {
    final below = await controllerWith({
      'journey': '2016399999999999',
      'total': '2016399999999999',
    });
    final exact = await controllerWith({
      'journey': '2016400000000000',
      'total': '2016400000000000',
    });

    expect(below.ascensionGain(), BigInt.from(141));
    expect(exact.ascensionGain(), BigInt.from(142));
    below.dispose();
    exact.dispose();
  });

  test(
      'offline base is credited once and its bonus is a separate idempotent transaction',
      () async {
    final controller = await controllerWith({
      'offlineAt': DateTime.now().millisecondsSinceEpoch -
          const Duration(hours: 12).inMilliseconds,
      'offlineRate': '26800',
      'remainder': '0',
    });
    controller.resume();
    expect(controller.available, BigInt.from(385920));
    expect(controller.returnBonusAvailable, isTrue);
    expect(controller.resolveReturnBonus(rewarded: true), isTrue);
    expect(controller.available, BigInt.from(463104));
    expect(controller.resolveReturnBonus(rewarded: true), isFalse);
    controller.dispose();
  });

  test('balance migration preserves the frozen offline-rate snapshot',
      () async {
    final controller = await controllerWith({
      'offlineAt': DateTime.now().millisecondsSinceEpoch -
          const Duration(hours: 12).inMilliseconds,
      'offlineRate': '26800',
      'multiplier': '1100',
      'ascensions': 10,
      'total': '10000000000000000',
      'remainder': '0',
    });

    expect(controller.multiplier, BigInt.from(416));
    expect(controller.available, BigInt.from(385920));
    expect(controller.returnBonusAvailable, isTrue);
    controller.dispose();
  });

  test('Complement spends only the quoted balance and never creates Total Aura',
      () async {
    final controller = await controllerWith({
      'available': '200',
      'journey': '500',
      'total': '500',
      'levels': {'TECH-01': 1},
    });
    final root = upgrades.firstWhere((u) => u.id == 'ITEM-A-01');
    final quote = controller.beginComplement(root);
    expect(quote, isNotNull);
    expect(quote!.missing, BigInt.from(70));
    expect(controller.redeemComplement(quote, rewarded: true), isTrue);
    expect(controller.available, BigInt.zero);
    expect(controller.total, BigInt.from(500));
    expect(controller.journey, BigInt.from(500));
    expect(controller.level(root.id), 1);
    controller.dispose();
  });
}
