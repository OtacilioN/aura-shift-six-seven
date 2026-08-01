import 'dart:async';
import 'dart:convert';

import 'package:aura_shift_six_seven/audio/audio_backend.dart';
import 'package:aura_shift_six_seven/audio/audio_catalog.dart';
import 'package:aura_shift_six_seven/audio/aura_audio_controller.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/main.dart';
import 'package:aura_shift_six_seven/ui/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AudioAssetCatalog audioCatalog;
  late Strings strings;
  late Strings arStrings;

  setUpAll(() async {
    final loaded = await Future.wait([
      AudioAssetCatalog.load(),
      Strings.load('pt-BR'),
      Strings.load('ar'),
    ]);
    audioCatalog = loaded[0] as AudioAssetCatalog;
    strings = loaded[1] as Strings;
    arStrings = loaded[2] as Strings;
  });

  testWidgets(
    'keeps all collection areas discoverable and exposes their progress',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'save-v1': jsonEncode({
          'locale': 'pt-BR',
          'appearances': ['ITEM-A-01', 'ITEM-C-01'],
          'equippedAppearances': ['ITEM-A-01'],
          'transformations': ['FORM-01'],
          'achievements': ['ACH-V-01', 'ACH-S-01'],
          'seals': ['67e0'],
        }),
      });
      final controller = await GameController.loadForTesting();
      final audio = await AuraAudioController.createForTesting(
        catalog: audioCatalog,
        backend: _SilentAudioBackend(),
        store: _MemoryAudioStore(),
      );
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;

      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: auraTheme(false, strings.locale),
            home: Scaffold(
              body: SafeArea(
                child: AuraCollectionView(
                  controller: controller,
                  strings: strings,
                  art: null,
                  audio: audio,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        for (final section in const [
          'appearances',
          'transformations',
          'seals',
        ]) {
          expect(
            find.byKey(ValueKey('collection-section-$section')),
            findsOneWidget,
          );
        }
        _expectCount(tester, 'appearance', '2/18');
        _expectCount(tester, 'transformation', '1/5');
        _expectCount(tester, 'seal', '1');
        _expectSingleLineSectionTitle(
          tester,
          section: 'appearances',
          count: 'appearance',
          label: strings('collection_appearances'),
        );
        _expectSingleLineSectionTitle(
          tester,
          section: 'transformations',
          count: 'transformation',
          label: strings('collection_transformations'),
        );
        _expectSingleLineSectionTitle(
          tester,
          section: 'seals',
          count: 'seal',
          label: strings('collection_seals'),
        );
        expect(find.text('Botão Suspeito'), findsOneWidget);
        expect(find.text('Primeira Virada'), findsNothing);

        expect(
          find.byKey(const ValueKey('collection-section-achievements')),
          findsNothing,
        );

        await tester.tap(
          find.byKey(const ValueKey('collection-section-transformations')),
        );
        await tester.pump();

        expect(find.text(strings('collection_transformations')), findsWidgets);
        expect(find.text('Botão Suspeito'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        audio.dispose();
        controller.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );

  testWidgets('section picker remains usable in narrow RTL layouts',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({'locale': 'ar'}),
    });
    final controller = await GameController.loadForTesting();
    final audio = await AuraAudioController.createForTesting(
      catalog: audioCatalog,
      backend: _SilentAudioBackend(),
      store: _MemoryAudioStore(),
    );
    tester.view
      ..physicalSize = const Size(320, 700)
      ..devicePixelRatio = 1;

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: auraTheme(false, arStrings.locale),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
              ),
              child: child!,
            ),
          ),
          home: Scaffold(
            body: SafeArea(
              child: AuraCollectionView(
                controller: controller,
                strings: arStrings,
                art: null,
                audio: audio,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      for (final section in const [
        'appearances',
        'transformations',
        'seals',
      ]) {
        expect(
          find.byKey(ValueKey('collection-section-$section')),
          findsOneWidget,
        );
      }
      _expectSingleLineSectionTitle(
        tester,
        section: 'transformations',
        count: 'transformation',
        label: arStrings('collection_transformations'),
      );

      expect(
        find.byKey(const ValueKey('collection-section-achievements')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('collection-section-seals')),
      );
      await tester.pump();

      expect(find.text(arStrings('collection_seals')), findsWidgets);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      audio.dispose();
      controller.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}

void _expectCount(WidgetTester tester, String section, String value) {
  final count = find.descendant(
    of: find.byKey(ValueKey('collection-count-$section')),
    matching: find.byType(Text),
  );
  expect(count, findsOneWidget);
  expect(tester.widget<Text>(count).data, value);
}

void _expectSingleLineSectionTitle(
  WidgetTester tester, {
  required String section,
  required String count,
  required String label,
}) {
  final button = find.byKey(ValueKey('collection-section-$section'));
  final title = find.descendant(of: button, matching: find.text(label));
  final countBadge = find.byKey(ValueKey('collection-count-$count'));
  expect(title, findsOneWidget);
  final titleWidget = tester.widget<Text>(title);
  expect(titleWidget.maxLines, 1);
  expect(titleWidget.softWrap, isFalse);
  expect(
    tester.getTopLeft(title).dy,
    lessThan(tester.getTopLeft(countBadge).dy),
  );
}

class _MemoryAudioStore implements AudioSettingsStore {
  final values = <String, Object>{};

  @override
  bool? readBool(String key) => values[key] as bool?;

  @override
  double? readDouble(String key) => values[key] as double?;

  @override
  Future<void> writeBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> writeDouble(String key, double value) async =>
      values[key] = value;
}

class _SilentAudioBackend implements AudioBackend {
  @override
  Future<void> initialize({Iterable<String> preloadPaths = const []}) async {}

  @override
  Future<MusicPlaybackHandle> playMusic(
    String cachePath, {
    required double volume,
    required Duration transition,
    required bool loop,
    bool preservePosition = false,
  }) async =>
      _SilentMusicPlaybackHandle();

  @override
  Future<void> playMusicLayers(
    Map<String, double> cachePathGains, {
    required double volume,
    required Duration transition,
  }) async {}

  @override
  Future<AudioPlaybackHandle> playSound(
    String cachePath, {
    required double volume,
    required Duration duration,
  }) async =>
      _SilentPlaybackHandle();

  @override
  Future<void> setMusicVolume(double volume) async {}

  @override
  Future<void> pauseMusic() async {}

  @override
  Future<void> resumeMusic() async {}

  @override
  Future<void> stopSounds() async {}

  @override
  Future<void> dispose() async {}
}

class _SilentPlaybackHandle implements AudioPlaybackHandle {
  @override
  Future<void> get completed => Future<void>.value();

  @override
  Future<void> stop() async {}
}

class _SilentMusicPlaybackHandle implements MusicPlaybackHandle {
  final Completer<void> _completed = Completer<void>();

  @override
  Stream<Duration> get position => const Stream<Duration>.empty();

  @override
  Future<void> get completed => _completed.future;
}
