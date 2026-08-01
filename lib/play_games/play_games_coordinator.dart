import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/game_controller.dart';
import 'play_games_models.dart';
import 'play_games_service.dart';
import 'play_games_store.dart';
import 'play_games_week.dart';

typedef PlayGamesClock = DateTime Function();

class PlayGamesCoordinator extends ChangeNotifier {
  PlayGamesCoordinator({
    required GameController controller,
    required PlayGamesService service,
    required PlayGamesStore store,
    PlayGamesClock clock = DateTime.now,
  })  : _controller = controller,
        _service = service,
        _store = store,
        _clock = clock;

  static const checkpointInterval = Duration(seconds: 45);

  final GameController _controller;
  final PlayGamesService _service;
  final PlayGamesStore _store;
  final PlayGamesClock _clock;

  Map<String, dynamic> _state = <String, dynamic>{};
  Future<void> _queue = Future.value();
  Timer? _checkpointTimer;
  bool _initialized = false;
  bool _disposed = false;
  bool _loading = false;
  PlayGamesAvailability _availability =
      PlayGamesAvailability.temporarilyUnavailable;
  PlayGamesPlayer? _currentPlayer;
  LeaderboardPage? _leaderboardPage;

  PlayGamesAvailability get availability => _availability;
  PlayGamesPlayer? get currentPlayer => _currentPlayer;
  LeaderboardPage? get leaderboardPage => _leaderboardPage;
  bool get loading => _loading;
  bool get authenticated =>
      _availability == PlayGamesAvailability.available &&
      _currentPlayer != null;
  FriendsConsentState get friendsConsentState =>
      FriendsConsentState.values
          .where((value) => value.name == _state['friendsConsent'])
          .firstOrNull ??
      FriendsConsentState.unknown;
  DateTime? get lastSuccessfulSync => DateTime.tryParse(
        '${_state['lastSuccessfulSync'] ?? ''}',
      );
  BigInt get weeklyAura =>
      BigInt.tryParse('${_state['weeklyAura'] ?? 0}') ?? BigInt.zero;
  BigInt get maxAuraPerSecond =>
      BigInt.tryParse('${_state['maxAuraPerSecond'] ?? 0}') ?? BigInt.zero;
  BigInt get maxAuraPerMovement =>
      BigInt.tryParse('${_state['maxAuraPerMovement'] ?? 0}') ?? BigInt.zero;

