import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/game_controller.dart';
import '../play_games/play_games_models.dart';
import '../play_games/play_games_service.dart';
import 'cloud_conflict_resolver.dart';
import 'cloud_game_save_repository.dart';
import 'cloud_save_envelope.dart';
import 'cloud_save_models.dart';
import 'local_game_save_repository.dart';

typedef CloudSaveClock = DateTime Function();

class CloudSaveCoordinator extends ChangeNotifier implements CloudSaveService {
  CloudSaveCoordinator({
    required GameController controller,
    required LocalGameSaveRepository localRepository,
    required CloudGameSaveRepository cloudRepository,
    required PlayGamesService playGamesService,
    GameSaveCodec codec = const GameSaveCodec(),
    CloudConflictResolver conflictResolver = const CloudConflictResolver(),
    CloudSaveClock clock = DateTime.now,
    this.syncInterval = const Duration(seconds: 45),
    this.operationTimeout = const Duration(seconds: 5),
  })  : _controller = controller,
        _local = localRepository,
        _cloud = cloudRepository,
        _playGames = playGamesService,
        _codec = codec,
        _conflictResolver = conflictResolver,
        _clock = clock;

  final GameController _controller;
  final LocalGameSaveRepository _local;
  final CloudGameSaveRepository _cloud;
  final PlayGamesService _playGames;
  final GameSaveCodec _codec;
  final CloudConflictResolver _conflictResolver;
  final CloudSaveClock _clock;
  final Duration syncInterval;
  final Duration operationTimeout;
  final StreamController<CloudSaveState> _states =
      StreamController<CloudSaveState>.broadcast();

  CloudSaveState _state = const CloudSaveLocalOnly();
  PlayGamesPlayer? _player;
  Timer? _syncTimer;
  bool _initialized = false;
  bool _listenerAttached = false;
  bool _disposed = false;
  bool _syncInFlight = false;
  bool _resyncRequested = false;
  bool _suppressGameChanges = false;
  bool _dirtyMarked = false;

  @override
  CloudSaveState get state => _state;

  PlayGamesPlayer? get player => _player;

  DateTime? get lastSuccessfulSync => _local.lastSuccessfulSync;

  CloudSaveConflict? get pendingConflict => _state is CloudSaveConflictPending
      ? (_state as CloudSaveConflictPending).conflict
      : null;

  @override
  Stream<CloudSaveState> watchState() => _states.stream;

  @override
  Future<CloudSaveInitializationResult> initialize() async {
    if (_initialized) {
      return CloudSaveInitializationResult(state: _state);
    }
    _initialized = true;
    var restored = false;
    try {
      if (!_cloud.supported) {
        _setState(const CloudSaveUnavailable());
      } else {
        final result = await synchronize(reason: CloudSyncReason.startup);
        restored = result.restored;
      }
    } finally {
      _attachGameListener();
      await _controller.completeDeferredStartup();
    }
    return CloudSaveInitializationResult(
      state: _state,
      restoredRemote: restored,
    );
  }

