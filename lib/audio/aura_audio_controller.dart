import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_controller.dart';
import 'audio_backend.dart';
import 'audio_catalog.dart';
import 'audio_selection.dart';

enum GameMusicStrategy {
  /// Starts Base/Groove/Hype together and changes only their gains by tier.
  /// Physical-device synchronization remains a release gate.
  requiredAdaptiveTracks,

  /// Uses the four approved conditional I0-I3 renders when a device/backend
  /// cannot layer or transition the required gameplay material reliably.
  preRenderedMixes,
}

abstract interface class AudioSettingsStore {
  double? readDouble(String key);
  bool? readBool(String key);
  Future<void> writeDouble(String key, double value);
  Future<void> writeBool(String key, bool value);
}

class SharedPreferencesAudioSettingsStore implements AudioSettingsStore {
  const SharedPreferencesAudioSettingsStore(this.preferences);
  final SharedPreferences preferences;

  @override
  double? readDouble(String key) => preferences.getDouble(key);

  @override
  bool? readBool(String key) => preferences.getBool(key);

  @override
  Future<void> writeDouble(String key, double value) async {
    await preferences.setDouble(key, value);
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    await preferences.setBool(key, value);
  }
}

/// Owns audio presentation only. Gameplay crediting, purchases and progression
/// remain exclusively in [GameController]. Every public playback method is
/// failure-isolated so unavailable audio can never block a game action.
class AuraAudioController extends ChangeNotifier {
  AuraAudioController._({
    required AudioAssetCatalog? catalog,
    required AudioBackend backend,
    required AudioSettingsStore store,
    required bool available,
    required Random random,
    required this.gameMusicStrategy,
    int Function()? nowMillis,
  })  : _catalog = catalog,
        _backend = backend,
        _store = store,
        _available = available,
        _sixBag = ShuffleBag<String>(AudioIds.six, random: random),
        _sevenBag = ShuffleBag<String>(AudioIds.seven, random: random),
        _nowMillisOverride = nowMillis {
    _musicVolume = (_store.readDouble(_musicVolumeKey) ?? .72).clamp(0, 1);
    _effectsVolume = (_store.readDouble(_effectsVolumeKey) ?? .86).clamp(0, 1);
    _musicMuted = _store.readBool(_musicMutedKey) ?? false;
    _effectsMuted = _store.readBool(_effectsMutedKey) ?? false;
  }

  static const _musicVolumeKey = 'audio.musicVolume';
  static const _effectsVolumeKey = 'audio.effectsVolume';
  static const _musicMutedKey = 'audio.musicMuted';
  static const _effectsMutedKey = 'audio.effectsMuted';
  static const _dialogDuck = .3981071706; // -8 dB

