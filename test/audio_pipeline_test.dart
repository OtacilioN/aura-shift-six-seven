import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aura_shift_six_seven/audio/audio_backend.dart';
import 'package:aura_shift_six_seven/audio/audio_catalog.dart';
import 'package:aura_shift_six_seven/audio/audio_selection.dart';
import 'package:aura_shift_six_seven/audio/aura_audio_controller.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AudioAssetCatalog catalog;

  setUpAll(() async {
    catalog = await AudioAssetCatalog.load();
  });

  test('approved catalog is exact and every one of its 42 IDs has a consumer',
      () {
    final catalogIds = catalog.all.map((record) => record.id).toSet();
    final consumerIds = AuraAudioController.consumerAssetIds.values
        .expand((ids) => ids)
        .toSet();
    expect(catalogIds, hasLength(42));
    expect(consumerIds, catalogIds);
    expect(catalog.music, hasLength(7));
    expect(catalog.soundEffects, hasLength(35));
    expect(AudioIds.soundtrack.first, AudioIds.bossShift);
    expect(catalog[AudioIds.bossShift].loop, isFalse);
  });

  test('catalog fails closed on unapproved, escaping, and duplicate records',
      () async {
    final source = jsonDecode(
      await rootBundle.loadString(AudioAssetCatalog.manifestPath),
    ) as Map<String, dynamic>;

    Map<String, dynamic> clone() =>
        jsonDecode(jsonEncode(source)) as Map<String, dynamic>;

    final unapproved = clone()..['status'] = 'candidate-reviewed';
    expect(() => AudioAssetCatalog.fromJson(unapproved), throwsFormatException);

    final escaping = clone();
    (escaping['assets'] as List).first['runtimePath'] =
        'assets/audio/../outside.wav';
    expect(() => AudioAssetCatalog.fromJson(escaping), throwsFormatException);

    final duplicate = clone();
    final assets = duplicate['assets'] as List;
    assets[1]['id'] = assets.first['id'];
    expect(() => AudioAssetCatalog.fromJson(duplicate), throwsFormatException);
  });

  test('shuffle bags exhaust all six variations without adjacent repetition',
      () {
    final bag = ShuffleBag<String>(AudioIds.six, random: Random(67));
    final draws = List.generate(24, (_) => bag.next());
    for (var offset = 0; offset < draws.length; offset += 6) {
      expect(draws.skip(offset).take(6).toSet(), AudioIds.six.toSet());
    }
    for (var index = 1; index < draws.length; index++) {
      expect(draws[index], isNot(draws[index - 1]));
    }
  });

  test('voice budget caps families and lets Seven displace the oldest Six', () {
    final budget = VoiceBudget();
    final six1 = budget.reserve(const VoiceRequest(
      bus: AudioBus.cycle,
      priority: 20,
      cycleFamily: CycleFamily.six,
    ))!;
    expect(
      budget.reserve(const VoiceRequest(
        bus: AudioBus.cycle,
        priority: 20,
        cycleFamily: CycleFamily.six,
      )),
      isNotNull,
    );
    expect(
      budget.reserve(const VoiceRequest(
        bus: AudioBus.cycle,
        priority: 20,
        cycleFamily: CycleFamily.six,
      )),
      isNull,
    );
    for (var i = 0; i < 2; i++) {
      expect(
        budget.reserve(const VoiceRequest(
          bus: AudioBus.cycle,
          priority: 30,
          cycleFamily: CycleFamily.seven,
        )),
        isNotNull,
      );
    }
    final thirdSeven = budget.reserve(const VoiceRequest(
      bus: AudioBus.cycle,
      priority: 30,
      cycleFamily: CycleFamily.seven,
    ));
    expect(thirdSeven?.evictedToken, six1.token);
    expect(budget.activeCount, 4);
  });

  test('cadence uses completed-cycle EMA, attack, hysteresis, and idle release',
      () {
    final cadence = CadenceIntensity();
    final tiers = <int, int>{};
    for (var millis = 0; millis <= 1600; millis += 200) {
      tiers[millis] = cadence.recordCycle(millis);
    }
    expect(tiers[800], lessThan(3));
    expect(
        tiers.entries.where((entry) => entry.key < 900),
        everyElement(
            predicate<MapEntry<int, int>>((entry) => entry.value < 3)));
    expect(tiers[1600], 3);
    expect(cadence.at(3400), 0);
  });

  test('session-randomized music loops until the player changes menu',
      () async {
    SharedPreferences.setMockInitialValues({});
    final game = await GameController.load();
    final backend = _FakeAudioBackend();
    final audio = await AuraAudioController.createForTesting(
      catalog: catalog,
      backend: backend,
      store: _MemoryAudioSettingsStore(),
    );

    await audio.start(game);
    expect(backend.preloaded, hasLength(13));
    expect(
      backend.preloaded.where((path) => path.contains('sfx/cycle/sfx_')),
      hasLength(12),
    );
    expect(
        backend.preloaded, contains(catalog[AudioIds.returnOffline].cachePath));
    expect(backend.layerCalls, isEmpty);
    final selectedTracks = <String>[audio.currentSoundtrackId];
    expect(AudioIds.soundtrack, contains(selectedTracks.single));
    expect(backend.musicCalls, [catalog[selectedTracks.single].cachePath]);
    expect(backend.musicLoops, [true]);

    final openingHandle = backend.musicHandles.single;
    openingHandle.emitPosition(catalog[selectedTracks.single].duration);
    openingHandle.complete();
    await Future<void>.delayed(Duration.zero);
    expect(backend.musicCalls, hasLength(1));

    // Each menu gets the next track in the session's shuffled order. Tabs 2
    // and 3 share a presentation context but are still separate menus.
    for (final tab in [1, 2, 3, 0, 1, 2]) {
      await audio.changeTab(tab);
      selectedTracks.add(audio.currentSoundtrackId);
    }
    expect(
      selectedTracks.toSet(),
      AudioIds.soundtrack.toSet(),
    );
    expect(
      backend.musicCalls,
      selectedTracks.map((id) => catalog[id].cachePath).toList(),
    );
    expect(backend.musicLoops, everyElement(isTrue));

    await audio.changeTab(3);
    expect(audio.currentSoundtrackId, isNot(selectedTracks.last));
    expect(backend.musicCalls, hasLength(8));

    audio.dispose();
    game.dispose();
  });

  test('mute, independent volumes, and latest lifecycle state win', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await GameController.load();
    final backend = _FakeAudioBackend();
    final store = _MemoryAudioSettingsStore({
      'audio.musicVolume': .6,
      'audio.effectsVolume': .4,
    });
    final audio = await AuraAudioController.createForTesting(
      catalog: catalog,
      backend: backend,
      store: store,
    );
    await audio.start(game);
    expect(audio.musicVolume, .6);
    expect(audio.effectsVolume, .4);
    expect(backend.musicCalls, hasLength(1));

    await audio.setMusicVolume(.25);
    await audio.setEffectsVolume(.35);
    expect(store.values['audio.musicVolume'], .25);
    expect(store.values['audio.effectsVolume'], .35);
    final disabling = audio.setEffectsEnabled(false);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await audio.setEffectsEnabled(true);
    await disabling;
    expect(audio.effectsMuted, isFalse);
    await audio.setMusicMuted(true);
    expect(backend.pauseCount, greaterThanOrEqualTo(1));
    await audio.setMusicMuted(false);
    expect(backend.resumeCount, greaterThanOrEqualTo(1));

    backend.pauseGate = Completer<void>();
    final inactive = audio.handleLifecycleState(AppLifecycleState.inactive);
    await Future<void>.delayed(Duration.zero);
    final resumed = audio.handleLifecycleState(AppLifecycleState.resumed);
    backend.pauseGate!.complete();
    await Future.wait([inactive, resumed]);
    expect(backend.resumeCount, greaterThanOrEqualTo(2));
    expect(backend.musicCalls, hasLength(1));

    audio.dispose();
    game.dispose();
  });

  test('cold muted navigation primes the selected loop silently before fade-in',
      () async {
    SharedPreferences.setMockInitialValues({});
    final game = await GameController.load();
    final backend = _FakeAudioBackend();
    final audio = await AuraAudioController.createForTesting(
      catalog: catalog,
      backend: backend,
      store: _MemoryAudioSettingsStore({
        'audio.musicMuted': true,
      }),
    );

    await audio.start(game);
    expect(backend.musicCalls, isEmpty);
    final openingTrack = audio.currentSoundtrackId;

    await audio.changeTab(1);
    final selectedTrack = audio.currentSoundtrackId;
    expect(selectedTrack, isNot(openingTrack));
    expect(backend.musicCalls, isEmpty);

    await audio.setMusicMuted(false);
    expect(backend.musicCalls, [catalog[selectedTrack].cachePath]);
    expect(backend.musicLoops, [true]);
    expect(backend.musicStartVolumes, [0]);
    expect(backend.resumeCount, 1);
    expect(backend.volumeCalls.last, closeTo(.72, 1e-10));

    audio.dispose();
    game.dispose();
  });

  test('cold load credits offline production once and emits a one-shot cue',
      () async {
    final leftAt = DateTime.now().millisecondsSinceEpoch - 3600000;
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({
        'offlineAt': leftAt,
        'offlineRate': '26800',
        'remainder': '0',
      }),
    });
    final game = await GameController.load();
    final credited = game.available;
    expect(credited, greaterThan(BigInt.zero));
    expect(game.consumeReturnAudioCue(), isTrue);
    expect(game.consumeReturnAudioCue(), isFalse);
    game.resume();
    expect(game.available, credited);
    game.dispose();
  });

  test('backend failures never prevent an interrupted game action', () async {
    final backend = _FakeAudioBackend()
      ..throwOnPause = true
      ..throwOnStopSounds = true
      ..throwOnResume = true;
    final audio = await AuraAudioController.createForTesting(
      catalog: catalog,
      backend: backend,
      store: _MemoryAudioSettingsStore(),
    );
    final previousHandler = FlutterError.onError;
    FlutterError.onError = (_) {};
    try {
      var actionRan = false;
      final value = await audio.whileInterrupted(() async {
        actionRan = true;
        return 67;
      });
      expect(actionRan, isTrue);
      expect(value, 67);
    } finally {
      backend
        ..throwOnPause = false
        ..throwOnStopSounds = false
        ..throwOnResume = false;
      audio.dispose();
      FlutterError.onError = previousHandler;
    }
  });
}