  @override
  Future<CloudSyncResult> synchronize({
    CloudSyncReason reason = CloudSyncReason.automatic,
  }) async {
    if (!_cloud.supported) {
      const unavailable = CloudSaveUnavailable();
      _setState(unavailable);
      return const CloudSyncResult(state: unavailable);
    }
    if (_state is CloudSaveConflictPending &&
        reason != CloudSyncReason.conflictResolution) {
      return CloudSyncResult(state: _state);
    }
    if (_syncInFlight) {
      _resyncRequested = true;
      return CloudSyncResult(state: _state);
    }

    _syncInFlight = true;
    _resyncRequested = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    _setState(CloudSaveSyncing(pending: _local.hasPendingChanges));
    try {
      final authentication =
          await _playGames.initialize().timeout(operationTimeout);
      if (!authentication.succeeded &&
          authentication.availability != PlayGamesAvailability.available) {
        return _authenticationFailure(authentication.availability);
      }
      if (!await _playGames.isAuthenticated().timeout(operationTimeout)) {
        const unauthenticated = CloudSaveUnauthenticated();
        _setState(unauthenticated);
        return const CloudSyncResult(state: unauthenticated);
      }
      _player = await _playGames.loadCurrentPlayer().timeout(operationTimeout);
      final player = _player;
      if (player == null || player.playerId.isEmpty) {
        const failure = CloudSaveFailure(
          type: CloudSaveErrorType.unauthenticated,
          retryable: true,
        );
        _setState(failure);
        return const CloudSyncResult(state: failure);
      }

      await _local.flush();
      final localEnvelope = await _local.captureCurrent(nowUtc: _now());
      final remoteResult = await _cloud.open().timeout(operationTimeout);
      return await _reconcile(
        player: player,
        local: localEnvelope,
        remoteResult: remoteResult,
      );
    } on TimeoutException {
      const pending = CloudSavePending(type: CloudSaveErrorType.timeout);
      _setState(pending);
      return const CloudSyncResult(state: pending);
    } on CloudRepositoryException catch (error) {
      return _repositoryFailure(error);
    } on CloudSaveValidationException catch (error) {
      final type = error.failure == CloudSaveValidationFailure.unsupportedSchema
          ? CloudSaveErrorType.unsupportedSchema
          : error.failure == CloudSaveValidationFailure.sizeLimit
              ? CloudSaveErrorType.sizeLimit
              : CloudSaveErrorType.corruptSave;
      final failure = CloudSaveFailure(
        type: type,
        retryable: type != CloudSaveErrorType.unsupportedSchema &&
            type != CloudSaveErrorType.sizeLimit,
      );
      _setState(failure);
      return CloudSyncResult(state: failure);
    } catch (error) {
      debugPrint(
        '[cloud_save] event=sync_failure type=unknown '
        'reason=${reason.name} error=${error.runtimeType}',
      );
      const pending = CloudSavePending(type: CloudSaveErrorType.unknown);
      _setState(pending);
      return const CloudSyncResult(state: pending);
    } finally {
      _syncInFlight = false;
      if (_resyncRequested &&
          _state is! CloudSaveConflictPending &&
          !_disposed) {
        _scheduleSync();
      }
    }
  }

  Future<CloudSyncResult> _reconcile({
    required PlayGamesPlayer player,
    required CloudSaveEnvelope local,
    required CloudRemoteResult remoteResult,
  }) async {
    final previousOwner = _local.ownerPlayerId;
    final accountChanged =
        previousOwner != null && previousOwner != player.playerId;

    if (remoteResult is CloudRemoteMissing) {
      if (accountChanged && _local.hasSignificantProgress) {
        final candidate = _candidate(
          local,
          CloudSaveCandidateOrigin.thisDevice,
          id: 'local',
        );
        final conflict = CloudSaveConflict(
          first: candidate,
          recommendedCandidateId: candidate.id,
          accountSwitch: true,
          playerId: player.playerId,
          playerName: player.displayName,
        );
        final pending = CloudSaveConflictPending(conflict);
        _setState(pending);
        return CloudSyncResult(state: pending);
      }
      await _local.bindOwner(player.playerId);
      return _commit(
        _prepareForCommit(local),
        player: player,
      );
    }

    if (remoteResult is CloudRemoteConflict) {
      return _reconcileNativeConflict(
        player: player,
        local: local,
        remote: remoteResult,
        accountChanged: accountChanged,
      );
    }

    final remoteData = remoteResult as CloudRemoteData;
    final remote = _codec.decode(remoteData.snapshot.payload);
    if (accountChanged) {
      final applied = await _applyRemote(remote, player.playerId);
      if (!applied) {
        const failure = CloudSaveFailure(
          type: CloudSaveErrorType.corruptSave,
          retryable: true,
        );
        _setState(failure);
        return const CloudSyncResult(state: failure);
      }
      return _synced(player, restored: true);
    }

    await _local.bindOwner(player.playerId);
    return _reconcileTwo(
      player: player,
      local: local,
      remote: remote,
      remoteMetadata: remoteData.snapshot.metadata,
    );
  }