  AuraProgressSnapshot get _snapshot => AuraProgressSnapshot(
        totalAura: _controller.total,
        auraPerSecond: _controller.passiveNumerator ~/ BigInt.from(2000),
        maxAuraPerMovement: _controller.maxAuraPerMovement,
        manualActions: _controller.cycles,
        itemsUnlocked: _controller.unlockedItemCount,
        prestiges: _controller.ascensions,
        restorationRevision: _controller.restorationRevision,
      );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _state = await _store.read();
    _normalizeState(_snapshot, _clock());
    await _persist();
    _controller.addListener(_onGameChanged);
    final result = await _service.initialize();
    _availability = result.availability;
    if (await _service.isAuthenticated()) {
      _currentPlayer = await _service.loadCurrentPlayer();
      _availability = PlayGamesAvailability.available;
      await flush(force: true);
    } else if (_availability == PlayGamesAvailability.available) {
      _availability = PlayGamesAvailability.unauthenticated;
    }
    _checkpointTimer = Timer.periodic(
      checkpointInterval,
      (_) => unawaited(flush()),
    );
    _notify();
  }

  Future<void> signIn() async {
    _setLoading(true);
    final result = await _service.signIn();
    if (result.succeeded && await _service.isAuthenticated()) {
      _currentPlayer = await _service.loadCurrentPlayer();
      _availability = PlayGamesAvailability.available;
      await flush(force: true);
    } else {
      _availability = result.availability;
    }
    _setLoading(false);
  }

  void _onGameChanged() {
    _queue = _queue.then((_) => _capture(_snapshot, _clock()));
  }

  Future<void> captureForTesting(
    AuraProgressSnapshot snapshot,
    DateTime now,
  ) =>
      _capture(snapshot, now);

  Future<void> _capture(
    AuraProgressSnapshot snapshot,
    DateTime now,
  ) async {
    _rollWeek(now);
    final previousRestoration = _int('restorationRevision');
    final restored = snapshot.restorationRevision != previousRestoration;
    final previousTotal = _big('lastObservedTotal');
    final previousManual = _int('lastObservedManualActions');
    final previousItems = _int('lastObservedItemsUnlocked');
    final previousPrestiges = _int('lastObservedPrestiges');

    if (!restored && snapshot.totalAura > previousTotal) {
      final auraDelta = snapshot.totalAura - previousTotal;
      _state['weeklyAura'] = (weeklyAura + auraDelta).toString();
      _mergeStats(GameStatsDelta(auraEarnedDelta: auraDelta));
    }
    if (!restored && snapshot.manualActions > previousManual) {
      _mergeStats(GameStatsDelta(
        manualActionsDelta: snapshot.manualActions - previousManual,
      ));
    }
    if (!restored && snapshot.itemsUnlocked > previousItems) {
      _mergeStats(GameStatsDelta(
        itemsUnlockedDelta: snapshot.itemsUnlocked - previousItems,
      ));
    }
    if (!restored && snapshot.prestiges > previousPrestiges) {
      _mergeStats(GameStatsDelta(
        prestigesDelta: snapshot.prestiges - previousPrestiges,
      ));
    }

    if (snapshot.auraPerSecond > maxAuraPerSecond) {
      _state['maxAuraPerSecond'] = snapshot.auraPerSecond.toString();
      _mergeStats(GameStatsDelta(
        maxAuraPerSecond: snapshot.auraPerSecond,
      ));
    }
    if (snapshot.maxAuraPerMovement > maxAuraPerMovement) {
      _state['maxAuraPerMovement'] = snapshot.maxAuraPerMovement.toString();
    }

    final progressLevel = auraProgressLevel(snapshot.totalAura);
    if (progressLevel != _int('lastProgressLevel') || restored) {
      _state['pendingProgress'] = AuraProgress(
        currentProgress: progressLevel,
        auraTier: auraTierForLevel(progressLevel),
      ).toMap();
      _state['lastProgressLevel'] = progressLevel;
    }

    _state
      ..['lastObservedTotal'] = snapshot.totalAura.toString()
      ..['lastObservedManualActions'] = snapshot.manualActions
      ..['lastObservedItemsUnlocked'] = snapshot.itemsUnlocked
      ..['lastObservedPrestiges'] = snapshot.prestiges
      ..['restorationRevision'] = snapshot.restorationRevision;
    _queueScores();
    await _persist();
    _notify();
  }

  Future<void> flush({bool force = false}) async {
    if (!_initialized) return;
    await _queue;
    final now = _clock();
    _rollWeek(now);
    final lastCheckpoint = DateTime.tryParse(
      '${_state['lastCheckpoint'] ?? ''}',
    );
    if (!force &&
        lastCheckpoint != null &&
        now.difference(lastCheckpoint) < checkpointInterval) {
      return;
    }
    _state['lastCheckpoint'] = now.toUtc().toIso8601String();
    _queueScores();
    await _persist();
    if (!await _service.isAuthenticated()) {
      if (_availability == PlayGamesAvailability.available) {
        _availability = PlayGamesAvailability.unauthenticated;
      }
      _notify();
      return;
    }

    var sentAnything = false;
    final pendingScores =
        Map<String, dynamic>.from(_state['pendingScores'] as Map? ?? const {});
    for (final entry in pendingScores.entries.toList()) {
      final leaderboard = AuraLeaderboard.values
          .where((value) => value.name == entry.key)
          .firstOrNull;
      final value = BigInt.tryParse('${entry.value}');
      if (leaderboard == null || value == null || value.isNegative) {
        pendingScores.remove(entry.key);
        continue;
      }
      final result = await _service.submitLeaderboardScore(leaderboard, value);
      if (result.succeeded) {
        pendingScores.remove(entry.key);
        _state[_lastSentKey(leaderboard)] = value.toString();
        sentAnything = true;
      } else if (result.availability != PlayGamesAvailability.notConfigured) {
        _availability = result.availability;
      }
    }
    _state['pendingScores'] = pendingScores;

    final delta = GameStatsDelta.fromJson(
      Map<String, dynamic>.from(
        _state['pendingStatsDelta'] as Map? ?? const {},
      ),
    );
    if (!delta.isEmpty) {
      final eventId =
          '${_state['pendingStatsEventId'] ?? _eventId('activity', now)}';
      _state['pendingStatsEventId'] = eventId;
      await _persist();
      final result = await _service.recordGameStatsDelta(
        eventId,
        delta,
      );
      if (result.succeeded) {
        _state['pendingStatsDelta'] = GameStatsDelta().toJson();
        _state.remove('pendingStatsEventId');
        sentAnything = true;
      }
    }

    final progressMap = _state['pendingProgress'];
    if (progressMap is Map) {
      final eventId =
          '${_state['pendingProgressEventId'] ?? _eventId('progress', now)}';
      _state['pendingProgressEventId'] = eventId;
      await _persist();
      final progress = AuraProgress(
        currentProgress: _mapInt(progressMap, 'currentProgress'),
        auraTier: '${progressMap['auraTier'] ?? 'initial'}',
      );
      final result = await _service.recordProgressUpdate(
        eventId,
        progress,
      );
      if (result.succeeded) {
        _state.remove('pendingProgress');
        _state.remove('pendingProgressEventId');
        sentAnything = true;
      }
    }
    if (sentAnything) {
      await _service.requestEventsUpload();
      _state['lastSuccessfulSync'] = now.toUtc().toIso8601String();
      _availability = PlayGamesAvailability.available;
    }
    await _persist();
    _notify();
  }

  Future<void> onPaused() => flush(force: true);

  Future<void> onResumed() async {
    final result = await _service.initialize();
    if (result.succeeded && await _service.isAuthenticated()) {
      _currentPlayer = await _service.loadCurrentPlayer();
      _availability = PlayGamesAvailability.available;
      await flush(force: true);
    } else {
      _availability = result.availability;
      _notify();
    }
  }

  Future<LeaderboardPage> loadLeaderboard({
    required AuraLeaderboard leaderboard,
    required LeaderboardTimeScope timeScope,
    required LeaderboardPlayerScope playerScope,
    bool forceReload = false,
  }) async {
    _setLoading(true);
    var page = await _service.loadLeaderboard(
      leaderboard: leaderboard,
      timeScope: timeScope,
      playerScope: playerScope,
      forceReload: forceReload,
    );
    if (playerScope == LeaderboardPlayerScope.friends &&
        page.availability == PlayGamesAvailability.available) {
      final friends = await _service.loadFriends(forceReload: forceReload);
      if (friends.availability == PlayGamesAvailability.available) {
        _state['friendsConsent'] = FriendsConsentState.granted.name;
        page = LeaderboardPage(
          entries: mergeFriendsAndScores(
            friends: friends.friends,
            scores: page.entries,
            currentPlayerId: _currentPlayer?.playerId,
          ),
          currentPlayer: page.currentPlayer,
        );
      } else {
        page = LeaderboardPage.unavailable(
          friends.availability,
          message: friends.message,
        );
        if (friends.availability == PlayGamesAvailability.consentRequired) {
          _state['friendsConsent'] = FriendsConsentState.required.name;
        }
      }
      await _persist();
    }
    _leaderboardPage = page;
    _setLoading(false);
    return page;
  }

  Future<bool> requestFriendsConsent() async {
    if (friendsConsentState == FriendsConsentState.denied ||
        friendsConsentState == FriendsConsentState.unknown) {
      final probe = await _service.loadFriends(forceReload: true);
      if (probe.availability == PlayGamesAvailability.available) {
        _state['friendsConsent'] = FriendsConsentState.granted.name;
        await _persist();
        _notify();
        return true;
      }
      if (probe.availability != PlayGamesAvailability.consentRequired) {
        _state['friendsConsent'] = FriendsConsentState.denied.name;
        await _persist();
        _notify();
        return false;
      }
      _state['friendsConsent'] = FriendsConsentState.required.name;
    }
    final result = await _service.requestFriendsConsent();
    final granted = result.succeeded;
    _state['friendsConsent'] =
        (granted ? FriendsConsentState.granted : FriendsConsentState.denied)
            .name;
    await _persist();
    _notify();
    return granted;
  }

  Future<PlayGamesOperationResult> showCompareProfile(
    LeaderboardEntry entry,
  ) =>
      _service.showCompareProfile(
        playerId: entry.playerId,
        otherPlayerInGameName: entry.displayName,
        currentPlayerInGameName: _currentPlayer?.displayName,
      );

  Future<PlayGamesOperationResult> showNativeLeaderboard(
    AuraLeaderboard leaderboard,
  ) =>
      _service.showNativeLeaderboard(leaderboard);

  void _normalizeState(AuraProgressSnapshot snapshot, DateTime now) {
    _rollWeek(now);
    _state
      ..putIfAbsent('weeklyAura', () => '0')
      ..putIfAbsent('lastWeeklySubmitted', () => '0')
      ..putIfAbsent('maxAuraPerSecond', () => snapshot.auraPerSecond.toString())
      ..putIfAbsent('lastMaxAuraPerSecondSubmitted', () => '0')
      ..putIfAbsent(
        'maxAuraPerMovement',
        () => snapshot.maxAuraPerMovement.toString(),
      )
      ..putIfAbsent('lastMaxAuraPerMovementSubmitted', () => '0')
      ..putIfAbsent('lastObservedTotal', () => snapshot.totalAura.toString())
      ..putIfAbsent(
        'lastObservedManualActions',
        () => snapshot.manualActions,
      )
      ..putIfAbsent('lastObservedItemsUnlocked', () => snapshot.itemsUnlocked)
      ..putIfAbsent('lastObservedPrestiges', () => snapshot.prestiges)
      ..putIfAbsent('restorationRevision', () => snapshot.restorationRevision)
      ..putIfAbsent(
        'pendingStatsDelta',
        () => GameStatsDelta().toJson(),
      )
      ..putIfAbsent('pendingScores', () => <String, dynamic>{})
      ..putIfAbsent('friendsConsent', () => FriendsConsentState.unknown.name);
    final level = auraProgressLevel(snapshot.totalAura);
    _state
      ..putIfAbsent('lastProgressLevel', () => level)
      ..putIfAbsent(
        'pendingProgress',
        () => AuraProgress(
          currentProgress: level,
          auraTier: auraTierForLevel(level),
        ).toMap(),
      );
    _queueScores();
  }

  void _rollWeek(DateTime now) {
    final key = PlayGamesWeek.keyFor(now);
    if (_state['weekKey'] == key) return;
    _state
      ..['weekKey'] = key
      ..['weeklyAura'] = '0'
      ..['lastWeeklySubmitted'] = '0';
    final pending =
        Map<String, dynamic>.from(_state['pendingScores'] as Map? ?? const {});
    pending.remove(AuraLeaderboard.weeklyAura.name);
    _state['pendingScores'] = pending;
  }

  void _queueScores() {
    final pending =
        Map<String, dynamic>.from(_state['pendingScores'] as Map? ?? const {});
    void queue(
      AuraLeaderboard leaderboard,
      BigInt value,
      BigInt lastSent,
    ) {
      if (value > lastSent) pending[leaderboard.name] = value.toString();
    }

    queue(
      AuraLeaderboard.weeklyAura,
      weeklyAura,
      _big('lastWeeklySubmitted'),
    );
    queue(
      AuraLeaderboard.maxAuraPerSecond,
      maxAuraPerSecond,
      _big('lastMaxAuraPerSecondSubmitted'),
    );
    queue(
      AuraLeaderboard.maxAuraPerMovement,
      maxAuraPerMovement,
      _big('lastMaxAuraPerMovementSubmitted'),
    );
    _state['pendingScores'] = pending;
  }

  String _lastSentKey(AuraLeaderboard leaderboard) => switch (leaderboard) {
        AuraLeaderboard.weeklyAura => 'lastWeeklySubmitted',
        AuraLeaderboard.maxAuraPerSecond => 'lastMaxAuraPerSecondSubmitted',
        AuraLeaderboard.maxAuraPerMovement => 'lastMaxAuraPerMovementSubmitted',
      };

  void _mergeStats(GameStatsDelta delta) {
    final current = GameStatsDelta.fromJson(Map<String, dynamic>.from(
      _state['pendingStatsDelta'] as Map? ?? const {},
    ));
    _state['pendingStatsDelta'] = current.merge(delta).toJson();
  }

  String _eventId(String kind, DateTime now) {
    final next = _int('eventSequence') + 1;
    _state['eventSequence'] = next;
    return 'aura-$kind-${now.toUtc().microsecondsSinceEpoch}-$next';
  }

  BigInt _big(String key) =>
      BigInt.tryParse('${_state[key] ?? 0}') ?? BigInt.zero;
  int _int(String key) => (_state[key] as num?)?.toInt() ?? 0;
  int _mapInt(Map<dynamic, dynamic> map, String key) =>
      (map[key] as num?)?.toInt() ?? 0;

  Future<void> _persist() => _store.write(_state);

  void _setLoading(bool value) {
    _loading = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _controller.removeListener(_onGameChanged);
    _checkpointTimer?.cancel();
    _disposed = true;
    super.dispose();
  }
}
