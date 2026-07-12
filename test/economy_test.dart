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
