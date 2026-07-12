import 'package:aura_shift_six_seven/ui/art_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('manifest art fallback keeps its accessible image label',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuraAssetArt(
            catalog: null,
            assetId: 'missing_asset',
            fallback: Icon(Icons.broken_image_outlined),
            width: 48,
            height: 48,
            semanticLabel: 'Aura artwork',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AuraAssetArt)),
      matchesSemantics(label: 'Aura artwork', isImage: true),
    );
    semantics.dispose();
  });
}
