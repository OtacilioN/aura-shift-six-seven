import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/game_controller.dart';
import '../play_games/play_games_models.dart';
import 'achievement_catalog.dart';
import 'achievement_evaluator.dart';
import 'achievement_models.dart';
import 'achievement_progress_repository.dart';
import 'play_games_achievement_ids.dart';
import 'play_games_achievements_service.dart';

typedef AchievementClock = DateTime Function();
typedef AchievementIdsConfigured = bool Function();
typedef AchievementExternalId = String Function(AuraAchievement achievement);
typedef AchievementForExternalId = AuraAchievement? Function(String id);

class AchievementSyncService extends ChangeNotifier {
  AchievementSyncService({
    required GameController controller,
    required PlayGamesAchievementsService service,
    required AchievementProgressRepository repository,
    AchievementEvaluator evaluator = const AchievementEvaluator(),
    AchievementClock clock = DateTime.now,
    AchievementIdsConfigured? idsConfigured,
    AchievementExternalId? externalId,
    AchievementForExternalId? achievementForExternalId,
    this.syncInterval = const Duration(seconds: 45),
    this.evaluationDebounce = const Duration(milliseconds: 250),
  })  : _controller = controller,
        _service = service,
        _repository = repository,
        _evaluator = evaluator,
        _clock = clock,
        _idsConfigured =
            idsConfigured ?? (() => PlayGamesAchievementIds.anyConfigured),
        _externalId = externalId ?? PlayGamesAchievementIds.idFor,
        _achievementForExternalId = achievementForExternalId ??
            PlayGamesAchievementIds.achievementForId;

  final GameController _controller;
  final PlayGamesAchievementsService _service;
  final AchievementProgressRepository _repository;
  final AchievementEvaluator _evaluator;
  final AchievementClock _clock;
  final AchievementIdsConfigured _idsConfigured;
  final AchievementExternalId _externalId;
  final AchievementForExternalId _achievementForExternalId;
  final Duration syncInterval;
  final Duration evaluationDebounce;

  AchievementQueueState _queue = AchievementQueueState();
  PlayGamesAvailability _availability =
      PlayGamesAvailability.temporarilyUnavailable;
  bool _initialized = false;
  bool _loading = false;
  bool _syncInFlight = false;
  bool _resyncRequested = false;
  bool _disposed = false;
  Timer? _evaluationTimer;
  Timer? _syncTimer;
  Future<void> _evaluationQueue = Future.value();

  PlayGamesAvailability get availability => _availability;
  bool get loading => _loading;
  bool get authenticated =>
      _availability == PlayGamesAvailability.available && _queue.authenticated;
  bool get hasPending => _queue.hasPending;
  int get pendingCount => _queue.pendingCount;
  int get confirmedCount => _queue.confirmedUnlocks.length;
  int get eligibleCount {
    final evaluation = _evaluator.evaluateAchievements(_snapshot);
    return evaluation.standardsToUnlock.length +
        evaluation.incrementalSteps.entries
            .where((entry) =>
                entry.value >=
                AchievementCatalog.definitionFor(entry.key).requiredSteps!)
            .length;
  }

  int get totalCount => AchievementCatalog.definitions.length;
  DateTime? get lastSuccessfulSync => _queue.lastSync;
  int get failedAttempts => _queue.failedAttempts;
  bool get idsConfigured => _idsConfigured();

  PlayerProgressSnapshot get _snapshot => PlayerProgressSnapshot(
        totalAura: _controller.total,
        manualMovements: _controller.manualMovements,
        auraProducingMovements: _controller.auraProducingMovements,
        sixMovements: _controller.sixMovements,
        sevenMovements: _controller.sevenMovements,
        purchaseCount: _controller.purchaseCount,
        automaticProductionSources: _controller.appearances.length,
        auraPerSecond: _controller.passiveNumerator ~/ BigInt.from(2000),
        maximumAuraPerMovement: _controller.maxAuraPerMovement,
        offlineRewardsCollected: _controller.offlineRewardsCollected,
        unlockedItemIds: _controller.appearances.toSet(),
        unlockedCharacterIds: _controller.transformations,
        unlockedTechniqueIds: _controller.unlockedTechniqueIds,
        distinctPlayDays: _controller.distinctPlayDays,
        maximumAuraStateId: _controller.maximumAuraStateId,
        saveMigrated: true,
      );

  Future<AchievementsInitializationResult> initialize() async {
    if (_initialized) {
      return AchievementsInitializationResult(_availability);
    }
    _initialized = true;
    _queue = await _repository.read();
    await _captureProgress(prioritySync: false);
    _controller.addListener(_onGameChanged);
    if (!_idsConfigured()) {
      _availability = PlayGamesAvailability.notConfigured;
      _startTimer();
      _notify();
      return const AchievementsInitializationResult(
        PlayGamesAvailability.notConfigured,
      );
    }
    final result = await _service.initialize();
    _availability = result.availability;
    if (result.succeeded && await _service.isAuthenticated()) {
      await _bindAuthenticatedPlayer();
      await synchronize(forceRemoteReload: true);
    } else {
      _queue.authenticated = false;
      await _persist();
    }
    _startTimer();
    _notify();
    return result;
  }

