import 'dart:convert';

import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/main.dart';
import 'package:aura_shift_six_seven/ui/aura_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Strings strings;
  late Strings arStrings;

  setUpAll(() async {
    final catalogs = await Future.wait([
      Strings.load('pt-BR'),
      Strings.load('ar'),
    ]);
    strings = catalogs[0];
    arStrings = catalogs[1];
  });

  Future<GameController> controllerWith(Map<String, dynamic> state) async {
    SharedPreferences.setMockInitialValues({'save-v1': jsonEncode(state)});
    return GameController.loadForTesting();
  }

  Future<void> pumpTree(
    WidgetTester tester,
    GameController controller,
    Strings strings, {
    double width = 360,
    double height = 700,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: auraTheme(false, strings.locale),
        home: Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              textScaler: textScaler,
            ),
            child: Scaffold(
              body: SafeArea(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: AuraItemTree(
                    controller: controller,
                    translate: strings.call,
                    locale: strings.locale,
                    art: null,
                    onPurchase: (upgrade, quantity) =>
                        controller.buy(upgrade, quantity),
                    onComplement: (_) async {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the 3x5 build tree and three Convergence nodes',
      (tester) async {
    final controller = await controllerWith({});
    try {
      await pumpTree(tester, controller, strings);

      for (final branch in const ['A', 'B', 'C']) {
        for (var depth = 1; depth <= 5; depth++) {
          expect(
            find.byKey(ValueKey('aura-node-ITEM-$branch-0$depth')),
            findsOneWidget,
          );
        }
      }
      for (var depth = 1; depth <= 3; depth++) {
        expect(
          find.byKey(ValueKey('aura-node-ITEM-CONV-0$depth')),
          findsOneWidget,
        );
      }
      expect(find.byKey(const ValueKey('aura-root-TECH-01')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      controller.dispose();
    }
  });

  testWidgets('tapping a node opens its localized detail and purchase options',
      (tester) async {
    final controller = await controllerWith({
      'available': '600',
      'total': '600',
      'levels': {'TECH-01': 1},
    });
    try {
      await pumpTree(tester, controller, strings);

      await tester.tap(find.byKey(const ValueKey('aura-node-ITEM-A-01')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
        findsOneWidget,
      );
      expect(find.text('Botão Suspeito'), findsWidgets);
      expect(
        find.text(
          'Em Six, parece decorativo. Em Seven, também — mas agora produz Aura.',
        ),
        findsOneWidget,
      );
      final detailScroll = find.descendant(
        of: find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-x1-ITEM-A-01')),
        180,
        scrollable: detailScroll,
      );
      final detailPosition =
          tester.state<ScrollableState>(detailScroll).position;
      detailPosition.jumpTo(
        (detailPosition.pixels + 120).clamp(
          detailPosition.minScrollExtent,
          detailPosition.maxScrollExtent,
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('buy-x1-ITEM-A-01')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-x10-ITEM-A-01')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-max-ITEM-A-01')), findsOneWidget);

      final oneButton = find.descendant(
        of: find.byKey(const ValueKey('buy-x1-ITEM-A-01')),
        matching: find.byType(FilledButton),
      );
      final tenButton = find.descendant(
        of: find.byKey(const ValueKey('buy-x10-ITEM-A-01')),
        matching: find.byType(OutlinedButton),
      );
      expect(tester.widget<FilledButton>(oneButton).onPressed, isNotNull);
      expect(tester.widget<OutlinedButton>(tenButton).onPressed, isNull);

      await tester.tap(oneButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.level('ITEM-A-01'), 1);
      expect(controller.available, BigInt.from(330));
      expect(
        find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('aura-node-ITEM-A-01')),
          matching: find.text('N1'),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      controller.dispose();
    }
  });

  testWidgets('x10 shows the exact shortfall at a compact-number collision',
      (tester) async {
    final controller = await controllerWith({
      'available': '5486',
      'total': '5486',
      'journey': '5486',
      'levels': {'TECH-01': 1},
    });
    try {
      await pumpTree(tester, controller, strings);
      await tester.tap(find.byKey(const ValueKey('aura-node-ITEM-A-01')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final detailScroll = find.descendant(
        of: find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-x10-ITEM-A-01')),
        180,
        scrollable: detailScroll,
      );

      final tenButton = find.descendant(
        of: find.byKey(const ValueKey('buy-x10-ITEM-A-01')),
        matching: find.byType(OutlinedButton),
      );
      expect(tester.widget<OutlinedButton>(tenButton).onPressed, isNull);
      final tenLabels = tester
          .widgetList<Text>(find.descendant(
            of: tenButton,
            matching: find.byType(Text),
          ))
          .map((text) => text.data ?? '')
          .join(' ')
          .replaceAll(RegExp('[\u2066\u2069]'), '');
      expect(tenLabels, contains('Faltam 1 de Aura'));

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      controller.dispose();
    }
  });

  testWidgets('Convergence detail lists each branch requirement',
      (tester) async {
    final controller = await controllerWith({
      'available': '6700',
      'total': '1000',
      'levels': {
        'ITEM-A-01': 10,
        'ITEM-B-01': 10,
        'ITEM-C-01': 9,
      },
    });
    final semantics = tester.ensureSemantics();
    try {
      await pumpTree(tester, controller, strings);

      final convergenceSemantics = tester.getSemantics(
        find.byKey(const ValueKey('aura-node-ITEM-CONV-01')),
      );
      expect(convergenceSemantics.label, contains('Botão Suspeito'));
      expect(convergenceSemantics.label, contains('Despertador das 6:70'));
      expect(convergenceSemantics.label, contains('Glitch Homologado'));
      expect(
        (convergenceSemantics.sortKey! as OrdinalSortKey).order,
        13,
      );

      await tester.tap(
        find.byKey(const ValueKey('aura-node-ITEM-CONV-01')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Botão Suspeito'), findsOneWidget);
      final requirementA = find.byKey(
        const ValueKey('requirement-ITEM-CONV-01-ITEM-A-01'),
      );
      expect(
        find.descendant(of: requirementA, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: requirementA,
          matching: find.textContaining('(10/10)'),
        ),
        findsOneWidget,
      );
      final detailScroll = find.descendant(
        of: find.byKey(const ValueKey('aura-detail-ITEM-CONV-01')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.textContaining('Despertador das 6:70'),
        130,
        scrollable: detailScroll,
      );
      expect(find.textContaining('Despertador das 6:70'), findsOneWidget);
      final requirementB = find.byKey(
        const ValueKey('requirement-ITEM-CONV-01-ITEM-B-01'),
      );
      expect(
        find.descendant(of: requirementB, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.textContaining('Glitch Homologado'),
        130,
        scrollable: detailScroll,
      );
      expect(find.textContaining('Glitch Homologado'), findsOneWidget);
      final requirementC = find.byKey(
        const ValueKey('requirement-ITEM-CONV-01-ITEM-C-01'),
      );
      expect(
        find.descendant(
          of: requirementC,
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: requirementC,
          matching: find.textContaining('(9/10)'),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-x1-ITEM-CONV-01')),
        180,
        scrollable: detailScroll,
      );
      final buyButton = find.descendant(
        of: find.byKey(const ValueKey('buy-x1-ITEM-CONV-01')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(buyButton).onPressed, isNull);

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      semantics.dispose();
      controller.dispose();
    }
  });

  testWidgets('reflows at 320dp with 200% text and mirrors branches in RTL',
      (tester) async {
    final controller = await controllerWith({});
    try {
      await pumpTree(
        tester,
        controller,
        arStrings,
        width: 288,
        height: 568,
        textScaler: const TextScaler.linear(2),
        textDirection: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      final nodeA = tester.getRect(
        find.byKey(const ValueKey('aura-node-ITEM-A-01')),
      );
      final nodeB = tester.getRect(
        find.byKey(const ValueKey('aura-node-ITEM-B-01')),
      );
      final nodeC = tester.getRect(
        find.byKey(const ValueKey('aura-node-ITEM-C-01')),
      );
      expect(nodeA.center.dx, greaterThan(nodeC.center.dx));
      expect(nodeC.right + 8, lessThanOrEqualTo(nodeB.left));
      expect(nodeB.right + 8, lessThanOrEqualTo(nodeA.left));
      expect(nodeA.height, greaterThan(120));
      final branchLabelA = tester.getRect(
        find.byKey(const ValueKey('aura-branch-label-A')),
      );
      expect(branchLabelA.bottom + 4, lessThanOrEqualTo(nodeA.top));

      await tester.tap(find.byKey(const ValueKey('aura-node-ITEM-A-01')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(
          tester.element(
            find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
          ),
        ),
        TextDirection.rtl,
      );
      final detailScroll = find.descendant(
        of: find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-x1-ITEM-A-01')),
        160,
        scrollable: detailScroll,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip(arStrings('action_close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      controller.dispose();
    }
  });
}