  Future<CloudSyncResult> _reconcileTwo({
    required PlayGamesPlayer player,
    required CloudSaveEnvelope local,
    required CloudSaveEnvelope remote,
    CloudRemoteMetadata? remoteMetadata,
  }) async {
    final resolution = _conflictResolver.resolve(local, remote);
    switch (resolution.decision) {
      case CloudConflictDecision.equivalent:
        final selected = resolution.selected!;
        await _local.writeEnvelope(selected, pending: false);
        await _local.markMigrationComplete();
        return _synced(player);
      case CloudConflictDecision.first:
        return _commit(
          _prepareForCommit(local, remote: remote),
          player: player,
        );
      case CloudConflictDecision.second:
        final applied = await _applyRemote(remote, player.playerId);
        if (!applied) {
          const failure = CloudSaveFailure(
            type: CloudSaveErrorType.corruptSave,
            retryable: true,
          );
          _setState(failure);
          return const CloudSyncResult(state: failure);
        }
        return _synced(player, restored: true);
      case CloudConflictDecision.ambiguous:
        final first = _candidate(
          local,
          CloudSaveCandidateOrigin.thisDevice,
          id: 'local',
        );
        final second = _candidate(
          remote,
          CloudSaveCandidateOrigin.cloud,
          id: 'remote',
          metadata: remoteMetadata,
        );
        final conflict = CloudSaveConflict(
          first: first,
          second: second,
          recommendedCandidateId: local.savedAtUtc.isAfter(remote.savedAtUtc)
              ? first.id
              : second.id,
          playerId: player.playerId,
          playerName: player.displayName,
        );
        final pending = CloudSaveConflictPending(conflict);
        _setState(pending);
        return CloudSyncResult(state: pending);
    }
  }

  Future<CloudSyncResult> _reconcileNativeConflict({
    required PlayGamesPlayer player,
    required CloudSaveEnvelope local,
    required CloudRemoteConflict remote,
    required bool accountChanged,
  }) async {
    CloudSaveEnvelope? server;
    CloudSaveEnvelope? conflicting;
    try {
      server = _codec.decode(remote.server.payload);
    } on CloudSaveValidationException {
      server = null;
    }
    try {
      conflicting = _codec.decode(remote.conflicting.payload);
    } on CloudSaveValidationException {
      conflicting = null;
    }

    if (server == null && conflicting == null) {
      await _cloud.abandonConflict(remote.token);
      const failure = CloudSaveFailure(
        type: CloudSaveErrorType.corruptSave,
        retryable: true,
      );
      _setState(failure);
      return const CloudSyncResult(state: failure);
    }
    if (server == null || conflicting == null) {
      final valid = server ?? conflicting!;
      return _reconcileLocalWithNativeWinner(
        player: player,
        token: remote.token,
        local: local,
        winner: valid,
        nativeCandidates: [
          if (server != null) server,
          if (conflicting != null) conflicting,
        ],
        accountChanged: accountChanged,
      );
    }

    final remoteResolution = _conflictResolver.resolve(server, conflicting);
    if (remoteResolution.decision != CloudConflictDecision.ambiguous) {
      return _reconcileLocalWithNativeWinner(
        player: player,
        token: remote.token,
        local: local,
        winner: remoteResolution.selected!,
        nativeCandidates: [server, conflicting],
        accountChanged: accountChanged,
      );
    }

    if (!accountChanged &&
        _selectsFirst(_conflictResolver.resolve(local, server)) &&
        _selectsFirst(_conflictResolver.resolve(local, conflicting))) {
      return _resolveNative(
        player: player,
        token: remote.token,
        selected: local,
        allCandidates: [local, server, conflicting],
      );
    }

    final candidates = <CloudSaveCandidate>[];
    void addCandidate(CloudSaveCandidate candidate) {
      if (candidates.any(
        (existing) =>
            existing.envelope.payloadHash == candidate.envelope.payloadHash,
      )) {
        return;
      }
      candidates.add(candidate);
    }

    if (!accountChanged) {
      addCandidate(_candidate(
        local,
        CloudSaveCandidateOrigin.thisDevice,
        id: 'local',
      ));
    }
    addCandidate(_candidate(
      server,
      local.payloadHash == server.payloadHash && !accountChanged
          ? CloudSaveCandidateOrigin.thisDevice
          : CloudSaveCandidateOrigin.cloud,
      id: 'server',
      metadata: remote.server.metadata,
    ));
    addCandidate(_candidate(
      conflicting,
      local.payloadHash == conflicting.payloadHash && !accountChanged
          ? CloudSaveCandidateOrigin.thisDevice
          : CloudSaveCandidateOrigin.otherDevice,
      id: 'conflicting',
      metadata: remote.conflicting.metadata,
    ));
    final recommended = candidates.reduce(
      (current, next) =>
          next.summary.savedAtUtc.isAfter(current.summary.savedAtUtc)
              ? next
              : current,
    );
    final conflict = CloudSaveConflict(
      first: candidates.first,
      second: candidates.length > 1 ? candidates[1] : null,
      additional: candidates.length > 2 ? candidates.sublist(2) : const [],
      recommendedCandidateId: recommended.id,
      nativeConflictToken: remote.token,
      playerId: player.playerId,
      playerName: player.displayName,
    );
    final pending = CloudSaveConflictPending(conflict);
    _setState(pending);
    return CloudSyncResult(state: pending);
  }