  Future<AchievementsInitializationResult> signIn() async {
    _setLoading(true);
    final result = await _service.signIn();
    _availability = result.availability;
    if (result.succeeded && await _service.isAuthenticated()) {
      await _bindAuthenticatedPlayer();
      await synchronize(forceRemoteReload: true);
    } else {
      _queue.authenticated = false;
      await _persist();
    }
    _setLoading(false);
    return result;
  }

  void _onGameChanged() {
    _evaluationTimer?.cancel();
    _evaluationTimer = Timer(evaluationDebounce, () {
      _evaluationQueue =
          _evaluationQueue.then((_) => _captureProgress(prioritySync: true));
    });
  }

  Future<void> captureForTesting({
    bool prioritySync = false,
  }) =>
      _captureProgress(prioritySync: prioritySync);

  Future<void> _captureProgress({required bool prioritySync}) async {
    final evaluation = _evaluator.evaluateAchievements(_snapshot);
    var addedStandard = false;
    for (final definition in AchievementCatalog.definitions) {
      final key = definition.key;
      if (definition.type == AchievementType.standard &&
          evaluation.standardsToUnlock.contains(key) &&
          !_queue.confirmedUnlocks.contains(key)) {
        addedStandard = _queue.pendingUnlocks.add(key) || addedStandard;
      }
      final steps = evaluation.incrementalSteps[key];
      if (steps != null &&
          steps > (_queue.pendingSteps[key] ?? 0) &&
          steps > (_queue.confirmedSteps[key] ?? 0)) {
        _queue.pendingSteps[key] = steps;
      }
    }
    await _persist();
    _notify();
    if (prioritySync && addedStandard && _queue.authenticated) {
      unawaited(synchronize());
    }
  }

  Future<AchievementSyncResult> synchronize({
    bool forceRemoteReload = false,
  }) async {
    if (!_initialized) {
      return const AchievementSyncResult(
        availability: PlayGamesAvailability.temporarilyUnavailable,
      );
    }
    if (_syncInFlight) {
      _resyncRequested = true;
      return AchievementSyncResult(
        availability: _availability,
        pending: _queue.pendingCount,
      );
    }
    if (!_idsConfigured()) {
      _availability = PlayGamesAvailability.notConfigured;
      _notify();
      return AchievementSyncResult(
        availability: _availability,
        pending: _queue.pendingCount,
      );
    }

    _syncInFlight = true;
    _resyncRequested = false;
    _setLoading(true);
    var sent = 0;
    try {
      await _evaluationQueue;
      await _captureProgress(prioritySync: false);
      final initialization = await _service.initialize();
      if (!initialization.succeeded) {
        return _failed(initialization.availability);
      }
      if (!await _service.isAuthenticated()) {
        return _failed(PlayGamesAvailability.unauthenticated);
      }
      await _bindAuthenticatedPlayer();

      if (forceRemoteReload ||
          _queue.reconciliationVersion < achievementCatalogVersion) {
        final remote = await _service.load(forceReload: forceRemoteReload);
        _mergeRemote(remote);
        _queue.reconciliationVersion = achievementCatalogVersion;
        await _persist();
      }

      for (final definition in AchievementCatalog.definitions) {
        final key = definition.key;
        if (_externalId(key).isEmpty) continue;
        if (_queue.pendingReveals.contains(key) &&
            !_queue.confirmedUnlocks.contains(key)) {
          final result = await _service.reveal(key);
          if (!result.succeeded) {
            return _failed(result.availability, sent: sent);
          }
          _queue.pendingReveals.remove(key);
          sent++;
          await _persist();
        }
        if (_queue.pendingUnlocks.contains(key) &&
            !_queue.confirmedUnlocks.contains(key)) {
          final result = await _service.unlock(key);
          if (!result.succeeded) {
            return _failed(result.availability, sent: sent);
          }
          _queue.pendingUnlocks.remove(key);
          _queue.pendingReveals.remove(key);
          _queue.confirmedUnlocks.add(key);
          sent++;
          await _persist();
        }
        final desiredSteps = _queue.pendingSteps[key] ?? 0;
        final confirmedSteps = _queue.confirmedSteps[key] ?? 0;
        if (definition.type == AchievementType.incremental &&
            desiredSteps > confirmedSteps) {
          final result = await _service.setSteps(
            achievement: key,
            steps: desiredSteps,
          );
          if (!result.succeeded) {
            return _failed(result.availability, sent: sent);
          }
          _queue.confirmedSteps[key] = desiredSteps;
          if (desiredSteps >= definition.requiredSteps!) {
            _queue.confirmedUnlocks.add(key);
          }
          sent++;
          await _persist();
        }
      }
      _queue
        ..lastSync = _clock().toUtc()
        ..failedAttempts = 0
        ..authenticated = true;
      _availability = PlayGamesAvailability.available;
      await _persist();
      _notify();
      return AchievementSyncResult(
        availability: _availability,
        sent: sent,
        pending: _queue.pendingCount,
      );
    } on PlatformException catch (error) {
      return _failed(
        _availabilityForCode(error.code),
        sent: sent,
      );
    } catch (_) {
      return _failed(
        PlayGamesAvailability.temporarilyUnavailable,
        sent: sent,
      );
    } finally {
      _syncInFlight = false;
      _setLoading(false);
      if (_resyncRequested && !_disposed) {
        _resyncRequested = false;
        scheduleMicrotask(() => unawaited(synchronize()));
      }
    }
  }

