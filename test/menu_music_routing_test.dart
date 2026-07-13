import 'dart:async';
import 'dart:math';

import 'package:aura_shift_six_seven/audio/audio_backend.dart';
import 'package:aura_shift_six_seven/audio/audio_catalog.dart';
import 'package:aura_shift_six_seven/audio/audio_selection.dart';
import 'package:aura_shift_six_seven/audio/aura_audio_controller.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('menu changes advance a shuffled looped soundtrack', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await GameController.load();
    final backend = _RecordingBackend();
    final expectedOrder = ShuffleBag<String>(
      AudioIds.soundtrack,
      random: Random(67),
    );
    final audio = await AuraAudioController.createForTesting(
      catalog: _testCatalog(),
      backend: backend,
      store: const _TestSettingsStore(),
      random: Random(67),
    );

    await audio.start(game);
    final selectedTracks = <String>[audio.currentSoundtrackId];
    expect(selectedTracks.single, expectedOrder.next());
    expect(backend.musicCalls, [selectedTracks.single]);
    expect(backend.musicLoops, [true]);

    // A completed handle and an unchanged menu cannot advance the soundtrack.
    await Future<void>.delayed(Duration.zero);
    await audio.setMusicContext(MusicContext.play);
    expect(backend.musicCalls, hasLength(1));

    // The first seven selections use every song exactly once, including the
    // two distinct menus that share MusicContext.menu.
    for (final tab in [1, 2, 3, 0, 1, 2]) {
      final previousTrack = audio.currentSoundtrackId;
      await audio.changeTab(tab);
      selectedTracks.add(audio.currentSoundtrackId);
      expect(audio.currentSoundtrackId, expectedOrder.next());
      expect(audio.currentSoundtrackId, isNot(previousTrack));
    }
    expect(selectedTracks.toSet(), AudioIds.soundtrack.toSet());
    expect(backend.musicCalls, selectedTracks);
    expect(backend.musicLoops, everyElement(isTrue));

    await audio.changeTab(3);
    expect(audio.currentSoundtrackId, expectedOrder.next());
    expect(audio.currentSoundtrackId, isNot(selectedTracks.last));

    audio.dispose();
    game.dispose();
  });
}

AudioAssetCatalog _testCatalog() => AudioAssetCatalog(
      AudioAssetCatalog.requiredIds.map((id) {
        final group = switch (id) {
          final music when music.startsWith('MUS-') => 'music',
          final cycle
              when cycle.startsWith('SFX-SIX-') ||
                  cycle.startsWith('SFX-SEVEN-') =>
            'cycle',
          final ui
              when ui.startsWith('SFX-UI-') ||
                  ui.startsWith('SFX-SHOP-') ||
                  ui.startsWith('SFX-COLLECTION-') =>
            'ui',
          _ => 'event',
        };
        final extension = group == 'music' ? 'ogg' : 'wav';
        return AudioAssetRecord(
          id: id,
          runtimePath: 'assets/audio/$group/${id.toLowerCase()}.$extension',
          group: group,
          kind: 'test',
          duration: const Duration(seconds: 1),
          loop: false,
        );
      }),
    );

class _TestSettingsStore implements AudioSettingsStore {
  const _TestSettingsStore();

  @override
  bool? readBool(String key) => null;

  @override
  double? readDouble(String key) => null;

  @override
  Future<void> writeBool(String key, bool value) async {}

  @override
  Future<void> writeDouble(String key, double value) async {}
}

class _RecordingBackend implements AudioBackend {
  final List<String> musicCalls = [];
  final List<bool> musicLoops = [];

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize({Iterable<String> preloadPaths = const []}) async {}

  @override
  Future<MusicPlaybackHandle> playMusic(
    String cachePath, {
    required double volume,
    required Duration transition,
    required bool loop,
    bool preservePosition = false,
  }) async {
    musicCalls.add(cachePath.split('/').last.split('.').first.toUpperCase());
    musicLoops.add(loop);
    return const _CompletedMusicHandle();
  }

  @override
  Future<void> pauseMusic() async {}

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
      const _CompletedAudioHandle();

  @override
  Future<void> resumeMusic() async {}

  @override
  Future<void> setMusicVolume(double volume) async {}

  @override
  Future<void> stopSounds() async {}
}

class _CompletedMusicHandle implements MusicPlaybackHandle {
  const _CompletedMusicHandle();

  @override
  Future<void> get completed => Future<void>.value();

  @override
  Stream<Duration> get position => const Stream<Duration>.empty();
}

class _CompletedAudioHandle implements AudioPlaybackHandle {
  const _CompletedAudioHandle();

  @override
  Future<void> get completed => Future<void>.value();

  @override
  Future<void> stop() async {}
}