  Future<CloudSyncResult> _reconcileLocalWithNativeWinner({
    required PlayGamesPlayer player,
    required String token,
    required CloudSaveEnvelope local,
    required CloudSaveEnvelope winner,
    required List<CloudSaveEnvelope> nativeCandidates,
    required bool accountChanged,
  }) {
    if (accountChanged) {
      return _resolveNative(
        player: player,
        token: token,
        selected: winner,
        allCandidates: nativeCandidates,
      );
    }
    final resolution = _conflictResolver.resolve(local, winner);
    if (resolution.decision != CloudConflictDecision.ambiguous) {
      return _resolveNative(
        player: player,
        token: token,
        selected: resolution.selected!,
        allCandidates: [local, ...nativeCandidates],
      );
    }
    final first = _candidate(
      local,
      CloudSaveCandidateOrigin.thisDevice,
      id: 'local',
    );
    final second = _candidate(
      winner,
      CloudSaveCandidateOrigin.cloud,
      id: 'remote',
    );
    final conflict = CloudSaveConflict(
      first: first,
      second: second,
      recommendedCandidateId:
          local.savedAtUtc.isAfter(winner.savedAtUtc) ? first.id : second.id,
      nativeConflictToken: token,
      playerId: player.playerId,
      playerName: player.displayName,
    );
    final pending = CloudSaveConflictPending(conflict);
    _setState(pending);
    return Future.value(CloudSyncResult(state: pending));
  }

  bool _selectsFirst(CloudConflictResolution resolution) =>
      resolution.decision == CloudConflictDecision.first ||
      (resolution.decision == CloudConflictDecision.equivalent &&
          resolution.selected != null);

  Future<CloudSyncResult> resolveConflict(String candidateId) async {
    final pending = pendingConflict;
    if (pending == null) return CloudSyncResult(state: _state);
    CloudSaveCandidate? candidate;
    for (final value in pending.candidates) {
      if (value.id == candidateId) {
        candidate = value;
        break;
      }
    }
    if (candidate == null) return CloudSyncResult(state: _state);

    final player = _player;
    if (player == null) {
      const unauthenticated = CloudSaveUnauthenticated();
      _setState(unauthenticated);
      return const CloudSyncResult(state: unauthenticated);
    }

    _setState(const CloudSaveSyncing());
    try {
      if (pending.accountSwitch) {
        await _local.bindOwner(player.playerId);
        final prepared = _prepareForCommit(candidate.envelope);
        return _commit(prepared, player: player);
      }
      final candidates =
          pending.candidates.map((value) => value.envelope).toList();
      if (pending.nativeConflictToken != null) {
        return _resolveNative(
          player: player,
          token: pending.nativeConflictToken!,
          selected: candidate.envelope,
          allCandidates: candidates,
        );
      }
      final selected = _prepareResolvedCandidate(
        candidate.envelope,
        candidates,
      );
      final applied = await _applyRemote(selected, player.playerId);
      if (!applied) {
        const failure = CloudSaveFailure(
          type: CloudSaveErrorType.corruptSave,
          retryable: true,
        );
        _setState(failure);
        return const CloudSyncResult(state: failure);
      }
      return _commit(selected, player: player);
    } on TimeoutException {
      const pendingState = CloudSavePending(type: CloudSaveErrorType.timeout);
      _setState(pendingState);
      return const CloudSyncResult(state: pendingState);
    } on CloudRepositoryException catch (error) {
      return _repositoryFailure(error);
    }
  }

