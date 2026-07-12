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

  test('approved catalog is exact and every one of its 44 IDs has a consumer',
      () {
    final catalogIds = catalog.all.map((record) => record.id).toSet();
    final consumerIds = AuraAudioController.consumerAssetIds.values
        .expand((ids) => ids)
        .toSet();
    expect(catalogIds, hasLength(44));
    expect(consumerIds, catalogIds);
    expect(catalog.music, hasLength(9));
    expect(catalog.soundEffects, hasLength(35));
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

  test('runtime preloads only cycle pools and routes layered, shop, and menu',
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
    expect(backend.layerCalls, hasLength(1));
    expect(backend.layerCalls.single.keys.toSet(), {
      catalog[AudioIds.gameBase].cachePath,
      catalog[AudioIds.gameGroove].cachePath,
      catalog[AudioIds.gameHype].cachePath,
    });
    expect(backend.layerCalls.single[catalog[AudioIds.gameBase].cachePath], 1);
    expect(
        backend.layerCalls.single[catalog[AudioIds.gameGroove].cachePath], 0);

    await audio.changeTab(1);
    expect(backend.musicCalls.last, catalog[AudioIds.shop].cachePath);
    final musicCallCount = backend.musicCalls.length;
    await audio.changeTab(1);
    expect(backend.musicCalls, hasLength(musicCallCount));
    await audio.changeTab(2);
    expect(backend.musicCalls.last, catalog[AudioIds.menu].cachePath);

    audio.dispose();
    game.dispose();
  });

  test('conditional mixes remain an executable fallback strategy', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await GameController.load();
    final backend = _FakeAudioBackend();
    final audio = await AuraAudioController.createForTesting(
      catalog: catalog,
      backend: backend,
      store: _MemoryAudioSettingsStore(),
      gameMusicStrategy: GameMusicStrategy.preRenderedMixes,
    );
    await audio.start(game);
    expect(backend.layerCalls, isEmpty);
    for (var millis = 0; millis <= 1600; millis += 200) {
      audio.recordCycle(CycleFamily.seven, nowMillis: millis);
      await Future<void>.delayed(Duration.zero);
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(
      backend.musicCalls,
      AudioIds.gameMixes.map((id) => catalog[id].cachePath).toList(),
    );
    audio.dispose();
    game.dispose();
  });

  test('I0-I3 emit the approved layered gains without stale-request pauses',
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
    for (var millis = 0; millis <= 400; millis += 200) {
      audio.recordCycle(CycleFamily.seven, nowMillis: millis);
    }
    await _waitUntil(() => backend.layerCalls.length == 2);
    backend.layerGate = Completer<void>();
    for (var millis = 600; millis <= 1000; millis += 200) {
      audio.recordCycle(CycleFamily.seven, nowMillis: millis);
      await Future<void>.delayed(Duration.zero);
    }
    await _waitUntil(() => backend.layerCalls.length == 3);
    for (var millis = 1200; millis <= 1600; millis += 200) {
      audio.recordCycle(CycleFamily.seven, nowMillis: millis);
    }
    backend.layerGate!.complete();
    await _waitUntil(() => backend.layerCalls.length == 4);

    final base = catalog[AudioIds.gameBase].cachePath;
    final groove = catalog[AudioIds.gameGroove].cachePath;
    final hype = catalog[AudioIds.gameHype].cachePath;
    expect(backend.layerCalls.map((call) => call[base]), [1, 1, 1, 1]);
    expect(backend.layerCalls.map((call) => call[groove]), [
      0,
      closeTo(.2511886432, 1e-10),
      closeTo(.5011872336, 1e-10),
      1,
    ]);
    expect(backend.layerCalls.map((call) => call[hype]), [
      0,
      0,
      closeTo(.1258925412, 1e-10),
      closeTo(.5011872336, 1e-10),
    ]);
    expect(backend.pauseCount, 0);
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

Future<void> _waitUntil(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for asynchronous audio routing.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
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
  Future<void> playMusic(
    String cachePath, {
    required double volume,
    required Duration transition,
    bool preservePosition = false,
  }) async {
    musicCalls.add(cachePath);
    volumeCalls.add(volume);
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
