import 'dart:convert';

import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/main.dart';
import 'package:aura_shift_six_seven/ui/aura_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Strings strings;

  setUpAll(() async {
    strings = await Strings.load('pt-BR');
  });

  testWidgets('shows a localized immutable snapshot of the Aura details',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({
        'available': '1000000000000',
        'total': '2000000000000',
        'journey': '3000000000000',
      }),
    });
    final controller = await GameController.loadForTesting();
    final snapshot = AuraDetailsSnapshot.fromController(controller);

    try {
      controller
        ..tap()
        ..tap();

      await tester.pumpWidget(
        MaterialApp(
          theme: auraTheme(false, strings.locale),
          home: Scaffold(
            body: AuraDetailsSheet(
              snapshot: snapshot,
              strings: strings,
              artwork: const Icon(Icons.bolt),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1.000.000.000.000'), findsOneWidget);
      expect(find.text('2.000.000.000.000'), findsOneWidget);
      expect(find.text('3.000.000.000.000'), findsOneWidget);
      expect(find.text('1.000.000.000.001'), findsNothing);
      expect(
        find.byKey(const ValueKey('aura-detail-passive-rate')),
        findsOneWidget,
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });
}
