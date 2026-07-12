import 'dart:math';

enum MusicContext { play, menu, shop }

enum AudioBus { cycle, ui, event }

enum CycleFamily { six, seven }

/// A random bag that emits every item once before refilling and never repeats
/// an item across a refill boundary.
class ShuffleBag<T> {
  ShuffleBag(Iterable<T> values, {Random? random})
      : _values = List<T>.unmodifiable(values),
        _random = random ?? Random() {
    if (_values.isEmpty) throw ArgumentError.value(values, 'values', 'empty');
  }

  final List<T> _values;
  final Random _random;
  final List<T> _bag = [];
  T? _last;

  T next() {
    if (_bag.isEmpty) _refill();
    final value = _bag.removeLast();
    _last = value;
    return value;
  }

  void _refill() {
    _bag
      ..addAll(_values)
      ..shuffle(_random);
    if (_bag.length > 1 && _bag.last == _last) {
      final swapIndex = _bag.indexWhere((value) => value != _last);
      final value = _bag[swapIndex];
      _bag[swapIndex] = _bag.last;
      _bag[_bag.length - 1] = value;
    }
  }
}

/// Presentation-only EMA of completed cycles/s. The constants mirror the
/// approved motion/audio contract: 1.3 s effective window, 0.15 cycles/s
/// hysteresis, 250 ms dwell, at least 900 ms from idle to I3, and 1.8 s idle
/// release. It never feeds economy.
class CadenceIntensity {
  CadenceIntensity({
    this.window = const Duration(milliseconds: 1300),
    this.hysteresis = .15,
    this.dwell = const Duration(milliseconds: 250),
    this.maximumAttack = const Duration(milliseconds: 900),
    this.idleRelease = const Duration(milliseconds: 1800),
  });

  final Duration window;
  final double hysteresis;
  final Duration dwell;
  final Duration maximumAttack;
  final Duration idleRelease;
  double _ema = 0;
  int? _lastUpdateMillis;
  int? _lastCycleMillis;
  int? _attackStartedMillis;
  int? _candidateSinceMillis;
  int? _candidateTier;
  int _tier = 0;

  double get cyclesPerSecond => _ema;
  int get tier => _tier;

  int recordCycle(int nowMillis) {
    _decayTo(nowMillis);
    _ema += 1000 / window.inMilliseconds;
    _lastCycleMillis = nowMillis;
    _attackStartedMillis ??= nowMillis;
    return at(nowMillis);
  }

  int at(int nowMillis) {
    _decayTo(nowMillis);
    final lastCycle = _lastCycleMillis;
    if (lastCycle == null ||
        nowMillis - lastCycle >= idleRelease.inMilliseconds) {
      _tier = 0;
      _candidateTier = null;
      _candidateSinceMillis = null;
      _attackStartedMillis = null;
      return _tier;
    }

    final target = _targetWithHysteresis();
    if (target == _tier) {
      _candidateTier = null;
      _candidateSinceMillis = null;
      return _tier;
    }
    final stepTarget = target > _tier ? _tier + 1 : _tier - 1;
    if (_candidateTier != stepTarget) {
      _candidateTier = stepTarget;
      _candidateSinceMillis = nowMillis;
      return _tier;
    }
    if (nowMillis - _candidateSinceMillis! < dwell.inMilliseconds) {
      return _tier;
    }

    if (stepTarget > _tier) {
      final next = _tier + 1;
      final attackAge = nowMillis - (_attackStartedMillis ?? nowMillis);
      if (next == 3 && attackAge < maximumAttack.inMilliseconds) return _tier;
      _tier = next;
    } else {
      _tier = stepTarget;
    }
    _candidateTier = null;
    _candidateSinceMillis = null;
    return _tier;
  }

  void _decayTo(int nowMillis) {
    final previous = _lastUpdateMillis;
    _lastUpdateMillis = nowMillis;
    if (previous == null || nowMillis <= previous) return;
    final elapsed = nowMillis - previous;
    _ema *= exp(-elapsed / window.inMilliseconds);
  }

