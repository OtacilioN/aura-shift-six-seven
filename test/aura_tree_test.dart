import 'dart:async';
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
    Future<void> Function(Upgrade upgrade)? onRewardedUpgrade,
    String? focusUpgradeId,
    int focusRequestToken = 0,
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
                    onRewardedUpgrade: onRewardedUpgrade ?? (_) async {},
                    focusUpgradeId: focusUpgradeId,
                    focusRequestToken: focusRequestToken,
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

  testWidgets('renders six techniques in the 3x5 tree and Convergence nodes',
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
      for (var index = 2; index <= 6; index++) {
        expect(
          find.byKey(ValueKey('aura-technique-TECH-0$index')),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('aura-node-ITEM-A-01')),
          matching: find.text('Botão Suspeito'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('aura-node-ITEM-A-02')),
          matching: find.text('Nota Fiscal do Brilho'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('aura-node-ITEM-A-01')),
          matching: find.textContaining(strings('content.branch_a.name')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('aura-node-ITEM-CONV-01')),
          matching: find.text('Nó de Reunião'),
        ),
        findsOneWidget,
      );
      expect(find.text('Spectrum 1'), findsNothing);
      expect(find.text(strings('shop_aura_tree')), findsNothing);
      expect(
        find.text(strings('play_available_aura_short').toUpperCase()),
        findsOneWidget,
      );

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
      expect(find.byKey(const ValueKey('buy-max-ITEM-A-01')), findsNothing);

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
        findsOneWidget,
      );
      final closeButton = find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(IconButton),
      );
      expect(closeButton, findsOneWidget);
      final closePosition = tester.widget<Positioned>(
        find.ancestor(
          of: closeButton,
          matching: find.byType(Positioned),
        ),
      );
      expect(closePosition.left, 8);
      expect(closePosition.right, isNull);
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

  testWidgets(
      'rewarded upgrade shows loading and blocks duplicate actions until done',
      (tester) async {
    final controller = await controllerWith({
      'available': '10000',
      'total': '10000',
      'journey': '10000',
      'levels': {'TECH-01': 1, 'ITEM-A-01': 1},
      'normalTechniquePurchased': true,
      'normalItemPurchased': true,
      'tutorialCompleted': true,
    });
    final adGate = Completer<void>();
    var rewardedCalls = 0;
    try {
      await pumpTree(
        tester,
        controller,
        strings,
        onRewardedUpgrade: (_) async {
          rewardedCalls++;
          await adGate.future;
        },
      );

      await tester.tap(find.byKey(const ValueKey('aura-node-ITEM-A-01')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final detailScroll = find.descendant(
        of: find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
        matching: find.byType(Scrollable),
      );
      final rewardedButton =
          find.byKey(const ValueKey('buy-rewarded-upgrade-ITEM-A-01'));
      await tester.scrollUntilVisible(
        rewardedButton,
        180,
        scrollable: detailScroll,
      );
      final closeButton = find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(IconButton),
      );
      final buyOneButton = find.descendant(
        of: find.byKey(const ValueKey('buy-x1-ITEM-A-01')),
        matching: find.byType(FilledButton),
      );
      final staleCloseAction =
          tester.widget<IconButton>(closeButton).onPressed!;
      final staleBuyAction =
          tester.widget<FilledButton>(buyOneButton).onPressed!;
      final staleRewardedAction =
          tester.widget<OutlinedButton>(rewardedButton).onPressed!;

      staleRewardedAction();
      staleRewardedAction();
      staleCloseAction();
      staleBuyAction();
      await tester.pump();

      expect(rewardedCalls, 1);
      expect(controller.level('ITEM-A-01'), 1);
      expect(
        find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('shop-ad-loading')), findsOneWidget);
      expect(find.text(strings('system_ad_loading')), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(rewardedButton).onPressed,
        isNull,
      );
      expect(tester.widget<IconButton>(closeButton).onPressed, isNull);
      expect(tester.widget<FilledButton>(buyOneButton).onPressed, isNull);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
        findsOneWidget,
      );
      expect(rewardedCalls, 1);

      adGate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('shop-ad-loading')), findsNothing);
      expect(
        find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
        findsOneWidget,
      );
      expect(tester.widget<IconButton>(closeButton).onPressed, isNotNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('aura-detail-ITEM-A-01')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      if (!adGate.isCompleted) adGate.complete();
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
        14,
      );

      await tester.tap(
        find.byKey(const ValueKey('aura-node-ITEM-CONV-01')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Botão Suspeito'), findsWidgets);
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
      final requirementB = find.byKey(
        const ValueKey('requirement-ITEM-CONV-01-ITEM-B-01'),
      );
      await tester.scrollUntilVisible(
        requirementB,
        130,
        scrollable: detailScroll,
      );
      expect(
        find.descendant(
          of: requirementB,
          matching: find.textContaining('Despertador das 6:70'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: requirementB, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      final requirementC = find.byKey(
        const ValueKey('requirement-ITEM-CONV-01-ITEM-C-01'),
      );
      await tester.scrollUntilVisible(
        requirementC,
        130,
        scrollable: detailScroll,
      );
      expect(
        find.descendant(
          of: requirementC,
          matching: find.textContaining('Glitch Homologado'),
        ),
        findsOneWidget,
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

  testWidgets('techniques open in the tree without changing their gates',
      (tester) async {
    final controller = await controllerWith({
      'available': '1000000',
      'total': '999999',
      'levels': {'TECH-01': 1},
    });
    final semantics = tester.ensureSemantics();
    try {
      await pumpTree(tester, controller, strings);

      final technique = find.byKey(
        const ValueKey('aura-technique-TECH-03'),
      );
      final techniqueSemantics = tester.getSemantics(technique);
      expect(techniqueSemantics.label, contains('Bloqueado'));
      expect(techniqueSemantics.label, contains('1M'));

      final treeScroll = find.descendant(
        of: find.byKey(const PageStorageKey('aura-tree-scroll')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        technique,
        240,
        scrollable: treeScroll,
      );
      await tester.tap(technique);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const ValueKey('aura-detail-TECH-03')),
        findsOneWidget,
      );
      final detailScroll = find.descendant(
        of: find.byKey(const ValueKey('aura-detail-TECH-03')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-x1-TECH-03')),
        180,
        scrollable: detailScroll,
      );
      final buyButton = find.descendant(
        of: find.byKey(const ValueKey('buy-x1-TECH-03')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(buyButton).onPressed, isNull);
      expect(controller.level('TECH-03'), 0);

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      semantics.dispose();
      controller.dispose();
    }
  });

  testWidgets('a reached tier and build dependency unlock a technique',
      (tester) async {
    final controller = await controllerWith({
      'available': '67000',
      'total': '1000000',
      'levels': {'TECH-02': 10},
    });
    final semantics = tester.ensureSemantics();
    try {
      await pumpTree(tester, controller, strings);

      final technique = find.byKey(
        const ValueKey('aura-technique-TECH-03'),
      );
      expect(tester.getSemantics(technique).label, contains('Desbloqueado'));

      final treeScroll = find.descendant(
        of: find.byKey(const PageStorageKey('aura-tree-scroll')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        technique,
        240,
        scrollable: treeScroll,
      );
      await tester.tap(technique);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final detailScroll = find.descendant(
        of: find.byKey(const ValueKey('aura-detail-TECH-03')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-x1-TECH-03')),
        180,
        scrollable: detailScroll,
      );
      final buyButton = find.descendant(
        of: find.byKey(const ValueKey('buy-x1-TECH-03')),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(buyButton).onPressed, isNotNull);

      await tester.ensureVisible(buyButton);
      await tester.pump();
      await tester.tap(buyButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.level('TECH-01'), 0);
      expect(controller.level('TECH-02'), 10);
      expect(controller.level('TECH-03'), 1);
      expect(controller.available, BigInt.zero);

      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      semantics.dispose();
      controller.dispose();
    }
  });

  testWidgets(
      'techniques follow tier order and Motion connectors avoid central nodes',
      (tester) async {
    final controller = await controllerWith({});
    try {
      for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
        await pumpTree(
          tester,
          controller,
          strings,
          textDirection: direction,
        );

        Finder techniqueFinder(int index) => index == 1
            ? find.byKey(const ValueKey('aura-root-TECH-01'))
            : find.byKey(ValueKey('aura-technique-TECH-0$index'));
        Finder branchFinder(String branch, int depth) =>
            find.byKey(ValueKey('aura-node-ITEM-$branch-0$depth'));

        final techniqueRects = [
          for (var index = 1; index <= 6; index++)
            tester.getRect(techniqueFinder(index)),
        ];
        for (var index = 1; index < techniqueRects.length; index++) {
          expect(
            techniqueRects[index - 1].bottom,
            lessThan(techniqueRects[index].top),
          );
        }
        for (var depth = 1; depth <= 5; depth++) {
          final tierNode = tester.getRect(branchFinder('B', depth));
          expect(
            techniqueRects[depth - 1].center.dy,
            lessThan(tierNode.center.dy),
          );
          expect(
            techniqueRects[depth - 1].overlaps(tierNode),
            isFalse,
          );
        }
        expect(
          tester.getRect(branchFinder('B', 5)).center.dy,
          lessThan(techniqueRects[5].center.dy),
        );

        final motionX = tester.getRect(branchFinder('B', 1)).center.dx;
        final signalX = tester.getRect(branchFinder('C', 1)).center.dx;
        for (var depth = 1; depth < 5; depth++) {
          final from = tester.getRect(branchFinder('B', depth)).center;
          final to = tester.getRect(branchFinder('B', depth + 1)).center;
          final path = auraTreeBranchConnectionPath(
            from: from,
            to: to,
            branch: 'B',
            direction: direction,
            motionX: motionX,
            signalX: signalX,
            bendsAroundCenter: true,
          );
          for (final obstacle in techniqueRects.where(
            (rect) => rect.center.dy > from.dy && rect.center.dy < to.dy,
          )) {
            expect(
              _pathIntersectsRect(path, obstacle.inflate(4)),
              isFalse,
              reason:
                  'Motion connector $depth crossed a Technique in $direction',
            );
          }
        }
      }

      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
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
      final nodeALabel = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('aura-node-ITEM-A-01')),
          matching: find.text(arStrings('content.item_a_01.name')),
        ),
      );
      expect(nodeALabel.maxLines, 3);
      expect(nodeALabel.overflow, TextOverflow.ellipsis);
      expect(nodeALabel.textDirection, isNull);
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

  testWidgets('external focus request scrolls to and selects an upgrade',
      (tester) async {
    final controller = await controllerWith({});
    try {
      await pumpTree(
        tester,
        controller,
        strings,
        height: 420,
      );
      final treeScroll = find.descendant(
        of: find.byKey(const PageStorageKey('aura-tree-scroll')),
        matching: find.byType(Scrollable),
      );
      expect(tester.state<ScrollableState>(treeScroll).position.pixels, 0);

      await pumpTree(
        tester,
        controller,
        strings,
        height: 420,
        focusUpgradeId: 'ITEM-A-05',
        focusRequestToken: 1,
      );
      await tester.pumpAndSettle();
      var position = tester.state<ScrollableState>(treeScroll).position;
      expect(position.pixels, greaterThan(0));
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('aura-node-ITEM-A-05')),
            )
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isTrue,
      );

      position.jumpTo(0);
      await tester.pump();
      await pumpTree(
        tester,
        controller,
        strings,
        height: 420,
        focusUpgradeId: 'ITEM-A-05',
        focusRequestToken: 2,
      );
      await tester.pumpAndSettle();
      position = tester.state<ScrollableState>(treeScroll).position;
      expect(position.pixels, greaterThan(0));

      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      controller.dispose();
    }
  });
}

bool _pathIntersectsRect(Path path, Rect rect) {
  for (final metric in path.computeMetrics()) {
    for (var distance = 0.0; distance <= metric.length; distance += 1) {
      final point = metric.getTangentForOffset(distance)?.position;
      if (point != null && rect.contains(point)) return true;
    }
  }
  return false;
}
