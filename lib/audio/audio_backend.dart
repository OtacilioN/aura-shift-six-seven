import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

abstract interface class AudioPlaybackHandle {
  Future<void> get completed;
  Future<void> stop();
}

abstract interface class AudioBackend {
  Future<void> initialize({Iterable<String> preloadPaths = const []});

  Future<void> playMusic(
    String cachePath, {
    required double volume,
    required Duration transition,
    bool preservePosition = false,
  });

  /// Starts all sources before publishing the group, then changes intensity by
  /// gain only. The platform still owns exact scheduling, so physical-device
  /// drift verification remains a release gate.
  Future<void> playMusicLayers(
    Map<String, double> cachePathGains, {
    required double volume,
    required Duration transition,
  });

  Future<void> setMusicVolume(double volume);
  Future<void> pauseMusic();
  Future<void> resumeMusic();

  Future<AudioPlaybackHandle> playSound(
    String cachePath, {
    required double volume,
    required Duration duration,
  });

  Future<void> stopSounds();
  Future<void> dispose();
}

class _MusicVoice {
  const _MusicVoice(this.player, this.gain);
  final AudioPlayer player;
  final double gain;

  _MusicVoice withGain(double value) => _MusicVoice(player, value);
}

/// Production backend. Cycle WAVs use persistent Flame AudioPools; music owns
/// focus while one-shot SFX mix without requesting focus on every contact.
class FlameAudioBackend implements AudioBackend {
  FlameAudioBackend()
      : _cache = AudioCache(prefix: 'assets/audio/'),
        _musicContext = AudioContextConfig(
          focus: AudioContextConfigFocus.gain,
          stayAwake: false,
        ).build(),
        _effectsContext = AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          stayAwake: false,
        ).build(),
        _musicFollowerContext = AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          stayAwake: false,
        ).build();

  final AudioCache _cache;
  final AudioContext _musicContext;
  final AudioContext _effectsContext;
  final AudioContext _musicFollowerContext;
  final Map<String, AudioPool> _effectPools = {};
  final Set<AudioPlaybackHandle> _sounds = {};
  final Set<AudioPlayer> _transitionPlayers = {};
  Map<String, _MusicVoice> _musicVoices = {};
  String _musicSignature = '';
  double _musicVolume = 1;
  int _musicGeneration = 0;
  int _soundGeneration = 0;
  bool _musicPaused = false;
  bool _disposed = false;

  @override
  Future<void> initialize({Iterable<String> preloadPaths = const []}) async {
    if (_disposed) return;
    await AudioPlayer.global.setAudioContext(_musicContext);
    final paths = preloadPaths.toSet().toList(growable: false);
    await _cache.loadAll(paths);
    for (final path in paths) {
      if (_disposed) return;
      _effectPools[path] = await AudioPool.create(
        source: AssetSource(path),
        audioCache: _cache,
        audioContext: _effectsContext,
        minPlayers: 1,
        maxPlayers: path.contains('sfx_seven_') ? 3 : 2,
        playerMode: PlayerMode.lowLatency,
      );
    }
  }

  @override
  Future<void> playMusic(
    String cachePath, {
    required double volume,
    required Duration transition,
    bool preservePosition = false,
  }) {
    return _switchMusic(
      signature: 'single:$cachePath',
      pathGains: {cachePath: 1},
      volume: volume,
      transition: transition,
      preservePosition: preservePosition,
    );
  }

  @override
  Future<void> playMusicLayers(
    Map<String, double> cachePathGains, {
    required double volume,
    required Duration transition,
  }) {
    final paths = cachePathGains.keys.toList()..sort();
    return _switchMusic(
      signature: 'layers:${paths.join('|')}',
      pathGains: cachePathGains,
      volume: volume,
      transition: transition,
      preservePosition: false,
    );
  }

  Future<void> _switchMusic({
    required String signature,
    required Map<String, double> pathGains,
    required double volume,
    required Duration transition,
    required bool preservePosition,
  }) async {
    if (_disposed) return;
    _musicVolume = volume.clamp(0, 1);
    if (_musicSignature == signature &&
        _musicVoices.keys.toSet().containsAll(pathGains.keys) &&
        pathGains.keys.toSet().containsAll(_musicVoices.keys)) {
      await _fadeCurrentGains(pathGains, transition);
      return;
    }

    final generation = ++_musicGeneration;
    final previous = Map<String, _MusicVoice>.from(_musicVoices);
    Duration? position;
    if (preservePosition && previous.isNotEmpty) {
      position = await previous.values.first.player.getCurrentPosition();
    }

    final entries = pathGains.entries.toList(growable: false);
    final created = <AudioPlayer>{};
    late final List<_MusicVoice> prepared;
    try {
      prepared = await Future.wait(entries.asMap().entries.map((indexed) async {
        final entry = indexed.value;
        final player = AudioPlayer(
          playerId: 'aura-music-$generation-${indexed.key}',
        )..audioCache = _cache;
        created.add(player);
        _transitionPlayers.add(player);
        try {
          await player.setAudioContext(
            indexed.key == 0 ? _musicContext : _musicFollowerContext,
          );
          await player.setPlayerMode(PlayerMode.mediaPlayer);
          await player.setReleaseMode(ReleaseMode.loop);
          await player.setVolume(0);
          await player.setSource(AssetSource(entry.key));
          if (position != null && position > Duration.zero) {
            await player.seek(position);
          }
          return _MusicVoice(player, entry.value.clamp(0, 1));
        } catch (_) {
          _transitionPlayers.remove(player);
          await player.dispose();
          rethrow;
        }
      }));
    } catch (_) {
      await _disposePlayers(created);
      if (_disposed) return;
      rethrow;
    }

    if (_disposed || generation != _musicGeneration) {
      await _disposePlayers(prepared.map((voice) => voice.player));
      return;
    }

    try {
      if (!_musicPaused) {
        await Future.wait(prepared.map((voice) => voice.player.resume()));
      }
      if (_musicPaused) {
        await Future.wait(prepared
            .map((voice) => voice.player)
            .where((player) => player.state == PlayerState.playing)
            .map((player) => player.pause()));
      }
    } catch (_) {
      await _disposePlayers(created);
      if (_disposed) return;
      rethrow;
    }
    if (_disposed || generation != _musicGeneration) {
      await _disposePlayers(prepared.map((voice) => voice.player));
      return;
    }

    final next = <String, _MusicVoice>{
      for (var index = 0; index < entries.length; index++)
        entries[index].key: prepared[index],
    };
    _musicVoices = next;
    _musicSignature = signature;
    _transitionPlayers.addAll(previous.values.map((voice) => voice.player));

    try {
      if (previous.isEmpty || transition == Duration.zero) {
        await _setVoiceVolumes(next, ratio: 1);
        return;
      }

      final previousVolumes = {
        for (final voice in previous.values) voice.player: voice.player.volume,
      };
      const steps = 12;
      final stepDelay = Duration(
        microseconds: transition.inMicroseconds ~/ steps,
      );
      for (var step = 1; step <= steps; step++) {
        if (_disposed || generation != _musicGeneration) return;
        final ratio = step / steps;
        await Future.wait([
          _setVoiceVolumes(next, ratio: ratio),
          ...previousVolumes.entries.map(
            (entry) => entry.key.setVolume(entry.value * (1 - ratio)),
          ),
        ]);
        if (stepDelay > Duration.zero) await Future<void>.delayed(stepDelay);
      }
    } finally {
      await _disposePlayers(previous.values.map((voice) => voice.player));
      _transitionPlayers.removeAll(next.values.map((voice) => voice.player));
    }
  }

  Future<void> _fadeCurrentGains(
    Map<String, double> gains,
    Duration transition,
  ) async {
    final generation = ++_musicGeneration;
    final startVolumes = {
      for (final entry in _musicVoices.entries)
        entry.key: entry.value.player.volume,
    };
    _musicVoices = {
      for (final entry in _musicVoices.entries)
        entry.key: entry.value.withGain(gains[entry.key]!.clamp(0, 1)),
    };
    final steps = transition == Duration.zero ? 1 : 12;
    final delay = Duration(microseconds: transition.inMicroseconds ~/ steps);
    for (var step = 1; step <= steps; step++) {
      if (_disposed || generation != _musicGeneration) return;
      final ratio = step / steps;
      await Future.wait(_musicVoices.entries.map((entry) {
        final start = startVolumes[entry.key]!;
        final target = _musicVolume * entry.value.gain;
        return entry.value.player.setVolume(start + (target - start) * ratio);
      }));
      if (delay > Duration.zero) await Future<void>.delayed(delay);
    }
  }

  Future<void> _setVoiceVolumes(
    Map<String, _MusicVoice> voices, {
    required double ratio,
  }) {
    return Future.wait(voices.values.map(
      (voice) => voice.player.setVolume(_musicVolume * voice.gain * ratio),
    ));
  }

  @override
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0, 1);
    if (!_musicPaused) await _setVoiceVolumes(_musicVoices, ratio: 1);
  }

  @override
  Future<void> pauseMusic() async {
    _musicPaused = true;
    final players = <AudioPlayer>{
      ..._transitionPlayers,
      ..._musicVoices.values.map((voice) => voice.player),
    };
    await Future.wait(players
        .where((player) => player.state == PlayerState.playing)
        .map((player) => player.pause()));
  }

  @override
  Future<void> resumeMusic() async {
    if (_disposed || _musicVoices.isEmpty) return;
    _musicPaused = false;
    await _setVoiceVolumes(_musicVoices, ratio: 1);
    await Future.wait(_musicVoices.values
        .map((voice) => voice.player)
        .where((player) => player.state != PlayerState.playing)
        .map((player) => player.resume()));
  }

  @override
  Future<AudioPlaybackHandle> playSound(
    String cachePath, {
    required double volume,
    required Duration duration,
  }) async {
    if (_disposed) return _CompletedPlaybackHandle();
    final generation = _soundGeneration;
    final lifetime = duration + const Duration(milliseconds: 80);
    final pool = _effectPools[cachePath];
    late final AudioPlaybackHandle handle;
    if (pool != null) {
      final stop = await pool.start(volume: volume.clamp(0, 1));
      if (_disposed || generation != _soundGeneration) {
        await stop();
        return _CompletedPlaybackHandle();
      }
      handle = _CallbackPlaybackHandle(stop, lifetime);
    } else {
      final player = AudioPlayer()..audioCache = _cache;
      try {
        await player.setAudioContext(_effectsContext);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.play(
          AssetSource(cachePath),
          volume: volume.clamp(0, 1),
          mode: PlayerMode.lowLatency,
        );
      } catch (_) {
        await player.dispose();
        rethrow;
      }
      if (_disposed || generation != _soundGeneration) {
        await player.dispose();
        return _CompletedPlaybackHandle();
      }
      handle = _CallbackPlaybackHandle(player.dispose, lifetime);
    }
    _sounds.add(handle);
    unawaited(handle.completed.whenComplete(() => _sounds.remove(handle)));
    return handle;
  }

  @override
  Future<void> stopSounds() async {
    _soundGeneration++;
    final active = _sounds.toList(growable: false);
    _sounds.clear();
    await Future.wait(active.map((handle) => handle.stop()));
  }

  Future<void> _disposePlayers(Iterable<AudioPlayer> players) async {
    final unique = players.toSet();
    _transitionPlayers.removeAll(unique);
    await Future.wait(unique.map((player) async {
      if (player.state != PlayerState.disposed) await player.dispose();
    }));
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _musicGeneration++;
    Object? firstError;
    StackTrace? firstStack;
    Future<void> attempt(Future<void> Function() operation) async {
      try {
        await operation();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStack ??= stackTrace;
      }
    }

    await attempt(stopSounds);
    final players = <AudioPlayer>{
      ..._transitionPlayers,
      ..._musicVoices.values.map((voice) => voice.player),
    };
    _transitionPlayers.clear();
    _musicVoices = {};
    _musicSignature = '';
    await attempt(() => _disposePlayers(players));
    for (final pool in _effectPools.values) {
      await attempt(pool.dispose);
    }
    _effectPools.clear();
    await attempt(_cache.clearAll);
    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStack!);
    }
  }
}

class _CallbackPlaybackHandle implements AudioPlaybackHandle {
  _CallbackPlaybackHandle(this._stopCallback, Duration lifetime) {
    _timer = Timer(lifetime, () => unawaited(stop()));
  }

  final Future<void> Function() _stopCallback;
  final Completer<void> _done = Completer<void>();
  Timer? _timer;
  bool _stopped = false;

  @override
  Future<void> get completed => _done.future;

  @override
  Future<void> stop() async {
    if (_stopped) return completed;
    _stopped = true;
    _timer?.cancel();
    try {
      await _stopCallback();
    } finally {
      if (!_done.isCompleted) _done.complete();
    }
  }
}

class _CompletedPlaybackHandle implements AudioPlaybackHandle {
  @override
  Future<void> get completed => Future<void>.value();

  @override
  Future<void> stop() => Future<void>.value();
}