  int _targetWithHysteresis() {
    return switch (_tier) {
      0 => _ema >= .5 + hysteresis ? _rawTier(_ema) : 0,
      1 => _ema < .5 - hysteresis
          ? 0
          : (_ema >= 1.5 + hysteresis ? _rawTier(_ema) : 1),
      2 => _ema < 1.5 - hysteresis
          ? _rawTier(_ema)
          : (_ema >= 2.5 + hysteresis ? 3 : 2),
      _ => _ema < 2.5 - hysteresis ? _rawTier(_ema) : 3,
    };
  }

  static int _rawTier(double cyclesPerSecond) {
    if (cyclesPerSecond >= 2.5) return 3;
    if (cyclesPerSecond >= 1.5) return 2;
    if (cyclesPerSecond >= .5) return 1;
    return 0;
  }
}

class VoiceRequest {
  const VoiceRequest({
    required this.bus,
    required this.priority,
    this.cycleFamily,
  });

  final AudioBus bus;
  final int priority;
  final CycleFamily? cycleFamily;
}

class VoiceReservation {
  const VoiceReservation({required this.token, this.evictedToken});
  final int token;
  final int? evictedToken;
}

class _ActiveVoice {
  const _ActiveVoice(this.token, this.order, this.request);
  final int token;
  final int order;
  final VoiceRequest request;
}

/// Deterministic policy for concurrency and preemption. Seven may displace an
/// older Six; high-priority events may displace lower-priority SFX.
class VoiceBudget {
  VoiceBudget({
    this.cycleLimit = 4,
    this.sixLimit = 2,
    this.sevenLimit = 3,
    this.uiLimit = 3,
    this.eventLimit = 2,
    this.globalLimit = 8,
  });

  final int cycleLimit;
  final int sixLimit;
  final int sevenLimit;
  final int uiLimit;
  final int eventLimit;
  final int globalLimit;
  final List<_ActiveVoice> _active = [];
  int _nextToken = 0;
  int _order = 0;

  int get activeCount => _active.length;
  bool contains(int token) => _active.any((voice) => voice.token == token);

  VoiceReservation? reserve(VoiceRequest request) {
    final sameBus = _active.where((voice) => voice.request.bus == request.bus);
    final busLimit = switch (request.bus) {
      AudioBus.cycle => cycleLimit,
      AudioBus.ui => uiLimit,
      AudioBus.event => eventLimit,
    };
    final familyLimit = switch (request.cycleFamily) {
      CycleFamily.six => sixLimit,
      CycleFamily.seven => sevenLimit,
      null => null,
    };
    if (familyLimit != null &&
        sameBus
                .where(
                    (voice) => voice.request.cycleFamily == request.cycleFamily)
                .length >=
            familyLimit) {
      return null;
    }

    _ActiveVoice? victim;
    if (sameBus.length >= busLimit) {
      if (request.cycleFamily == CycleFamily.seven) {
        victim = _oldestWhere((voice) =>
            voice.request.bus == AudioBus.cycle &&
            voice.request.cycleFamily == CycleFamily.six);
      }
      victim ??= _lowestPriorityVictim(sameBus, request.priority);
      if (victim == null) return null;
    }

    if (_active.length >= globalLimit && victim == null) {
      victim = _lowestPriorityVictim(_active, request.priority);
      if (victim == null) return null;
    }

    if (victim != null) _active.remove(victim);
    final voice = _ActiveVoice(++_nextToken, ++_order, request);
    _active.add(voice);
    return VoiceReservation(token: voice.token, evictedToken: victim?.token);
  }

  void release(int token) =>
      _active.removeWhere((voice) => voice.token == token);
  void clear() => _active.clear();

  _ActiveVoice? _oldestWhere(bool Function(_ActiveVoice voice) predicate) {
    final matches = _active.where(predicate).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return matches.isEmpty ? null : matches.first;
  }

  _ActiveVoice? _lowestPriorityVictim(
    Iterable<_ActiveVoice> candidates,
    int incomingPriority,
  ) {
    final lower = candidates
        .where((voice) => voice.request.priority < incomingPriority)
        .toList()
      ..sort((a, b) {
        final priority = a.request.priority.compareTo(b.request.priority);
        return priority != 0 ? priority : a.order.compareTo(b.order);
      });
    return lower.isEmpty ? null : lower.first;
  }
}