  Future<void> postponeConflict() async {
    // Keep the native conflict handle and both immutable candidates alive.
    // Uploads remain blocked until the player explicitly returns and chooses.
  }

  Future<CloudSyncResult> connect() async {
    final result = await _playGames.signIn().timeout(operationTimeout);
    if (!result.succeeded) {
      return _authenticationFailure(result.availability);
    }
    return synchronize(reason: CloudSyncReason.manual);
  }

  Future<CloudSyncResult> _commit(
    CloudSaveEnvelope envelope, {
    required PlayGamesPlayer player,
  }) async {
    final bytes = _codec.encode(envelope);
    if (bytes.length > await _cloud.maximumPayloadBytes()) {
      const failure = CloudSaveFailure(
        type: CloudSaveErrorType.sizeLimit,
        retryable: false,
      );
      _setState(failure);
      return const CloudSyncResult(state: failure);
    }
    final result = await _cloud
        .commit(
          payload: bytes,
          description: _description(envelope),
          playedTime: envelope.totalPlayTime,
          progressValue: CloudProgressVector.fromEnvelope(envelope).auraLevel,
        )
        .timeout(operationTimeout);
    if (result is CloudRemoteConflict) {
      return _reconcileNativeConflict(
        player: player,
        local: envelope,
        remote: result,
        accountChanged: false,
      );
    }
    if (result is! CloudRemoteData) {
      const pending = CloudSavePending(type: CloudSaveErrorType.commitFailed);
      _setState(pending);
      return const CloudSyncResult(state: pending);
    }
    await _local.writeEnvelope(envelope, pending: false);
    await _local.bindOwner(player.playerId);
    await _local.markMigrationComplete();
    return _synced(player, uploaded: true);
  }

  Future<CloudSyncResult> _resolveNative({
    required PlayGamesPlayer player,
    required String token,
    required CloudSaveEnvelope selected,
    required List<CloudSaveEnvelope> allCandidates,
  }) async {
    final resolved = _prepareResolvedCandidate(selected, allCandidates);
    final result = await _cloud
        .resolveConflict(
          token: token,
          payload: _codec.encode(resolved),
          description: _description(resolved),
          playedTime: resolved.totalPlayTime,
          progressValue: CloudProgressVector.fromEnvelope(resolved).auraLevel,
        )
        .timeout(operationTimeout);
    if (result is CloudRemoteConflict) {
      return _reconcileNativeConflict(
        player: player,
        local: resolved,
        remote: result,
        accountChanged: false,
      );
    }
    if (result is! CloudRemoteData) {
      const pending = CloudSavePending(type: CloudSaveErrorType.commitFailed);
      _setState(pending);
      return const CloudSyncResult(state: pending);
    }
    final applied = await _applyRemote(resolved, player.playerId);
    if (!applied) {
      const failure = CloudSaveFailure(
        type: CloudSaveErrorType.corruptSave,
        retryable: true,
      );
      _setState(failure);
      return const CloudSyncResult(state: failure);
    }
    await _local.markMigrationComplete();
    return _synced(player, uploaded: true, restored: true);
  }

  CloudSaveEnvelope _prepareForCommit(
    CloudSaveEnvelope local, {
    CloudSaveEnvelope? remote,
  }) {
    if (remote == null || local.revision > remote.revision) return local;
    return _codec.create(
      saveId: remote.saveId,
      revision: remote.revision + 1,
      installationId: _local.installationId,
      parentPayloadHash: remote.payloadHash,
      savedAtUtc: _now(),
      lastActiveAtUtc: local.lastActiveAtUtc,
      totalPlayTime: local.totalPlayTime,
      gameState: local.gameState,
    );
  }

