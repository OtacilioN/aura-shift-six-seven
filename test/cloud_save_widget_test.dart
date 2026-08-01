import 'dart:async';

import 'package:aura_shift_six_seven/cloud_save/cloud_game_save_repository.dart';
import 'package:aura_shift_six_seven/cloud_save/cloud_save_models.dart';
import 'package:aura_shift_six_seven/main.dart';
import 'package:aura_shift_six_seven/play_games/play_games_models.dart';
import 'package:aura_shift_six_seven/ui/cloud_save_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cloud_save_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Strings strings;

  setUpAll(() async {
    strings = await Strings.load('en-US');
  });

  testWidgets('renders synced, unauthenticated, offline and unavailable states',
      (tester) async {
    final synced = await CloudSaveHarness.create(
      gameState: validGameState(total: 67),
    );
    await synced.coordinator.synchronize();
    await _pumpSection(tester, synced, strings);
    expect(find.text(strings('cloud_save_synced')), findsOneWidget);
    expect(find.text('Player Test'), findsOneWidget);
    expect(find.text(strings('cloud_save_sync_now')), findsOneWidget);
    synced.dispose();

    final unauthenticatedService = FakeCloudPlayGamesService(
      initializeResult: const PlayGamesOperationResult(
        PlayGamesAvailability.unauthenticated,
      ),
      authenticated: false,
    );
    final unauthenticated = await CloudSaveHarness.create(
      playGames: unauthenticatedService,
    );
    await unauthenticated.coordinator.synchronize();
    await _pumpSection(tester, unauthenticated, strings);
    expect(find.text(strings('cloud_save_unauthenticated')), findsOneWidget);
    expect(find.text(strings('cloud_save_connect')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cloud-save-action')));
    await tester.pump();
    expect(unauthenticatedService.signInCalls, 1);
    unauthenticated.dispose();

    final offlineService = FakeCloudPlayGamesService(
      initializeResult: const PlayGamesOperationResult(
        PlayGamesAvailability.offline,
      ),
    );
    final offline = await CloudSaveHarness.create(playGames: offlineService);
    await offline.coordinator.synchronize();
    await _pumpSection(tester, offline, strings);
    expect(find.text(strings('cloud_save_offline')), findsOneWidget);
    expect(find.text(strings('cloud_save_retry')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cloud-save-pending')),
      findsOneWidget,
    );
    offline.dispose();

    final unsupported = await CloudSaveHarness.create(
      cloud: FakeCloudGameSaveRepository(supported: false),
    );
    await unsupported.coordinator.synchronize();
    await _pumpSection(tester, unsupported, strings);
    expect(find.text(strings('cloud_save_unavailable')), findsOneWidget);
    expect(find.text(strings('cloud_save_sync_now')), findsOneWidget);
    unsupported.dispose();
  });

  testWidgets('shows progress while syncing and disables the action',
      (tester) async {
    final initialization = Completer<PlayGamesOperationResult>();
    final service = FakeCloudPlayGamesService()
      ..blockedInitialization = initialization;
    final harness = await CloudSaveHarness.create(playGames: service);
    addTearDown(harness.dispose);

    final synchronization = harness.coordinator.synchronize();
    await _pumpSection(tester, harness, strings);

    expect(find.text(strings('cloud_save_syncing')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('cloud-save-action')),
    );
    expect(button.onPressed, isNull);

    initialization.complete(const PlayGamesOperationResult.available());
    await synchronization;
    await tester.pump();
    expect(find.text(strings('cloud_save_synced')), findsOneWidget);
  });

  testWidgets('retry shows confirmed success while newer changes stay queued',
      (tester) async {
    final cloud = FakeCloudGameSaveRepository()
      ..openError = const CloudRepositoryException(
        CloudSaveErrorType.busy,
      );
    final harness = await CloudSaveHarness.create(
      cloud: cloud,
      syncInterval: const Duration(hours: 1),
    );
    addTearDown(harness.dispose);

    await harness.coordinator.initialize();
    await _pumpSection(tester, harness, strings);
    expect(find.text(strings('cloud_save_pending')), findsOneWidget);

    cloud.openError = null;
    final blockedCommit = Completer<void>();
    cloud.blockedCommit = blockedCommit;
    await tester.tap(find.byKey(const ValueKey('cloud-save-action')));
    await tester.pump();
    await tester.runAsync(
      () => _waitUntil(() => cloud.activeOperations == 1),
    );

    harness.controller.tap();
    blockedCommit.complete();
    await tester.pumpAndSettle();

    expect(find.text(strings('cloud_save_synced')), findsWidgets);
    expect(find.text(strings('cloud_save_sync_now')), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(strings('cloud_save_synced')),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cloud-save-pending')),
      findsOneWidget,
    );
    harness.coordinator.dispose();
  });

  testWidgets('renders local-only, retry-pending and terminal failure states',
      (tester) async {
    final localOnly = await CloudSaveHarness.create();
    await _pumpSection(tester, localOnly, strings);
    expect(find.text(strings('cloud_save_local')), findsOneWidget);
    expect(find.text(strings('cloud_save_sync_now')), findsOneWidget);
    localOnly.dispose();

    final pendingCloud = FakeCloudGameSaveRepository()
      ..openError = const CloudRepositoryException(
        CloudSaveErrorType.busy,
      );
    final pending = await CloudSaveHarness.create(cloud: pendingCloud);
    await pending.coordinator.synchronize();
    await _pumpSection(tester, pending, strings);
    expect(find.text(strings('cloud_save_pending')), findsOneWidget);
    expect(find.text(strings('cloud_save_retry')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('cloud-save-pending')),
      findsOneWidget,
    );
    pending.dispose();

    final failedCloud = FakeCloudGameSaveRepository()
      ..openError = const CloudRepositoryException(
        CloudSaveErrorType.sizeLimit,
        retryable: false,
      );
    final failed = await CloudSaveHarness.create(cloud: failedCloud);
    await failed.coordinator.synchronize();
    await _pumpSection(tester, failed, strings);
    expect(find.text(strings('cloud_save_failed')), findsOneWidget);
    expect(find.text(strings('cloud_save_retry')), findsOneWidget);
    failed.dispose();
  });

  testWidgets('conflict dialog compares whole saves and resolves one choice',
      (tester) async {
    final first = envelopeFor(
      state: validGameState(
        total: 6700,
        totalPlayTimeMillis: const Duration(minutes: 1).inMilliseconds,
      ),
      revision: 3,
      installationId: 'device-a',
      totalPlayTime: const Duration(minutes: 1),
    );
    final second = envelopeFor(
      state: validGameState(
        total: 67,
        totalPlayTimeMillis: const Duration(hours: 1).inMilliseconds,
      ),
      revision: 4,
      installationId: 'device-b',
      totalPlayTime: const Duration(hours: 1),
    );
    final firstSnapshot = remoteDataFor(first).snapshot;
    final secondSnapshot = remoteDataFor(second).snapshot;
    final cloud = FakeCloudGameSaveRepository(
      openResult: CloudRemoteConflict(
        token: 'native-conflict',
        server: firstSnapshot,
        conflicting: secondSnapshot,
      ),
    );
    final harness = await CloudSaveHarness.create(
      gameState: validGameState(total: 1),
      cloud: cloud,
    );
    addTearDown(harness.dispose);

    final result = await harness.coordinator.synchronize();
    expect(result.state, isA<CloudSaveConflictPending>());
    final candidateCount =
        harness.coordinator.pendingConflict!.candidates.length;
    await _pumpSection(tester, harness, strings);

    expect(find.textContaining('Export'), findsNothing);
    expect(find.textContaining('Import'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('cloud-save-resolve-conflict')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cloud-save-conflict-dialog')),
      findsOneWidget,
    );
    expect(find.text(strings('cloud_save_cloud')), findsOneWidget);
    expect(find.text(strings('cloud_save_other_device')), findsOneWidget);
    expect(find.text(strings('cloud_save_this_device')), findsOneWidget);
    expect(find.text(strings('cloud_save_recommended')), findsOneWidget);
    final choices = find.descendant(
      of: find.byKey(const ValueKey('cloud-save-conflict-dialog')),
      matching: find.widgetWithText(
        FilledButton,
        strings('cloud_save_use_this'),
      ),
    );
    expect(choices, findsNWidgets(candidateCount));

    await tester.tap(choices.first);
    await tester.pumpAndSettle();

    expect(cloud.resolveCalls, 1);
    expect(cloud.resolvedTokens, <String>['native-conflict']);
    expect(harness.coordinator.state, isA<CloudSaveSynced>());
    expect(
      find.byKey(const ValueKey('cloud-save-conflict-dialog')),
      findsNothing,
    );
  });

  testWidgets('postponing preserves the conflict until a later choice',
      (tester) async {
    final first = envelopeFor(
      state: validGameState(
        total: 6700,
        totalPlayTimeMillis: const Duration(minutes: 1).inMilliseconds,
      ),
      totalPlayTime: const Duration(minutes: 1),
    );
    final second = envelopeFor(
      state: validGameState(
        total: 67,
        totalPlayTimeMillis: const Duration(hours: 1).inMilliseconds,
      ),
      totalPlayTime: const Duration(hours: 1),
    );
    final cloud = FakeCloudGameSaveRepository(
      openResult: CloudRemoteConflict(
        token: 'postpone-me',
        server: remoteDataFor(first).snapshot,
        conflicting: remoteDataFor(second).snapshot,
      ),
    );
    final harness = await CloudSaveHarness.create(cloud: cloud);
    addTearDown(harness.dispose);

    await harness.coordinator.synchronize();
    await _pumpSection(tester, harness, strings);
    await tester.tap(
      find.byKey(const ValueKey('cloud-save-resolve-conflict')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings('cloud_save_later')));
    await tester.pumpAndSettle();

    expect(cloud.abandonCalls, 0);
    expect(harness.coordinator.state, isA<CloudSaveConflictPending>());

    await tester.tap(
      find.byKey(const ValueKey('cloud-save-resolve-conflict')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, strings('cloud_save_use_this')).first,
    );
    await tester.pumpAndSettle();

    expect(cloud.resolveCalls, 1);
    expect(cloud.resolvedTokens, <String>['postpone-me']);
    expect(harness.coordinator.state, isA<CloudSaveSynced>());
  });
}

Future<void> _pumpSection(
  WidgetTester tester,
  CloudSaveHarness harness,
  Strings strings,
) =>
    tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CloudSaveSection(
              coordinator: harness.coordinator,
              strings: strings,
            ),
          ),
        ),
      ),
    );

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
