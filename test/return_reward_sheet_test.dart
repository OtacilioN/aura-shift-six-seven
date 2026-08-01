import 'dart:async';

import 'package:aura_shift_six_seven/main.dart';
import 'package:aura_shift_six_seven/ui/return_reward_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, Strings> localizedStrings;

  setUpAll(() async {
    const locales = ['pt-BR', 'de-DE', 'ja-JP', 'ar'];
    final loaded = await Future.wait(locales.map(Strings.load));
    localizedStrings = {
      for (var index = 0; index < locales.length; index++)
        locales[index]: loaded[index],
    };
  });

  testWidgets('shows the reward hierarchy and both claim paths',
      (tester) async {
    final strings = localizedStrings['pt-BR']!;
    var baseClaims = 0;
    var bonusClaims = 0;

    await _pumpReturnSheet(
      tester,
      strings: strings,
      baseAmount: '12,4K',
      bonusAmount: '2,48K',
      creditCapped: true,
      bonusAvailable: true,
      onClaimBase: () {
        baseClaims++;
        return true;
      },
      onClaimBonus: () async {
        bonusClaims++;
        return ReturnBonusOutcome.cancelled;
      },
    );

    expect(find.byKey(const ValueKey('return-reward-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('return-away-time')), findsOneWidget);
    expect(find.byKey(const ValueKey('return-base-amount')), findsOneWidget);
    expect(find.byKey(const ValueKey('return-credit-cap')), findsOneWidget);
    expect(find.byKey(const ValueKey('return-bonus-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('return-bonus-amount')), findsOneWidget);
    expect(find.text('12,4K'), findsOneWidget);
    expect(find.text('+2,48K'), findsOneWidget);

    final adButton = find.byKey(const ValueKey('return-watch-ad'));
    final baseButton = find.byKey(const ValueKey('return-claim-base'));
    expect(tester.getSize(adButton).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(baseButton).height, greaterThanOrEqualTo(48));

    await tester.tap(adButton);
    await tester.pumpAndSettle();
    expect(bonusClaims, 1);
    expect(find.byKey(const ValueKey('return-reward-sheet')), findsOneWidget);

    await tester.tap(baseButton);
    await tester.pumpAndSettle();
    expect(baseClaims, 1);
    expect(find.byKey(const ValueKey('return-reward-sheet')), findsNothing);
  });

  testWidgets('base-only return exposes one full-width claim action',
      (tester) async {
    final strings = localizedStrings['pt-BR']!;
    var baseClaims = 0;

    await _pumpReturnSheet(
      tester,
      strings: strings,
      bonusAvailable: false,
      onClaimBase: () {
        baseClaims++;
        return true;
      },
    );

    expect(find.byKey(const ValueKey('return-bonus-card')), findsNothing);
    expect(find.byKey(const ValueKey('return-watch-ad')), findsNothing);
    final baseButton = find.byKey(const ValueKey('return-claim-base'));
    expect(baseButton, findsOneWidget);
    expect(
      tester.widget<FilledButton>(baseButton).onPressed,
      isNotNull,
    );

    await tester.tap(baseButton);
    await tester.pumpAndSettle();
    expect(baseClaims, 1);
  });

  testWidgets('blocks duplicate claims while the return ad is in flight',
      (tester) async {
    final strings = localizedStrings['pt-BR']!;
    final firstAttempt = Completer<ReturnBonusOutcome>();
    var bonusClaims = 0;
    var baseClaims = 0;

    await _pumpReturnSheet(
      tester,
      strings: strings,
      bonusAvailable: true,
      onClaimBase: () {
        baseClaims++;
        return true;
      },
      onClaimBonus: () {
        bonusClaims++;
        return firstAttempt.future;
      },
    );

    final adButton = find.byKey(const ValueKey('return-watch-ad'));
    await tester.tap(adButton);
    await tester.tap(adButton);
    await tester.pump();

    expect(bonusClaims, 1);
    expect(find.byKey(const ValueKey('return-ad-loading')), findsOneWidget);
    expect(
      tester.widget<FilledButton>(adButton).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('return-claim-base')),
          )
          .onPressed,
      isNull,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('return-reward-sheet')), findsOneWidget);
    expect(baseClaims, 0);

    firstAttempt.complete(ReturnBonusOutcome.failed);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('return-ad-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('return-ad-retry-label')), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('return-claim-base')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('ad failure can be retried and success closes exactly once',
      (tester) async {
    final strings = localizedStrings['pt-BR']!;
    var attempts = 0;

    await _pumpReturnSheet(
      tester,
      strings: strings,
      bonusAvailable: true,
      onClaimBonus: () async {
        attempts++;
        return attempts == 1
            ? ReturnBonusOutcome.failed
            : ReturnBonusOutcome.claimed;
      },
    );

    final adButton = find.byKey(const ValueKey('return-watch-ad'));
    await tester.tap(adButton);
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.byKey(const ValueKey('return-ad-error')), findsOneWidget);

    await tester.tap(adButton);
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byKey(const ValueKey('return-reward-sheet')), findsNothing);
  });

  for (final locale in const ['de-DE', 'ja-JP', 'ar']) {
    testWidgets('reflows at 320x568 with 200% text in $locale', (tester) async {
      final strings = localizedStrings[locale]!;

      await _pumpReturnSheet(
        tester,
        strings: strings,
        size: const Size(320, 568),
        textScale: 2,
        creditCapped: true,
        bonusAvailable: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final baseButton = find.byKey(const ValueKey('return-claim-base'));
      await tester.ensureVisible(baseButton);
      await tester.pumpAndSettle();
      expect(baseButton.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      final direction = Directionality.of(
        tester.element(find.byKey(const ValueKey('return-reward-sheet'))),
      );
      expect(
        direction,
        locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
    });
  }
}

Future<void> _pumpReturnSheet(
  WidgetTester tester, {
  required Strings strings,
  String baseAmount = '1,24K',
  String bonusAmount = '248',
  Size size = const Size(390, 844),
  double textScale = 1,
  bool creditCapped = false,
  bool bonusAvailable = true,
  bool Function()? onClaimBase,
  Future<ReturnBonusOutcome> Function()? onClaimBonus,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: auraTheme(false, strings.locale),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: Directionality(
            textDirection:
                strings.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        );
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const ValueKey('open-return-sheet'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                isDismissible: false,
                enableDrag: false,
                backgroundColor: Colors.transparent,
                builder: (_) => ReturnRewardSheet(
                  strings: strings,
                  baseAmount: baseAmount,
                  bonusAmount: bonusAmount,
                  awayDuration: const Duration(hours: 5, minutes: 17),
                  creditCapped: creditCapped,
                  bonusAvailable: bonusAvailable,
                  highContrast: false,
                  reduceMotion: false,
                  auraArtwork: const Icon(Icons.auto_awesome_rounded, size: 56),
                  timeArtwork: const Icon(Icons.schedule_rounded, size: 18),
                  bonusArtwork:
                      const Icon(Icons.smart_display_rounded, size: 32),
                  onClaimBase: onClaimBase ?? () => true,
                  onClaimBonus:
                      onClaimBonus ?? () async => ReturnBonusOutcome.cancelled,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-return-sheet')));
  await tester.pumpAndSettle();
}