  CloudSaveEnvelope _prepareResolvedCandidate(
    CloudSaveEnvelope selected,
    List<CloudSaveEnvelope> candidates,
  ) {
    final maxRevision =
        candidates.map((item) => item.revision).reduce((a, b) => a > b ? a : b);
    return _codec.create(
      saveId: selected.saveId,
      revision: maxRevision + 1,
      installationId: _local.installationId,
      parentPayloadHash: selected.payloadHash,
      savedAtUtc: _now(),
      lastActiveAtUtc: selected.lastActiveAtUtc,
      totalPlayTime: selected.totalPlayTime,
      gameState: selected.gameState,
    );
  }

  Future<bool> _applyRemote(
    CloudSaveEnvelope envelope,
    String playerId,
  ) async {
    _suppressGameChanges = true;
    try {
      final applied = await _local.applyEnvelope(envelope, pending: false);
      if (!applied) return false;
      await _local.bindOwner(playerId);
      await _local.markMigrationComplete();
      return true;
    } finally {
      _suppressGameChanges = false;
    }
  }

  CloudSaveCandidate _candidate(
    CloudSaveEnvelope envelope,
    CloudSaveCandidateOrigin origin, {
    required String id,
    CloudRemoteMetadata? metadata,
  }) {
    final state = envelope.gameState;
    final total = BigInt.tryParse('${state['total'] ?? 0}') ?? BigInt.zero;
    final multiplier =
        BigInt.tryParse('${state['multiplier'] ?? 100}') ?? BigInt.from(100);
    final levels = (state['levels'] as Map? ?? const <String, int>{});
    final passive20 = upgrades.where((upgrade) => !upgrade.isTechnique).fold(
      BigInt.zero,
      (sum, upgrade) {
        final level =
            levels[upgrade.id] is num ? (levels[upgrade.id] as num).toInt() : 0;
        return sum +
            upgrade.base20 * BigInt.from(level * _milestoneFactor(level));
      },
    );
    return CloudSaveCandidate(
      id: id,
      origin: origin,
      envelope: envelope,
      summary: CloudSaveProgressSummary(
        savedAtUtc: metadata?.lastModifiedAt ?? envelope.savedAtUtc,
        auraLevel: auraProgressLevel(total),
        totalAura: total,
        auraPerSecond: passive20 * multiplier ~/ BigInt.from(2000),
        ascensions: state['ascensions'] as int? ?? 0,
        itemsUnlocked:
            (state['appearances'] as List? ?? const <Object?>[]).length,
        totalPlayTime: envelope.totalPlayTime,
        deviceName: metadata?.deviceName,
      ),
    );
  }

  int _milestoneFactor(int level) =>
      1 <<
      ((level >= 10 ? 1 : 0) +
          (level >= 25 ? 1 : 0) +
          (level >= 50 ? 1 : 0) +
          (level ~/ 100));

  String _description(CloudSaveEnvelope envelope) {
    final vector = CloudProgressVector.fromEnvelope(envelope);
    final summary = _candidate(
      envelope,
      CloudSaveCandidateOrigin.thisDevice,
      id: 'description',
    ).summary;
    return 'Nível de Aura ${vector.auraLevel} • '
        '${summary.auraPerSecond} aura/s';
  }

  Future<CloudSyncResult> _synced(
    PlayGamesPlayer player, {
    bool uploaded = false,
    bool restored = false,
  }) async {
    final now = _now();
    var hasNewerChanges = _resyncRequested;
    if (!hasNewerChanges) _dirtyMarked = false;
    await _local.markSynced(now, pending: hasNewerChanges);
    hasNewerChanges = _resyncRequested;
    if (hasNewerChanges && !_local.hasPendingChanges) {
      await _local.setPending(true);
    }
    final synced = CloudSaveSynced(
      syncedAt: now,
      playerId: player.playerId,
      playerName: player.displayName,
      pending: hasNewerChanges,
    );
    _setState(synced);
    return CloudSyncResult(
      state: synced,
      uploaded: uploaded,
      restored: restored,
    );
  }

