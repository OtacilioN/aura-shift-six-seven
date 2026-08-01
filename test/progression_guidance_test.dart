import 'dart:convert';

import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/main.dart';
import 'package:aura_shift_six_seven/ui/progression_guidance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Strings strings;

  setUpAll(() async {
    strings = await Strings.load('pt-BR');
  });

  test('central plan exposes the next tier and earliest shop requirements',
      () async {
    final controller = await _controllerWith({});
    try {
      final plan = buildAuraProgressionPlan(controller);
      expect(plan.tier?.threshold, BigInt.from(1000));
      expect(
        plan.unlockGoals.take(3).map((goal) => goal.upgrade.id),
        ['ITEM-A-01', 'ITEM-B-01', 'ITEM-C-01'],
      );
      expect(
        plan.unlockGoals.first.pending.single.upgradeId,
        'TECH-01',
      );
    } finally {
      controller.dispose();
    }
  });

  test('plan advances tiers and prioritizes the closest level milestone',
      () async {
    final controller = await _controllerWith({
      'available': '1500',
      'journey': '1500',
      'total': '1500',
      'levels': {'TECH-01': 1, 'ITEM-A-01': 7},
    });
    try {
      final plan = buildAuraProgressionPlan(controller);
      expect(plan.tier?.threshold, BigInt.from(1000000));
      expect(plan.unlockGoals.first.upgrade.id, 'ITEM-CONV-01');
      expect(plan.milestoneGoals.first.upgrade.id, 'ITEM-A-01');
      expect(plan.milestoneGoals.first.targetLevel, 10);
    } finally {
      controller.dispose();
    }
  });

  testWidgets(
      'next steps trigger is an accessible compact action and forwards its tap',
      (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: auraTheme(false, strings.locale),
        home: Scaffold(
          body: AuraNextStepsTrigger(
            strings: strings,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    await tester.pump();

    final trigger = find.byKey(const ValueKey('next-steps-trigger'));
    expect(trigger, findsOneWidget);
    expect(
      find.descendant(
        of: trigger,
        matching: find.byIcon(Icons.flag_outlined),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Próximos passos'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.tap(trigger);
    expect(taps, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('next steps sheet centralizes goals and opens their tree node',
      (tester) async {
    final controller = await _controllerWith({});
    String? openedUpgrade;
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: auraTheme(false, strings.locale),
          home: Scaffold(
            body: AuraNextStepsSheet(
              controller: controller,
              strings: strings,
              onOpenUpgrade: (id) => openedUpgrade = id,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Próximos passos'), findsOneWidget);
      expect(find.text('Próximos desbloqueios da Loja'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('next-unlock-ITEM-A-01')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('next-unlock-ITEM-A-01')),
      );
      expect(openedUpgrade, 'ITEM-A-01');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });
}

Future<GameController> _controllerWith(Map<String, dynamic> state) async {
  SharedPreferences.setMockInitialValues({
    'save-v1': jsonEncode({
      'saveVersion': 1,
      'arithVersion': 'arith-v1',
      'balanceVersion': balanceVersion,
      'ascensionAura': '0',
      'multiplier': '100',
      'locale': 'pt-BR',
      ...state,
    }),
  });
  return GameController.loadForTesting();
}
