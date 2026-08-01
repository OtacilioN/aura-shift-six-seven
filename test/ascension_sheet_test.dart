import 'package:aura_shift_six_seven/main.dart';
import 'package:aura_shift_six_seven/ui/ascension_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('explains the Ascension trade-off and confirms the action',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final strings = await Strings.load('pt-BR');
    var ascended = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: auraTheme(false, strings.locale),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: AscensionSheet(
              strings: strings,
              artwork: const Icon(Icons.auto_awesome_rounded, size: 48),
              currentMultiplier: '1',
              gainedMultiplier: '1.36',
              resultingMultiplier: '2.36',
              journeyAura: '1Qa',
              highContrast: false,
              reduceMotion: true,
              onAscend: () => ascended = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('ascension-sheet')), findsOneWidget);
    expect(find.text(strings('ascension_lore_body')), findsOneWidget);
    expect(find.text(strings('ascension_resets_title')), findsOneWidget);
    expect(find.text(strings('ascension_resets_body')), findsOneWidget);
    expect(find.text(strings('ascension_keeps_title')), findsOneWidget);
    expect(find.text(strings('ascension_keeps_body')), findsOneWidget);
    expect(find.text('1×'), findsOneWidget);
    expect(find.text('+1.36×'), findsOneWidget);
    expect(find.text('2.36×'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final action = find.byKey(const ValueKey('ascension-confirm-button'));
    await tester.scrollUntilVisible(
      action,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(action);

    expect(ascended, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains scrollable with expanded pseudo-locale copy',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final strings = await Strings.load('en-XA');

    await tester.pumpWidget(
      MaterialApp(
        theme: auraTheme(true, strings.locale),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: AscensionSheet(
              strings: strings,
              artwork: const Icon(Icons.auto_awesome_rounded, size: 48),
              currentMultiplier: '10',
              gainedMultiplier: '0.99',
              resultingMultiplier: '10.99',
              journeyAura: '285Qa',
              highContrast: true,
              reduceMotion: true,
              onAscend: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final action = find.byKey(const ValueKey('ascension-confirm-button'));
    await tester.scrollUntilVisible(
      action,
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(action, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
