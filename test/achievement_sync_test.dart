import 'package:aura_shift_six_seven/achievements/achievement_models.dart';
import 'package:aura_shift_six_seven/achievements/achievement_progress_repository.dart';
import 'package:aura_shift_six_seven/achievements/achievement_sync_service.dart';
import 'package:aura_shift_six_seven/achievements/play_games_achievements_service.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/play_games/play_games_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('offline eligibility is persisted and retried after authentication',
      () async {
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);
    final repository = _MemoryRepository();
    final service = _FakeAchievementsService(
      availability: PlayGamesAvailability.offline,
      authenticated: false,
    );
    final sync = _coordinator(controller, service, repository);
    addTearDown(sync.dispose);

    await sync.initialize();
    controller.tap();
    await Future<void>.delayed(const Duration(milliseconds: 320));

    expect(
      repository.state.pendingUnlocks,
      contains(AuraAchievement.firstSix),
    );
    expect(service.unlockCalls, isEmpty);

    service
      ..availability = PlayGamesAvailability.available
      ..authenticated = true;
    await sync.signIn();

    expect(service.unlockCalls, contains(AuraAchievement.firstSix));
    expect(
      repository.state.confirmedUnlocks,
      contains(AuraAchievement.firstSix),
    );
  });

  test('manual movements do not call Play Games once per movement', () async {
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);
    final repository = _MemoryRepository();
    final service = _FakeAchievementsService();
    final sync = _coordinator(controller, service, repository);
    addTearDown(sync.dispose);
    await sync.initialize();
    service.resetCalls();

    for (var index = 0; index < 20; index++) {
      controller.tap();
    }
    expect(service.totalUpdateCalls, 0);
    await Future<void>.delayed(const Duration(milliseconds: 450));

    expect(service.setStepsCalls.length, lessThanOrEqualTo(5));
    expect(service.totalUpdateCalls, lessThan(20));
  });

  test('remote incremental progress greater than local is never reduced',
      () async {
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);
    for (var index = 0; index < 20; index++) {
      controller.tap();
    }
    final service = _FakeAchievementsService(
      remote: const [
        RemoteAchievementState(
          id: 'manualMovements100',
          status: RemoteAchievementStatus.revealed,
          type: AchievementType.incremental,
          currentSteps: 90,
          totalSteps: 100,
        ),
      ],
    );
    final repository = _MemoryRepository();
    final sync = _coordinator(controller, service, repository);
    addTearDown(sync.dispose);

    await sync.initialize();

    expect(
      service.setStepsCalls[AuraAchievement.manualMovements100],
      isNull,
    );
    expect(
      repository.state.confirmedSteps[AuraAchievement.manualMovements100],
      90,
    );
  });

  test('already unlocked remote achievements are not unlocked twice', () async {
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);
    controller.tap();
    final service = _FakeAchievementsService(
      remote: const [
        RemoteAchievementState(
          id: 'firstSix',
          status: RemoteAchievementStatus.unlocked,
          type: AchievementType.standard,
        ),
      ],
    );
    final sync = _coordinator(
      controller,
      service,
      _MemoryRepository(),
    );
    addTearDown(sync.dispose);

    await sync.initialize();

    expect(service.unlockCalls, isNot(contains(AuraAchievement.firstSix)));
  });

  test('simultaneous sync requests never run native updates in parallel',
      () async {
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);
    controller.tap();
    final service = _FakeAchievementsService(
      updateDelay: const Duration(milliseconds: 60),
    );
    final sync = _coordinator(
      controller,
      service,
      _MemoryRepository(),
    );
    addTearDown(sync.dispose);
    await sync.initialize();
    service.resetCalls();
    controller.tap();
    await sync.captureForTesting();

    await Future.wait([
      sync.synchronize(forceRemoteReload: true),
      sync.synchronize(forceRemoteReload: true),
      sync.synchronize(forceRemoteReload: true),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(service.maximumConcurrentUpdates, 1);
  });

  test('account switch discards the previous player queue', () async {
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);
    final previous = AchievementQueueState(
      ownerPlayerId: 'old-player',
      confirmedUnlocks: {AuraAchievement.fortyTwo},
      reconciliationVersion: achievementCatalogVersion,
    );
    final repository = _MemoryRepository(previous);
    final service = _FakeAchievementsService(playerId: 'new-player');
    final sync = _coordinator(controller, service, repository);
    addTearDown(sync.dispose);

    await sync.initialize();

    expect(repository.state.ownerPlayerId, 'new-player');
    expect(
      repository.state.confirmedUnlocks,
      isNot(contains(AuraAchievement.fortyTwo)),
    );
  });

  test('missing IDs and unsupported platforms stay non-blocking', () async {
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);
    final missingIds = AchievementSyncService(
      controller: controller,
      service: _FakeAchievementsService(),
      repository: _MemoryRepository(),
      idsConfigured: () => false,
      externalId: (_) => '',
    );
    addTearDown(missingIds.dispose);
    final missingResult = await missingIds.initialize();
    expect(
      missingResult.availability,
      PlayGamesAvailability.notConfigured,
    );

    final unsupported = _coordinator(
      controller,
      _FakeAchievementsService(
        availability: PlayGamesAvailability.unsupportedPlatform,
        authenticated: false,
      ),
      _MemoryRepository(),
    );
    addTearDown(unsupported.dispose);
    final unsupportedResult = await unsupported.initialize();
    expect(
      unsupportedResult.availability,
      PlayGamesAvailability.unsupportedPlatform,
    );
  });

  test('recoverable native errors keep pending operations for retry', () async {
    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);
    controller.tap();
    final service = _FakeAchievementsService(
      updateAvailability: PlayGamesAvailability.temporarilyUnavailable,
    );
    final repository = _MemoryRepository();
    final sync = _coordinator(controller, service, repository);
    addTearDown(sync.dispose);

    final result = await sync.initialize();

    expect(
      result.availability,
      PlayGamesAvailability.available,
    );
    expect(repository.state.pendingUnlocks, isNotEmpty);
    expect(repository.state.failedAttempts, greaterThan(0));
  });
}