  CloudSyncResult _authenticationFailure(
    PlayGamesAvailability availability,
  ) {
    final state = switch (availability) {
      PlayGamesAvailability.unsupportedPlatform => const CloudSaveUnavailable(),
      PlayGamesAvailability.notConfigured => const CloudSaveUnavailable(
          type: CloudSaveErrorType.notConfigured,
        ),
      PlayGamesAvailability.unauthenticated => const CloudSaveUnauthenticated(),
      PlayGamesAvailability.offline => const CloudSaveOffline(),
      _ => const CloudSavePending(type: CloudSaveErrorType.unknown),
    };
    _setState(state);
    return CloudSyncResult(state: state);
  }

  CloudSyncResult _repositoryFailure(CloudRepositoryException error) {
    debugPrint(
      '[cloud_save] event=repository_failure type=${error.type.name} '
      'retryable=${error.retryable}',
    );
    if (error.type == CloudSaveErrorType.unauthenticated) {
      const unauthenticated = CloudSaveUnauthenticated();
      _setState(unauthenticated);
      return const CloudSyncResult(state: unauthenticated);
    }
    if (error.type == CloudSaveErrorType.offline) {
      const offline = CloudSaveOffline();
      _setState(offline);
      return const CloudSyncResult(state: offline);
    }
    if (error.type == CloudSaveErrorType.unsupportedPlatform ||
        error.type == CloudSaveErrorType.notConfigured) {
      final unavailable = CloudSaveUnavailable(type: error.type);
      _setState(unavailable);
      return CloudSyncResult(state: unavailable);
    }
    if (error.retryable) {
      final pending = CloudSavePending(
        type: error.type,
        lastAttemptAt: _now(),
      );
      _setState(pending);
      return CloudSyncResult(state: pending);
    }
    final failure = CloudSaveFailure(
      type: error.type,
      retryable: false,
      message: error.message,
    );
    _setState(failure);
    return CloudSyncResult(state: failure);
  }

  void _attachGameListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;
    _controller.addListener(_onGameChanged);
  }

  void _onGameChanged() {
    if (_suppressGameChanges || _disposed) return;
    _markDirty();
  }

  void _markDirty({bool priority = false}) {
    if (!_dirtyMarked) {
      _dirtyMarked = true;
      unawaited(_local.setPending(true));
    }
    if (_syncInFlight) {
      _resyncRequested = true;
    }
    if ((_state is CloudSaveSynced &&
            !(_state as CloudSaveSynced).hasPendingChanges) ||
        _state is CloudSaveLocalOnly) {
      _setState(const CloudSavePending());
    }
    if (priority) {
      unawaited(synchronize(reason: CloudSyncReason.priority));
    } else {
      _scheduleSync();
    }
  }

  void requestPrioritySync() => _markDirty(priority: true);

  void _scheduleSync() {
    if (_syncTimer != null || _disposed) return;
    _syncTimer = Timer(syncInterval, () {
      _syncTimer = null;
      unawaited(synchronize());
    });
  }

  @override
  Future<CloudSyncResult> uploadCurrentSave() =>
      synchronize(reason: CloudSyncReason.manual);

  @override
  Future<CloudSyncResult> retry() =>
      synchronize(reason: CloudSyncReason.manual);

  @override
  Future<void> onAppPaused() async {
    await _controller.flushLocal();
    _markDirty();
    await synchronize(reason: CloudSyncReason.pause);
  }

  @override
  Future<void> onAppResumed() async {
    final reconciled = await synchronize(reason: CloudSyncReason.resume);
    _controller.resume();
    await _controller.flushLocal();
    if (reconciled.succeeded) {
      _markDirty(priority: true);
    }
  }

  void _setState(CloudSaveState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
    if (!_disposed) notifyListeners();
  }

  DateTime _now() => _clock().toUtc();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _syncTimer?.cancel();
    if (_listenerAttached) {
      _controller.removeListener(_onGameChanged);
    }
    unawaited(_states.close());
    super.dispose();
  }
}
