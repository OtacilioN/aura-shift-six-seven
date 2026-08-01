import 'package:aura_shift_six_seven/achievements/achievement_models.dart';
import 'package:aura_shift_six_seven/achievements/achievement_progress_repository.dart';
import 'package:aura_shift_six_seven/achievements/achievement_sync_service.dart';
import 'package:aura_shift_six_seven/achievements/play_games_achievements_service.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/play_games/play_games_models.dart';
import 'package:aura_shift_six_seven/ui/aura_achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('authenticated state opens the native achievements interface',
      (tester) async {
    final harness = await _Harness.create(PlayGamesAvailability.available);
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.byKey(const ValueKey('open-native-achievements')), findsOne);
    expect(find.text('Sincronização concluída'), findsOne);
    await tester.tap(find.byKey(const ValueKey('open-native-achievements')));
    await tester.pump();
    expect(harness.service.nativeOpenCalls, 1);
  });

  testWidgets('unauthenticated state offers manual connection', (tester) async {
    final harness = await _Harness.create(
      PlayGamesAvailability.unauthenticated,
      authenticated: false,
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.text('Não autenticado'), findsOne);
    expect(find.byKey(const ValueKey('connect-achievements')), findsOne);
  });

  testWidgets('offline progress is shown as safe and pending', (tester) async {
    final harness = await _Harness.create(
      PlayGamesAvailability.offline,
      authenticated: false,
    );
    addTearDown(harness.dispose);
    harness.controller.tap();
    await harness.sync.captureForTesting();
    await harness.pump(tester);
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Sem conexão'), findsOne);
    expect(find.byKey(const ValueKey('achievements-pending')), findsOne);
  });

  testWidgets('missing IDs never crash and disable the native action',
      (tester) async {
    final harness = await _Harness.create(
      PlayGamesAvailability.available,
      idsConfigured: false,
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.text('IDs não configurados'), findsOne);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('open-native-achievements')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
      'unsupported platform and recoverable failure render finite states',
      (tester) async {
    final unsupported = await _Harness.create(
      PlayGamesAvailability.unsupportedPlatform,
      authenticated: false,
    );
    addTearDown(unsupported.dispose);
    await unsupported.pump(tester);
    expect(find.text('Plataforma não suportada'), findsOne);

    final recoverable = await _Harness.create(
      PlayGamesAvailability.temporarilyUnavailable,
      authenticated: false,
    );
    addTearDown(recoverable.dispose);
    await recoverable.pump(tester);
    expect(find.text('Erro recuperável'), findsOne);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

class _Harness {
  _Harness(this.controller, this.service, this.sync);

  static Future<_Harness> create(
    PlayGamesAvailability availability, {
    bool authenticated = true,
    bool idsConfigured = true,
  }) async {
    final controller = await GameController.loadForTesting();
    final service = _WidgetAchievementsService(
      availability: availability,
      authenticated: authenticated,
    );
    final sync = AchievementSyncService(
      controller: controller,
      service: service,
      repository: _WidgetRepository(),
      idsConfigured: () => idsConfigured,
      externalId: (achievement) => achievement.name,
      achievementForExternalId: (_) => null,
      syncInterval: Duration.zero,
      evaluationDebounce: const Duration(milliseconds: 10),
    );
    await sync.initialize();
    return _Harness(controller, service, sync);
  }

  final GameController controller;
  final _WidgetAchievementsService service;
  final AchievementSyncService sync;

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: AuraAchievementsScreen(
            coordinator: sync,
            locale: 'pt-BR',
          ),
        ),
      );

  void dispose() {
    sync.dispose();
    controller.dispose();
  }
}

class _WidgetRepository implements AchievementProgressRepository {
  AchievementQueueState state = AchievementQueueState();

  @override
  Future<AchievementQueueState> read() async => state;

  @override
  Future<void> write(AchievementQueueState value) async {
    state = AchievementQueueState.fromJson(value.toJson());
  }
}

class _WidgetAchievementsService implements PlayGamesAchievementsService {
  _WidgetAchievementsService({
    required this.availability,
    required this.authenticated,
  });

  PlayGamesAvailability availability;
  bool authenticated;
  int nativeOpenCalls = 0;

  @override
  Future<AchievementsInitializationResult> initialize() async =>
      AchievementsInitializationResult(availability);
  @override
  Future<AchievementsInitializationResult> signIn() async =>
      AchievementsInitializationResult(availability);
  @override
  Future<bool> isAuthenticated() async => authenticated;
  @override
  Future<String?> loadPlayerId() async =>
      authenticated ? 'widget-player' : null;
  @override
  Future<List<RemoteAchievementState>> load({
    bool forceReload = false,
  }) async =>
      const [];
  @override
  Future<PlayGamesOperationResult> reveal(AuraAchievement achievement) async =>
      PlayGamesOperationResult(availability);
  @override
  Future<PlayGamesOperationResult> setSteps({
    required AuraAchievement achievement,
    required int steps,
  }) async =>
      PlayGamesOperationResult(availability);
  @override
  Future<PlayGamesOperationResult> showNativeAchievements() async {
    nativeOpenCalls++;
    return PlayGamesOperationResult(availability);
  }

  @override
  Future<PlayGamesOperationResult> unlock(AuraAchievement achievement) async =>
      PlayGamesOperationResult(availability);
}