AchievementSyncService _coordinator(
  GameController controller,
  _FakeAchievementsService service,
  _MemoryRepository repository,
) =>
    AchievementSyncService(
      controller: controller,
      service: service,
      repository: repository,
      syncInterval: const Duration(days: 1),
      evaluationDebounce: const Duration(milliseconds: 250),
      idsConfigured: () => true,
      externalId: (achievement) => achievement.name,
      achievementForExternalId: (id) {
        for (final achievement in AuraAchievement.values) {
          if (achievement.name == id) return achievement;
        }
        return null;
      },
    );

class _MemoryRepository implements AchievementProgressRepository {
  _MemoryRepository([AchievementQueueState? initial])
      : state = initial ?? AchievementQueueState();

  AchievementQueueState state;

  @override
  Future<AchievementQueueState> read() async => state;

  @override
  Future<void> write(AchievementQueueState value) async {
    state = AchievementQueueState.fromJson(value.toJson());
  }
}

class _FakeAchievementsService implements PlayGamesAchievementsService {
  _FakeAchievementsService({
    this.availability = PlayGamesAvailability.available,
    this.authenticated = true,
    this.playerId = 'player-1',
    this.remote = const [],
    this.updateDelay = Duration.zero,
    this.updateAvailability = PlayGamesAvailability.available,
  });

  PlayGamesAvailability availability;
  bool authenticated;
  String playerId;
  List<RemoteAchievementState> remote;
  Duration updateDelay;
  PlayGamesAvailability updateAvailability;
  final List<AuraAchievement> unlockCalls = [];
  final List<AuraAchievement> revealCalls = [];
  final Map<AuraAchievement, int> setStepsCalls = {};
  int _concurrentUpdates = 0;
  int maximumConcurrentUpdates = 0;

  int get totalUpdateCalls =>
      unlockCalls.length + revealCalls.length + setStepsCalls.length;

  void resetCalls() {
    unlockCalls.clear();
    revealCalls.clear();
    setStepsCalls.clear();
    maximumConcurrentUpdates = 0;
  }

  @override
  Future<AchievementsInitializationResult> initialize() async =>
      AchievementsInitializationResult(availability);

  @override
  Future<AchievementsInitializationResult> signIn() async =>
      AchievementsInitializationResult(availability);

  @override
  Future<bool> isAuthenticated() async => authenticated;

  @override
  Future<String?> loadPlayerId() async => authenticated ? playerId : null;

  @override
  Future<List<RemoteAchievementState>> load({
    bool forceReload = false,
  }) async =>
      remote;

  @override
  Future<PlayGamesOperationResult> unlock(
    AuraAchievement achievement,
  ) async {
    unlockCalls.add(achievement);
    return _update();
  }

  @override
  Future<PlayGamesOperationResult> reveal(
    AuraAchievement achievement,
  ) async {
    revealCalls.add(achievement);
    return _update();
  }

  @override
  Future<PlayGamesOperationResult> setSteps({
    required AuraAchievement achievement,
    required int steps,
  }) async {
    setStepsCalls[achievement] = steps;
    return _update();
  }

  Future<PlayGamesOperationResult> _update() async {
    _concurrentUpdates++;
    if (_concurrentUpdates > maximumConcurrentUpdates) {
      maximumConcurrentUpdates = _concurrentUpdates;
    }
    if (updateDelay > Duration.zero) {
      await Future<void>.delayed(updateDelay);
    }
    _concurrentUpdates--;
    return PlayGamesOperationResult(updateAvailability);
  }

  @override
  Future<PlayGamesOperationResult> showNativeAchievements() async =>
      PlayGamesOperationResult(availability);
}
