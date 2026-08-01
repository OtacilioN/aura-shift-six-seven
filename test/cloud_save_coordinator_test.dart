import 'dart:async';

import 'package:aura_shift_six_seven/cloud_save/cloud_game_save_repository.dart';
import 'package:aura_shift_six_seven/cloud_save/cloud_save_envelope.dart';
import 'package:aura_shift_six_seven/cloud_save/cloud_save_models.dart';
import 'package:aura_shift_six_seven/play_games/play_games_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cloud_save_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudSaveCoordinator reconciliation', () {
    test('first authenticated save uploads the complete local state', () async {
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 67),
      );
      addTearDown(harness.dispose);

      final result = await harness.coordinator.synchronize();

      expect(result.succeeded, isTrue);
      expect(result.uploaded, isTrue);
      expect(harness.cloud.commitCalls, 1);
      expect(harness.local.ownerPlayerId, 'player-test');
      expect(harness.local.hasPendingChanges, isFalse);
      final uploaded =
          const GameSaveCodec().decode(harness.cloud.committedPayloads.single);
      expect(uploaded.gameState['total'], '67');
      expect(uploaded.gameState['available'], '67');
    });

    test('a dominant cloud snapshot replaces the local save as one unit',
        () async {
      final remote = envelopeFor(
        state: validGameState(
          total: 6700,
          cycles: 2,
          totalPlayTimeMillis: const Duration(minutes: 5).inMilliseconds,
        ),
        revision: 4,
        installationId: 'other-device',
        totalPlayTime: const Duration(minutes: 5),
      );
      final cloud = FakeCloudGameSaveRepository(
        openResult: remoteDataFor(remote),
      );
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 67, cycles: 1),
        cloud: cloud,
      );
      addTearDown(harness.dispose);

      final result = await harness.coordinator.synchronize();

      expect(result.restored, isTrue);
      expect(harness.controller.total, BigInt.from(6700));
      expect(harness.controller.available, BigInt.from(6700));
      expect(harness.controller.cycles, 2);
      expect(cloud.commitCalls, 0);
    });

    test('an account switch never silently uploads progress to an empty slot',
        () async {
      final playGames = FakeCloudPlayGamesService(
        player: const PlayGamesPlayer(
          playerId: 'new-player',
          displayName: 'New Player',
        ),
      );
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 67),
        preferences: const <String, Object>{
          'cloud-save-owner-player-id': 'old-player',
        },
        playGames: playGames,
      );
      addTearDown(harness.dispose);

      final result = await harness.coordinator.synchronize();

      expect(result.state, isA<CloudSaveConflictPending>());
      final conflict = harness.coordinator.pendingConflict!;
      expect(conflict.accountSwitch, isTrue);
      expect(conflict.playerId, 'new-player');
      expect(harness.cloud.commitCalls, 0);

      final resolved =
          await harness.coordinator.resolveConflict(conflict.first.id);
      expect(resolved.succeeded, isTrue);
      expect(harness.cloud.commitCalls, 1);
      expect(harness.local.ownerPlayerId, 'new-player');
    });

    test('unauthenticated and offline states keep the local save pending',
        () async {
      final unauthenticatedService = FakeCloudPlayGamesService(
        initializeResult: const PlayGamesOperationResult(
          PlayGamesAvailability.unauthenticated,
        ),
        authenticated: false,
      );
      final unauthenticated = await CloudSaveHarness.create(
        gameState: validGameState(total: 1),
        playGames: unauthenticatedService,
      );
      addTearDown(unauthenticated.dispose);

      final unauthenticatedResult =
          await unauthenticated.coordinator.synchronize();
      expect(unauthenticatedResult.state, isA<CloudSaveUnauthenticated>());
      expect(unauthenticated.cloud.openCalls, 0);
      expect(unauthenticated.local.hasPendingChanges, isTrue);

      final offlineService = FakeCloudPlayGamesService(
        initializeResult: const PlayGamesOperationResult(
          PlayGamesAvailability.offline,
        ),
      );
      final offline = await CloudSaveHarness.create(
        gameState: validGameState(total: 1),
        playGames: offlineService,
      );
      addTearDown(offline.dispose);

      final offlineResult = await offline.coordinator.synchronize();
      expect(offlineResult.state, isA<CloudSaveOffline>());
      expect(offline.cloud.openCalls, 0);
      expect(offline.local.hasPendingChanges, isTrue);
    });

    test('timeout is bounded and retry succeeds after connectivity returns',
        () async {
      final playGames = FakeCloudPlayGamesService()
        ..blockedInitialization = Completer<PlayGamesOperationResult>();
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 1),
        playGames: playGames,
        operationTimeout: const Duration(milliseconds: 5),
      );
      addTearDown(harness.dispose);

      final timedOut = await harness.coordinator.synchronize();
      expect(timedOut.state, isA<CloudSavePending>());
      expect(
        (timedOut.state as CloudSavePending).type,
        CloudSaveErrorType.timeout,
      );

      playGames.blockedInitialization = null;
      final retried = await harness.coordinator.retry();
      expect(retried.succeeded, isTrue);
      expect(harness.cloud.commitCalls, 1);
    });

    test('retry recovers an explicitly offline repository failure', () async {
      final cloud = FakeCloudGameSaveRepository()
        ..openError = const CloudRepositoryException(
          CloudSaveErrorType.offline,
        );
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 1),
        cloud: cloud,
      );
      addTearDown(harness.dispose);

      final offline = await harness.coordinator.synchronize();
      expect(offline.state, isA<CloudSaveOffline>());

      cloud.openError = null;
      final recovered = await harness.coordinator.retry();
      expect(recovered.succeeded, isTrue);
      expect(cloud.commitCalls, 1);
    });

    test('not-configured Saved Games is unavailable instead of retry-pending',
        () async {
      final cloud = FakeCloudGameSaveRepository()
        ..openError = const CloudRepositoryException(
          CloudSaveErrorType.notConfigured,
          retryable: false,
        );
      final harness = await CloudSaveHarness.create(cloud: cloud);
      addTearDown(harness.dispose);

      final result = await harness.coordinator.synchronize();

      expect(result.state, isA<CloudSaveUnavailable>());
      expect(
        (result.state as CloudSaveUnavailable).type,
        CloudSaveErrorType.notConfigured,
      );
    });
  });

  group('CloudSaveCoordinator scheduling', () {
    test('coalesces concurrent requests and never opens in parallel', () async {
      final blocker = Completer<CloudRemoteResult>();
      final cloud = FakeCloudGameSaveRepository()..blockedOpen = blocker;
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 1),
        cloud: cloud,
        syncInterval: const Duration(milliseconds: 1),
      );
      addTearDown(harness.dispose);

      final first = harness.coordinator.synchronize();
      await _waitUntil(() => cloud.openCalls == 1);
      final second = await harness.coordinator.synchronize();

      expect(second.state, isA<CloudSaveSyncing>());
      expect(cloud.openCalls, 1);
      expect(cloud.maximumConcurrentOperations, 1);

      blocker.complete(const CloudRemoteMissing());
      final firstResult = await first;
      expect(firstResult.state, isA<CloudSaveSynced>());
      expect(firstResult.succeeded, isTrue);
      expect(firstResult.state.hasPendingChanges, isTrue);
      await _waitUntil(() => cloud.openCalls >= 2);

      expect(cloud.maximumConcurrentOperations, 1);
      expect(cloud.openCalls, 2);
    });

    test('confirmed upload stays successful when a newer tick is pending',
        () async {
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 1),
        syncInterval: const Duration(milliseconds: 20),
      );
      addTearDown(harness.dispose);

      await harness.coordinator.initialize();
      await _waitUntil(() => harness.coordinator.state is CloudSaveSynced);

      harness.controller.tap();
      final blockedCommit = Completer<void>();
      harness.cloud.blockedCommit = blockedCommit;
      final synchronization = harness.coordinator.synchronize();
      await _waitUntil(() => harness.cloud.activeOperations == 1);

      harness.controller.tap();
      blockedCommit.complete();
      final result = await synchronization;

      expect(result.succeeded, isTrue);
      expect(result.state, isA<CloudSaveSynced>());
      expect(result.state.hasPendingChanges, isTrue);
      expect(harness.coordinator.lastSuccessfulSync, isNotNull);
      expect(harness.local.hasPendingChanges, isTrue);

      await _waitUntil(() => harness.cloud.commitCalls >= 3);
      await _waitUntil(
        () =>
            harness.coordinator.state is CloudSaveSynced &&
            !harness.coordinator.state.hasPendingChanges,
      );
    });

    test('a new game change is debounced into a later upload', () async {
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 1),
        syncInterval: const Duration(milliseconds: 5),
      );
      addTearDown(harness.dispose);

      await harness.coordinator.initialize();
      await _waitUntil(() => harness.coordinator.state is CloudSaveSynced);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final commitsBeforeChange = harness.cloud.commitCalls;

      harness.controller.tap();
      await _waitUntil(
        () => harness.coordinator.state is CloudSavePending,
      );
      await _waitUntil(
        () => harness.cloud.commitCalls > commitsBeforeChange,
      );

      expect(harness.cloud.commitCalls, commitsBeforeChange + 1);
      expect(harness.coordinator.state, isA<CloudSaveSynced>());
    });

    test('a change during upload stays pending and starts a second round',
        () async {
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 1),
        syncInterval: const Duration(milliseconds: 5),
      );
      addTearDown(harness.dispose);

      await harness.coordinator.initialize();
      await _waitUntil(() => harness.coordinator.state is CloudSaveSynced);
      final commitsBeforeChange = harness.cloud.commitCalls;
      final blockedCommit = Completer<void>();
      harness.cloud.blockedCommit = blockedCommit;

      harness.controller.tap();
      await _waitUntil(
        () => harness.cloud.commitCalls > commitsBeforeChange,
      );
      harness.controller.tap();
      await Future<void>.delayed(const Duration(milliseconds: 1));
      blockedCommit.complete();
      harness.cloud.blockedCommit = null;

      await _waitUntil(
        () => harness.cloud.commitCalls >= commitsBeforeChange + 2,
      );
      await _waitUntil(() => harness.coordinator.state is CloudSaveSynced);

      expect(harness.cloud.maximumConcurrentOperations, 1);
      expect(harness.cloud.commitCalls, commitsBeforeChange + 2);
      final latest = const GameSaveCodec().decode(
        harness.cloud.committedPayloads.last,
      );
      expect(latest.gameState['cycles'], 1);
    });

    test('pause and resume sync around offline progress reconciliation',
        () async {
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 1),
        syncInterval: const Duration(milliseconds: 5),
      );
      addTearDown(harness.dispose);

      await harness.coordinator.initialize();
      await _waitUntil(() => harness.coordinator.state is CloudSaveSynced);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final opensBeforeLifecycle = harness.cloud.openCalls;

      harness.controller.pause();
      await harness.coordinator.onAppPaused();
      await harness.coordinator.onAppResumed();
      await _waitUntil(
        () => harness.cloud.openCalls >= opensBeforeLifecycle + 2,
      );

      expect(harness.cloud.openCalls,
          greaterThanOrEqualTo(opensBeforeLifecycle + 2));
      expect(harness.controller.captureSaveState()['offlineAt'], isNull);
    });

    test('unsupported platforms are a no-op and never touch the remote',
        () async {
      final cloud = FakeCloudGameSaveRepository(supported: false);
      final harness = await CloudSaveHarness.create(
        gameState: validGameState(total: 1),
        cloud: cloud,
      );
      addTearDown(harness.dispose);

      final initialized = await harness.coordinator.initialize();
      final manual = await harness.coordinator.uploadCurrentSave();

      expect(initialized.state, isA<CloudSaveUnavailable>());
      expect(manual.state, isA<CloudSaveUnavailable>());
      expect(cloud.openCalls, 0);
      expect(cloud.commitCalls, 0);
    });
  });
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition was not reached within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}