  static Future<AuraAudioController> create({
    GameMusicStrategy gameMusicStrategy =
        GameMusicStrategy.requiredAdaptiveTracks,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesAudioSettingsStore(preferences);
    AudioAssetCatalog? catalog;
    final backend = FlameAudioBackend();
    var available = true;
    try {
      catalog = await AudioAssetCatalog.load();
      await backend.initialize(
        preloadPaths: _preloadIds.map((id) => catalog![id].cachePath),
      );
    } catch (error, stackTrace) {
      available = false;
      try {
        await backend.dispose();
      } catch (_) {
        // The original initialization failure is the actionable error.
      }
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'aura audio',
        context: ErrorDescription('while initializing optional game audio'),
      ));
    }
    return AuraAudioController._(
      catalog: catalog,
      backend: backend,
      store: store,
      available: available,
      random: Random(),
      gameMusicStrategy: gameMusicStrategy,
    );
  }

  @visibleForTesting
  static Future<AuraAudioController> createForTesting({
    required AudioAssetCatalog catalog,
    required AudioBackend backend,
    required AudioSettingsStore store,
    Random? random,
    int Function()? nowMillis,
    GameMusicStrategy gameMusicStrategy =
        GameMusicStrategy.requiredAdaptiveTracks,
  }) async {
    await backend.initialize(
      preloadPaths: _preloadIds.map((id) => catalog[id].cachePath),
    );
    return AuraAudioController._(
      catalog: catalog,
      backend: backend,
      store: store,
      available: true,
      random: random ?? Random(67),
      nowMillis: nowMillis,
      gameMusicStrategy: gameMusicStrategy,
    );
  }

  static const Set<String> _preloadIds = {
    ...AudioIds.six,
    ...AudioIds.seven,
    AudioIds.returnOffline,
  };

  /// Registry audited by tests. Conditional mixes and required adaptive tracks
  /// are both explicit consumers, even though only one strategy is active.
  static final Map<String, Set<String>> consumerAssetIds = {
    'required-music': {
      AudioIds.gameBase,
      AudioIds.gameGroove,
      AudioIds.gameHype,
      AudioIds.menu,
      AudioIds.shop,
    },
    'conditional-music-fallback': {...AudioIds.gameMixes},
    'cycle-shuffle-bags': {...AudioIds.six, ...AudioIds.seven},
    'ui-shop-collection': {
      AudioIds.uiTab,
      AudioIds.uiOpen,
      AudioIds.uiClose,
      AudioIds.uiToggleOn,
      AudioIds.uiToggleOff,
      AudioIds.uiError,
      AudioIds.shopPurchase,
      AudioIds.shopBatch,
      AudioIds.shopUnavailable,
      AudioIds.shopUnlock,
      AudioIds.shopMilestone,
      AudioIds.collectionEquip,
      AudioIds.collectionHide,
    },
    'progression-events': {
      for (var i = 1; i <= 5; i++) AudioIds.form(i),
      AudioIds.achievement,
      AudioIds.ascension,
      AudioIds.mark67,
      AudioIds.returnOffline,
      AudioIds.returnBonus,
    },
  };

  final AudioAssetCatalog? _catalog;
  final AudioBackend _backend;
  final AudioSettingsStore _store;
  final ShuffleBag<String> _sixBag;
  final ShuffleBag<String> _sevenBag;
  final VoiceBudget _voices = VoiceBudget();
  final Map<int, AudioPlaybackHandle> _voiceHandles = {};
  final CadenceIntensity _cadence = CadenceIntensity();
  final int Function()? _nowMillisOverride;
  final Stopwatch _audioClock = Stopwatch()..start();
  final GameMusicStrategy gameMusicStrategy;
  final bool _available;
  bool _disposed = false;
  bool _appActive = true;
  int _interruptionDepth = 0;
  int _duckDepth = 0;
  int _volumeGeneration = 0;
  int _effectsGeneration = 0;
  int _effectsToggleGeneration = 0;
  int _musicRequest = 0;
  Future<void> _musicQueue = Future<void>.value();
  int _lifecycleGeneration = 0;
  Future<void> _lifecycleQueue = Future<void>.value();
  Timer? _cadenceReleaseTimer;
  final Map<int, double> _transientDucks = {};
  final Map<int, Timer> _transientDuckTimers = {};
  int _nextDuckToken = 0;
  GameController? _game;
  Set<String> _knownForms = {};
  Set<String> _knownAchievements = {};
  Set<String> _knownSeals = {};
  MusicContext _musicContext = MusicContext.play;
  String? _playingMusicId;
  int _intensity = 0;
  late double _musicVolume;
  late double _effectsVolume;
  late bool _musicMuted;
  late bool _effectsMuted;
  bool _suppressNextAchievement = false;

  bool get available => _available;
  double get musicVolume => _musicVolume;
  double get effectsVolume => _effectsVolume;
  bool get musicMuted => _musicMuted;
  bool get effectsMuted => _effectsMuted;
  MusicContext get musicContext => _musicContext;
  int get musicIntensity => _intensity;
  int get _currentMillis =>
      _nowMillisOverride?.call() ?? _audioClock.elapsedMilliseconds;

  Future<void> start(GameController game) async {
    if (_disposed) return;
    if (!identical(_game, game)) {
      _game?.removeListener(_onGameChanged);
      _game = game;
      _knownForms = {...game.transformations};
      _knownAchievements = {...game.achievements};
      _knownSeals = {...game.seals};
      game.addListener(_onGameChanged);
    }
    await _ensureMusic(transition: Duration.zero);
    if (game.consumeReturnAudioCue()) {
      unawaited(playReturnOffline());
    }
  }

  Future<void> setMusicContext(MusicContext context) async {
    if (_musicContext == context) return;
    final wasPlay = _musicContext == MusicContext.play;
    _musicContext = context;
    await _ensureMusic(
      transition: const Duration(milliseconds: 600),
      preservePosition: wasPlay && context == MusicContext.play,
    );
  }

  Future<void> changeTab(int tab) async {
    unawaited(playUiTab());
    final context = switch (tab) {
      0 => MusicContext.play,
      1 => MusicContext.shop,
      _ => MusicContext.menu,
    };
    await setMusicContext(context);
  }

  void recordCycle(CycleFamily family, {int? nowMillis}) {
    if (family == CycleFamily.six) {
      unawaited(_play(
        _sixBag.next(),
        const VoiceRequest(
          bus: AudioBus.cycle,
          priority: 20,
          cycleFamily: CycleFamily.six,
        ),
      ));
      return;
    }

    unawaited(_play(
      _sevenBag.next(),
      const VoiceRequest(
        bus: AudioBus.cycle,
        priority: 30,
        cycleFamily: CycleFamily.seven,
      ),
    ));
    _pulseMusicDuck(
      factor: .8413951416, // -1.5 dB
      duration: const Duration(milliseconds: 80),
    );
    final now = nowMillis ?? _currentMillis;
    _updateIntensity(_cadence.recordCycle(now));
    _cadenceReleaseTimer?.cancel();
    _cadenceReleaseTimer = Timer(_cadence.idleRelease, () {
      _updateIntensity(_cadence.at(_currentMillis));
    });
  }

  Future<void> playUiTab() => _playUi(AudioIds.uiTab, priority: 10);
  Future<void> playUiOpen() => _playUi(AudioIds.uiOpen, priority: 12);
  Future<void> playUiClose() => _playUi(AudioIds.uiClose, priority: 12);
  Future<void> playUiError() => _playUi(AudioIds.uiError, priority: 22);
  Future<void> playToggle(bool enabled) => _playUi(
        enabled ? AudioIds.uiToggleOn : AudioIds.uiToggleOff,
        priority: 14,
      );

  Future<void> playPurchaseResult({
    required bool success,
    required int quantity,
    bool unlockedAppearance = false,
    bool levelMilestone = false,
  }) async {
    if (!success) {
      await _playUi(AudioIds.shopUnavailable, priority: 25);
      return;
    }
    unawaited(_playUi(
      quantity == 1 ? AudioIds.shopPurchase : AudioIds.shopBatch,
      priority: 25,
    ));
    if (unlockedAppearance) {
      unawaited(_playUi(AudioIds.shopUnlock, priority: 35));
    }
    if (levelMilestone) {
      unawaited(_playUi(AudioIds.shopMilestone, priority: 32));
    }
  }

  Future<void> playCollectionChange({required bool hidden}) => _playUi(
        hidden ? AudioIds.collectionHide : AudioIds.collectionEquip,
        priority: 24,
      );

  Future<void> playAscension() => _playEvent(AudioIds.ascension, priority: 100);
  void prepareAscension() => _suppressNextAchievement = true;
  Future<void> playReturnOffline() =>
      _playEvent(AudioIds.returnOffline, priority: 65);
  Future<void> playReturnBonus() =>
      _playEvent(AudioIds.returnBonus, priority: 75);

  Future<void> beginDuck() async {
    _duckDepth++;
    await _applyMusicVolume();
  }

  Future<void> endDuck() async {
    if (_duckDepth > 0) _duckDepth--;
    await _applyMusicVolume();
  }

  Future<T> whileDucked<T>(Future<T> Function() action) async {
    await beginDuck();
    try {
      return await action();
    } finally {
      await endDuck();
    }
  }

  Future<T> whileInterrupted<T>(Future<T> Function() action) async {
    await pauseForInterruption();
    try {
      return await action();
    } finally {
      await resumeAfterInterruption();
    }
  }

  Future<void> pauseForInterruption() async {
    _interruptionDepth++;
    if (_interruptionDepth == 1) await _suspendPlayback();
  }

  Future<void> resumeAfterInterruption() async {
    if (_interruptionDepth > 0) _interruptionDepth--;
    if (_interruptionDepth == 0 && _appActive) await _resumePlayback();
  }

  Future<void> handleLifecycleState(AppLifecycleState state) async {
    final shouldBeActive = state == AppLifecycleState.resumed;
    if (_appActive == shouldBeActive) return;
    _appActive = shouldBeActive;
    final generation = ++_lifecycleGeneration;
    _lifecycleQueue = _lifecycleQueue.catchError((_) {}).then((_) async {
      if (generation != _lifecycleGeneration) return;
      if (_appActive) {
        if (_interruptionDepth == 0) await _resumePlayback();
      } else {
        await _suspendPlayback();
      }
    });
    await _lifecycleQueue;
  }

  Future<void> setMusicVolume(double value) async {
    _musicVolume = value.clamp(0, 1);
    notifyListeners();
    unawaited(_guardSetting(
      () => _store.writeDouble(_musicVolumeKey, _musicVolume),
      'persisting music volume',
    ));
    await _applyMusicVolume();
  }

  Future<void> setEffectsVolume(double value) async {
    _effectsVolume = value.clamp(0, 1);
    notifyListeners();
    unawaited(_guardSetting(
      () => _store.writeDouble(_effectsVolumeKey, _effectsVolume),
      'persisting effects volume',
    ));
    if (_effectsVolume == 0) await _stopEffects();
  }

  Future<void> setMusicMuted(bool value) async {
    if (_musicMuted == value) return;
    _musicMuted = value;
    notifyListeners();
    unawaited(_guardSetting(
      () => _store.writeBool(_musicMutedKey, value),
      'persisting music mute',
    ));
    if (value) {
      _musicRequest++;
      await _guardBackend(_backend.pauseMusic, 'muting music');
    } else if (_canPlay) {
      await _ensureMusic(transition: const Duration(milliseconds: 400));
      await _resumePlayback();
    }
  }

  Future<void> setEffectsMuted(bool value) {
    _effectsToggleGeneration++;
    return _applyEffectsMuted(value);
  }

  Future<void> _applyEffectsMuted(bool value) async {
    if (_effectsMuted == value) return;
    _effectsMuted = value;
    notifyListeners();
    unawaited(_guardSetting(
      () => _store.writeBool(_effectsMutedKey, value),
      'persisting effects mute',
    ));
    if (value) await _stopEffects();
  }

  Future<void> setEffectsEnabled(bool enabled) async {
    final generation = ++_effectsToggleGeneration;
    if (enabled) {
      await _applyEffectsMuted(false);
      if (generation != _effectsToggleGeneration) return;
      await playToggle(true);
      return;
    }
    if (_effectsMuted) return;
    await playToggle(false);
    final duration = _catalog?[AudioIds.uiToggleOff].duration ??
        const Duration(milliseconds: 140);
    await Future<void>.delayed(duration);
    if (generation == _effectsToggleGeneration) {
      await _applyEffectsMuted(true);
    }
  }

  bool get _canPlay =>
      _available && !_disposed && _appActive && _interruptionDepth == 0;
  double get _effectiveMusicVolume => _musicMuted
      ? 0
      : _musicVolume *
          (_duckDepth > 0 ? _dialogDuck : 1) *
          _transientDuckFactor *
          (_musicContext == MusicContext.play &&
                  gameMusicStrategy == GameMusicStrategy.requiredAdaptiveTracks
              ? .9332543008 // -0.6 dB shared layered headroom trim
              : 1);

  double get _transientDuckFactor => _transientDucks.values.fold<double>(
        1,
        (current, factor) => min(current, factor),
      );

  void _pulseMusicDuck({
    required double factor,
    required Duration duration,
  }) {
    if (!_canPlay || _musicMuted || _effectsMuted || _effectsVolume <= 0) {
      return;
    }
    final token = ++_nextDuckToken;
    _transientDucks[token] = factor;
    unawaited(_applyMusicVolume());
    _transientDuckTimers[token] = Timer(duration, () {
      _transientDucks.remove(token);
      _transientDuckTimers.remove(token);
      unawaited(_applyMusicVolume());
    });
  }

  void _updateIntensity(int next) {
    if (_intensity == next) return;
    _intensity = next;
    if (_musicContext == MusicContext.play) {
      unawaited(_ensureMusic(
        transition: const Duration(milliseconds: 700),
        preservePosition: true,
      ));
    }
  }

  String get _desiredMusicRoute {
    return switch (_musicContext) {
      MusicContext.menu => AudioIds.menu,
      MusicContext.shop => AudioIds.shop,
      MusicContext.play => switch (gameMusicStrategy) {
          GameMusicStrategy.requiredAdaptiveTracks =>
            'GAME-LAYERS-I$_intensity',
          GameMusicStrategy.preRenderedMixes => AudioIds.gameMixes[_intensity],
        },
    };
  }

  static Map<String, double> layerGainsForIntensity(int intensity) {
    if (intensity < 0 || intensity > 3) {
      throw RangeError.range(intensity, 0, 3, 'intensity');
    }
    const gains = <Map<String, double>>[
      {AudioIds.gameBase: 1, AudioIds.gameGroove: 0, AudioIds.gameHype: 0},
      {
        AudioIds.gameBase: 1,
        AudioIds.gameGroove: .2511886432, // -12 dB
        AudioIds.gameHype: 0,
      },
      {
        AudioIds.gameBase: 1,
        AudioIds.gameGroove: .5011872336, // -6 dB
        AudioIds.gameHype: .1258925412, // -18 dB
      },
      {
        AudioIds.gameBase: 1,
        AudioIds.gameGroove: 1,
        AudioIds.gameHype: .5011872336,
      },
    ];
    return gains[intensity];
  }

  Map<String, double> get _desiredLayerGains =>
      layerGainsForIntensity(_intensity);

  Future<void> _ensureMusic({
    required Duration transition,
    bool preservePosition = false,
  }) {
    if (!_canPlay || _musicMuted || _catalog == null) return Future.value();
    final route = _desiredMusicRoute;
    if (_playingMusicId == route) return _applyMusicVolume();
    final request = ++_musicRequest;
    _musicQueue = _musicQueue.catchError((_) {}).then((_) async {
      if (request != _musicRequest || !_canPlay || _musicMuted) return;
      try {
        if (_musicContext == MusicContext.play &&
            gameMusicStrategy == GameMusicStrategy.requiredAdaptiveTracks) {
          await _backend.playMusicLayers(
            {
              for (final entry in _desiredLayerGains.entries)
                _catalog[entry.key].cachePath: entry.value,
            },
            volume: _effectiveMusicVolume,
            transition: transition,
          );
        } else {
          final record = _catalog[route];
          await _backend.playMusic(
            record.cachePath,
            volume: _effectiveMusicVolume,
            transition: transition,
            preservePosition: preservePosition,
          );
        }
        if (request == _musicRequest && _canPlay && !_musicMuted) {
          _playingMusicId = route;
        } else if (!_canPlay || _musicMuted) {
          await _backend.pauseMusic();
        }
      } catch (error, stackTrace) {
        _reportAudioError(error, stackTrace, 'switching music to $route');
      }
    });
    return _musicQueue;
  }

  Future<void> _applyMusicVolume() async {
    if (!_available || _disposed) return;
    try {
      await _backend.setMusicVolume(_effectiveMusicVolume);
    } catch (error, stackTrace) {
      _reportAudioError(error, stackTrace, 'setting music volume');
    }
  }

  Future<void> _suspendPlayback() async {
    _volumeGeneration++;
    _musicRequest++;
    await Future.wait([
      _guardBackend(_backend.pauseMusic, 'suspending music'),
      _stopEffects(),
    ]);
  }

  Future<void> _resumePlayback() async {
    if (!_canPlay || _musicMuted) return;
    await _ensureMusic(transition: const Duration(milliseconds: 400));
    final generation = ++_volumeGeneration;
    try {
      await _backend.setMusicVolume(0);
      await _backend.resumeMusic();
      const steps = 8;
      for (var step = 1; step <= steps; step++) {
        if (generation != _volumeGeneration || !_canPlay) return;
        await _backend.setMusicVolume(
          _effectiveMusicVolume * step / steps,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    } catch (error, stackTrace) {
      _reportAudioError(error, stackTrace, 'resuming music');
    }
  }

  Future<void> _playUi(String id, {required int priority}) => _play(
        id,
        VoiceRequest(bus: AudioBus.ui, priority: priority),
      );

  Future<void> _playEvent(String id, {required int priority}) {
    if (priority >= 88) {
      _pulseMusicDuck(
        factor: .6309573445, // -4 dB
        duration: const Duration(milliseconds: 1200),
      );
    }
    return _play(
      id,
      VoiceRequest(bus: AudioBus.event, priority: priority),
    );
  }

  Future<void> _play(String id, VoiceRequest request) async {
    if (!_canPlay || _effectsMuted || _effectsVolume <= 0 || _catalog == null) {
      return;
    }
    final reservation = _voices.reserve(request);
    if (reservation == null) return;
    final generation = _effectsGeneration;
    final evicted = reservation.evictedToken;
    if (evicted != null) {
      final handle = _voiceHandles.remove(evicted);
      if (handle != null) {
        unawaited(_guardBackend(handle.stop, 'preempting an audio voice'));
      }
    }
    try {
      final record = _catalog[id];
      final handle = await _backend.playSound(
        record.cachePath,
        volume: _effectsVolume,
        duration: record.duration,
      );
      if (!_voices.contains(reservation.token) ||
          generation != _effectsGeneration ||
          !_canPlay ||
          _effectsMuted ||
          _effectsVolume <= 0) {
        _voices.release(reservation.token);
        await handle.stop();
        return;
      }
      _voiceHandles[reservation.token] = handle;
      unawaited(handle.completed.whenComplete(() {
        _voiceHandles.remove(reservation.token);
        _voices.release(reservation.token);
      }));
    } catch (error, stackTrace) {
      _voices.release(reservation.token);
      _reportAudioError(error, stackTrace, 'playing $id');
    }
  }

  Future<void> _stopEffects() async {
    _effectsGeneration++;
    final handles = _voiceHandles.values.toList(growable: false);
    _voiceHandles.clear();
    _voices.clear();
    await Future.wait([
      ...handles.map(
          (handle) => _guardBackend(handle.stop, 'stopping an audio voice')),
      _guardBackend(_backend.stopSounds, 'stopping sound effects'),
    ]);
  }

  void _onGameChanged() {
    final game = _game;
    if (game == null || _disposed) return;
    if (game.consumeReturnAudioCue()) unawaited(playReturnOffline());
    final newForms = game.transformations.difference(_knownForms);
    final newSeals = game.seals.difference(_knownSeals);
    final newAchievements = game.achievements.difference(_knownAchievements);
    _knownForms = {...game.transformations};
    _knownSeals = {...game.seals};
    _knownAchievements = {...game.achievements};

    if (newForms.isNotEmpty) {
      final number = newForms
          .map((id) => int.tryParse(id.split('-').last) ?? 0)
          .reduce(max);
      unawaited(_playEvent(AudioIds.form(number), priority: 90 + number));
    } else if (newSeals.isNotEmpty) {
      unawaited(_playEvent(AudioIds.mark67, priority: 88));
    } else if (newAchievements.isNotEmpty && !_suppressNextAchievement) {
      unawaited(_playEvent(AudioIds.achievement, priority: 70));
    }
    _suppressNextAchievement = false;
  }

  void _reportAudioError(Object error, StackTrace stackTrace, String context) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'aura audio',
      context: ErrorDescription('while $context'),
    ));
  }

  Future<void> _guardBackend(
    Future<void> Function() operation,
    String context,
  ) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      _reportAudioError(error, stackTrace, context);
    }
  }

  Future<void> _guardSetting(
    Future<void> Function() operation,
    String context,
  ) =>
      _guardBackend(operation, context);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _game?.removeListener(_onGameChanged);
    _game = null;
    _cadenceReleaseTimer?.cancel();
    _audioClock.stop();
    for (final timer in _transientDuckTimers.values) {
      timer.cancel();
    }
    _transientDuckTimers.clear();
    _transientDucks.clear();
    _volumeGeneration++;
    unawaited(_guardBackend(_backend.dispose, 'disposing audio'));
    super.dispose();
  }
}
