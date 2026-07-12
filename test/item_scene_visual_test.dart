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
  const captureGoldens = bool.fromEnvironment('ITEM_SCENE_GOLDENS');

  late AudioAssetCatalog audioCatalog;

  setUpAll(() async {
    audioCatalog = await AudioAssetCatalog.load();
  });

  final itemIds = <String>[
    for (final branch in const ['A', 'B', 'C'])
      for (var depth = 1; depth <= 5; depth++) 'ITEM-$branch-0$depth',
    for (var depth = 1; depth <= 3; depth++) 'ITEM-CONV-0$depth',
  ];

  for (final itemId in itemIds) {
    for (final reduceMotion in const [false, true]) {
      final motionLabel = reduceMotion ? 'reduced' : 'animated';
      testWidgets('$itemId has a stable $motionLabel scene composition',
          (tester) async {
        tester.view
          ..physicalSize = const Size(512, 640)
          ..devicePixelRatio = 1;
        SharedPreferences.setMockInitialValues({
          'save-v1': jsonEncode({
            'levels': {itemId: 25},
            'appearances': [itemId],
            'equipped': itemId,
            'reduceMotion': reduceMotion,
            'locale': 'pt-BR',
          }),
        });
        final controller = await GameController.loadForTesting();
        final audio = await AuraAudioController.createForTesting(
          catalog: audioCatalog,
          backend: _SilentAudioBackend(),
          store: _MemoryAudioStore(),
        );

        try {
          final boundaryKey = ValueKey('scene-$itemId-$motionLabel');
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RepaintBoundary(
                  key: boundaryKey,
                  child: SizedBox.expand(
                    child: GameWidget(
                      game: AuraScene(controller, audio),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull);

          if (captureGoldens && !reduceMotion) {
            final filename = itemId.toLowerCase().replaceAll('-', '_');
            await expectLater(
              find.byKey(boundaryKey),
              matchesGoldenFile('goldens/item_scenes/$filename.png'),
            );
          } else {
            expect(find.byKey(boundaryKey), findsOneWidget);
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          audio.dispose();
          controller.dispose();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      });
    }
  }
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
  Future<void> playMusic(
    String cachePath, {
    required double volume,
    required Duration transition,
    bool preservePosition = false,
  }) async {}

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