class _MemoryAudioSettingsStore implements AudioSettingsStore {
  _MemoryAudioSettingsStore([Map<String, Object>? initial])
      : values = {...?initial};
  final Map<String, Object> values;

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

class _FakeAudioBackend implements AudioBackend {
  final List<String> preloaded = [];
  final List<String> musicCalls = [];
  final List<bool> musicLoops = [];
  final List<double> musicStartVolumes = [];
  final List<_FakeMusicPlaybackHandle> musicHandles = [];
  final List<Map<String, double>> layerCalls = [];
  final List<String> soundCalls = [];
  final List<double> volumeCalls = [];
  final List<_FakePlaybackHandle> handles = [];
  Completer<void>? pauseGate;
  Completer<void>? layerGate;
  int pauseCount = 0;
  int resumeCount = 0;
  int stopSoundsCount = 0;
  bool disposed = false;
  bool throwOnPause = false;
  bool throwOnResume = false;
  bool throwOnStopSounds = false;

  @override
  Future<void> initialize({Iterable<String> preloadPaths = const []}) async {
    preloaded.addAll(preloadPaths);
  }

  @override
  Future<MusicPlaybackHandle> playMusic(
    String cachePath, {
    required double volume,
    required Duration transition,
    required bool loop,
    bool preservePosition = false,
  }) async {
    musicCalls.add(cachePath);
    musicLoops.add(loop);
    musicStartVolumes.add(volume);
    volumeCalls.add(volume);
    final handle = _FakeMusicPlaybackHandle();
    musicHandles.add(handle);
    return handle;
  }

