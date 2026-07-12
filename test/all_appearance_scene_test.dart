import 'dart:async';
import 'dart:convert';

import 'package:aura_shift_six_seven/audio/audio_backend.dart';
import 'package:aura_shift_six_seven/audio/audio_catalog.dart';
import 'package:aura_shift_six_seven/audio/aura_audio_controller.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/game/aura_scene.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AudioAssetCatalog audioCatalog;
  final itemIds = <String>[
    for (final branch in const ['A', 'B', 'C'])
      for (var depth = 1; depth <= 5; depth++) 'ITEM-$branch-0$depth',
    for (var depth = 1; depth <= 3; depth++) 'ITEM-CONV-0$depth',
  ];

  setUpAll(() async {
    audioCatalog = await AudioAssetCatalog.load();
  });

  Future<void> pumpAppearanceLayers(
    WidgetTester tester,
    AuraScene scene,
    int expected,
  ) async {
    for (var attempt = 0; attempt < 1000; attempt++) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      if (scene.debugRequestedAppearanceLayerCount == expected &&
          scene.debugLoadedAppearanceLayerCount == expected) {
        return;
      }
    }
    fail(
      'Appearance layers did not finish loading: '
      '${scene.debugLoadedAppearanceLayerCount}/'
      '${scene.debugRequestedAppearanceLayerCount}, expected $expected',
    );
  }

  testWidgets(
    'all appearances compose at phone sizes in animated and reduced motion',
    (tester) async {
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      SharedPreferences.setMockInitialValues({
        'save-v1': jsonEncode({
          'levels': {for (final itemId in itemIds) itemId: 25},
          'appearances': itemIds,
          'equippedAppearances': itemIds,
          'reduceMotion': false,
          'locale': 'pt-BR',
        }),
      });
      final controller = await GameController.loadForTesting();
      final audio = await AuraAudioController.createForTesting(
        catalog: audioCatalog,
        backend: _SilentAudioBackend(),
        store: _MemoryAudioStore(),
      );
      final scene = AuraScene(controller, audio);
      const boundaryKey = ValueKey('scene-all-appearances');

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox.expand(child: GameWidget(game: scene)),
              ),
            ),
          ),
        );
        await tester.pump();
        await pumpAppearanceLayers(tester, scene, 51);
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(scene.debugActiveAppearanceCount, itemIds.length);
        expect(scene.debugLoadedAppearanceLayerCount, 51);
        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/item_scenes/all_appearances.png'),
        );

        controller.setBool('reduceMotion', true);
        tester.view.physicalSize = const Size(512, 640);
        await tester.pump();
        await pumpAppearanceLayers(tester, scene, 17);
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(scene.debugActiveAppearanceCount, itemIds.length);
        expect(scene.debugLoadedAppearanceLayerCount, 17);
        expect(scene.debugRequestedAppearanceLayerCount, 17);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        audio.dispose();
        controller.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
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