  Future<AchievementSyncResult> retryPendingUpdates() =>
      synchronize(forceRemoteReload: true);

  Future<PlayGamesOperationResult> showNativeAchievements() async {
    if (!_idsConfigured()) {
      _availability = PlayGamesAvailability.notConfigured;
      _notify();
      return const PlayGamesOperationResult(
        PlayGamesAvailability.notConfigured,
      );
    }
    final result = await _service.showNativeAchievements();
    _availability = result.availability;
    _notify();
    return result;
  }

  Future<void> onPaused() async {
    _evaluationTimer?.cancel();
    await _captureProgress(prioritySync: false);
    await synchronize();
  }

  Future<void> onResumed() async {
    final result = await _service.initialize();
    _availability = result.availability;
    if (result.succeeded && await _service.isAuthenticated()) {
      await _bindAuthenticatedPlayer();
      await synchronize(forceRemoteReload: true);
    } else {
      _queue.authenticated = false;
      await _persist();
      _notify();
    }
  }

  Future<void> _bindAuthenticatedPlayer() async {
    final playerId = await _service.loadPlayerId();
    if (playerId == null) {
      _queue.authenticated = false;
      _availability = PlayGamesAvailability.unauthenticated;
      return;
    }
    if (_queue.ownerPlayerId == null) {
      _queue.ownerPlayerId = playerId;
    } else if (_queue.ownerPlayerId != playerId) {
      _queue.resetForOwner(playerId);
      await _captureProgress(prioritySync: false);
    }
    _queue.authenticated = true;
    await _persist();
  }

  void _mergeRemote(List<RemoteAchievementState> remote) {
    for (final state in remote) {
      final key = _achievementForExternalId(state.id);
      if (key == null) continue;
      if (state.status == RemoteAchievementStatus.unlocked) {
        _queue.confirmedUnlocks.add(key);
        _queue.pendingUnlocks.remove(key);
        _queue.pendingReveals.remove(key);
      } else if (state.status == RemoteAchievementStatus.revealed) {
        _queue.pendingReveals.remove(key);
      }
      if (state.type == AchievementType.incremental) {
        final remoteSteps = state.currentSteps.clamp(0, 10000);
        if (remoteSteps > (_queue.confirmedSteps[key] ?? 0)) {
          _queue.confirmedSteps[key] = remoteSteps;
        }
        if (remoteSteps >= (_queue.pendingSteps[key] ?? 0)) {
          _queue.pendingSteps.remove(key);
        }
      }
    }
  }

  AchievementSyncResult _failed(
    PlayGamesAvailability availability, {
    int sent = 0,
  }) {
    _availability = availability;
    _queue
      ..authenticated = availability == PlayGamesAvailability.available
      ..failedAttempts = (_queue.failedAttempts + 1).clamp(0, 1000000);
    unawaited(_persist());
    _notify();
    return AchievementSyncResult(
      availability: availability,
      sent: sent,
      pending: _queue.pendingCount,
    );
  }

  Future<void> _persist() => _repository.write(_queue);

  void _startTimer() {
    _syncTimer?.cancel();
    if (syncInterval <= Duration.zero) return;
    _syncTimer = Timer.periodic(
      syncInterval,
      (_) => unawaited(synchronize()),
    );
  }

  void _setLoading(bool value) {
    _loading = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static PlayGamesAvailability _availabilityForCode(String code) =>
      switch (code) {
        'not_configured' => PlayGamesAvailability.notConfigured,
        'unauthenticated' => PlayGamesAvailability.unauthenticated,
        'offline' => PlayGamesAvailability.offline,
        'unsupported' => PlayGamesAvailability.unsupportedPlatform,
        _ => PlayGamesAvailability.temporarilyUnavailable,
      };

  @override
  void dispose() {
    _disposed = true;
    _controller.removeListener(_onGameChanged);
    _evaluationTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