  @override
  Future<void> playMusicLayers(
    Map<String, double> cachePathGains, {
    required double volume,
    required Duration transition,
  }) async {
    layerCalls.add({...cachePathGains});
    volumeCalls.add(volume);
    await layerGate?.future;
  }

  @override
  Future<AudioPlaybackHandle> playSound(
    String cachePath, {
    required double volume,
    required Duration duration,
  }) async {
    soundCalls.add(cachePath);
    final handle = _FakePlaybackHandle();
    handles.add(handle);
    return handle;
  }

  @override
  Future<void> setMusicVolume(double volume) async {
    volumeCalls.add(volume);
  }

  @override
  Future<void> pauseMusic() async {
    pauseCount++;
    await pauseGate?.future;
    if (throwOnPause) throw StateError('pause failed');
  }

  @override
  Future<void> resumeMusic() async {
    resumeCount++;
    if (throwOnResume) throw StateError('resume failed');
  }

  @override
  Future<void> stopSounds() async {
    stopSoundsCount++;
    if (throwOnStopSounds) throw StateError('stop failed');
    await Future.wait(handles.map((handle) => handle.stop()));
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await stopSounds();
    await Future.wait(musicHandles.map((handle) => handle.dispose()));
  }
}

class _FakeMusicPlaybackHandle implements MusicPlaybackHandle {
  final StreamController<Duration> _positions =
      StreamController<Duration>.broadcast(sync: true);
  final Completer<void> _completed = Completer<void>();

  @override
  Stream<Duration> get position => _positions.stream;

  @override
  Future<void> get completed => _completed.future;

  void emitPosition(Duration position) => _positions.add(position);

  void complete() {
    if (!_completed.isCompleted) _completed.complete();
  }

  Future<void> dispose() async {
    complete();
    await _positions.close();
  }
}

class _FakePlaybackHandle implements AudioPlaybackHandle {
  final Completer<void> _completed = Completer<void>();

  @override
  Future<void> get completed => _completed.future;

  @override
  Future<void> stop() async {
    if (!_completed.isCompleted) _completed.complete();
  }
}
