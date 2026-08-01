import 'dart:convert';

import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/play_games/aura_leaderboard_score_codec.dart';
import 'package:aura_shift_six_seven/play_games/play_games_coordinator.dart';
import 'package:aura_shift_six_seven/play_games/play_games_ids.dart';
import 'package:aura_shift_six_seven/play_games/play_games_models.dart';
import 'package:aura_shift_six_seven/play_games/play_games_service.dart';
import 'package:aura_shift_six_seven/play_games/play_games_store.dart';
import 'package:aura_shift_six_seven/play_games/play_games_week.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Play Games week', () {
    test('changes Sunday at 07:00 UTC', () {
      expect(
        PlayGamesWeek.keyFor(DateTime.utc(2026, 7, 26, 6, 59, 59)),
        '2026-07-19',
      );
      expect(
        PlayGamesWeek.keyFor(DateTime.utc(2026, 7, 26, 7)),
        '2026-07-26',
      );
    });

    test('uses the same key throughout the Play Games week', () {
      expect(
        PlayGamesWeek.keyFor(DateTime.utc(2026, 7, 27, 12)),
        PlayGamesWeek.keyFor(DateTime.utc(2026, 8, 1, 23, 59)),
      );
    });
  });

  group('Aura leaderboard score codec', () {
    test('keeps zero and safe small values exact', () {
      expect(AuraLeaderboardScoreCodec.encode(BigInt.zero), 0);
      expect(AuraLeaderboardScoreCodec.encode(BigInt.from(67)), 67);
      expect(
        AuraLeaderboardScoreCodec.decodeApproximate(999999999999999),
        BigInt.parse('999999999999999'),
      );
    });

    test('is monotonic across exact, compressed, and saturated values', () {
      final values = [
        BigInt.zero,
        BigInt.one,
        BigInt.parse('999999999999999'),
        BigInt.parse('1000000000000000'),
        BigInt.parse('9999999999999999'),
        BigInt.from(10).pow(100),
        BigInt.from(10).pow(10000),
      ];
      final encoded = values.map(AuraLeaderboardScoreCodec.encode).toList();
      for (var index = 1; index < encoded.length; index++) {
        expect(encoded[index], greaterThanOrEqualTo(encoded[index - 1]));
      }
      expect(encoded.last, AuraLeaderboardScoreCodec.maxInt64.toInt());
    });

    test('decodes a large value approximately without overflow', () {
      final value = BigInt.parse('123456789012345678901234567890');
      final decoded = AuraLeaderboardScoreCodec.decodeApproximate(
        AuraLeaderboardScoreCodec.encode(value),
      );
      expect(decoded <= value, isTrue);
      expect(decoded.toString().length, value.toString().length);
    });

    test('rejects negative values', () {
      expect(
        () => AuraLeaderboardScoreCodec.encode(BigInt.from(-1)),
        throwsArgumentError,
      );
    });
  });

  test('aura progress level is small and monotonic', () {
    final values = [
      BigInt.zero,
      BigInt.one,
      BigInt.from(67),
      BigInt.from(1000),
      BigInt.from(10).pow(100),
    ];
    final levels = values.map(auraProgressLevel).toList();
    expect(levels, orderedEquals([0, 1, 2, 4, 101]));
  });

  test('friends and social scores merge by player ID', () {
    final merged = mergeFriendsAndScores(
      currentPlayerId: 'me',
      friends: const [
        PlayGamesFriend(playerId: 'a', displayName: 'Ana'),
        PlayGamesFriend(playerId: 'b', displayName: 'Bia'),
      ],
      scores: [
        LeaderboardEntry(
          playerId: 'a',
          displayName: 'Ana',
          rank: 2,
          encodedScore: 67,
          auraValue: BigInt.from(67),
        ),
      ],
    );
    expect(merged, hasLength(2));
    expect(merged.first.playerId, 'a');
    expect(merged.last.hasScore, isFalse);
  });

  group('Play Games coordinator', () {
    late GameController controller;
    late MemoryPlayGamesStore store;
    late FakePlayGamesService service;
    late PlayGamesCoordinator coordinator;
    late DateTime now;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'save-v1': jsonEncode({
          'total': '100',
          'available': '100',
          'journey': '100',
          'remainder': '0',
          'multiplier': '100',
        }),
      });
      controller = await GameController.loadForTesting();
      store = MemoryPlayGamesStore();
      service = FakePlayGamesService();
      now = DateTime.utc(2026, 7, 27, 12);
      coordinator = PlayGamesCoordinator(
        controller: controller,
        service: service,
        store: store,
        clock: () => now,
      );
      await coordinator.initialize();
    });

    tearDown(() {
      coordinator.dispose();
      controller.dispose();
    });

    test('old saves start safely without counting lifetime aura as weekly', () {
      expect(coordinator.weeklyAura, BigInt.zero);
      expect(store.value['lastObservedTotal'], '100');
    });

    test('queues offline changes and flushes after authentication', () async {
      service.authenticated = false;
      await coordinator.captureForTesting(
        snapshot(total: 167, aps: 4, movement: 3, manual: 1),
        now,
      );
      await coordinator.flush(force: true);
      expect(service.submittedScores, isEmpty);
      expect(coordinator.weeklyAura, BigInt.from(67));

      service.authenticated = true;
      now = now.add(const Duration(minutes: 1));
      await coordinator.flush(force: true);
      expect(
        service.submittedScores[AuraLeaderboard.weeklyAura],
        BigInt.from(67),
      );
      expect(service.statsDeltas.single.auraEarnedDelta, BigInt.from(67));
    });

    test('submits records only when they increase', () async {
      await coordinator.captureForTesting(
        snapshot(total: 100, aps: 50, movement: 25),
        now,
      );
      await coordinator.flush(force: true);
      expect(
        service.submittedScores[AuraLeaderboard.maxAuraPerSecond],
        BigInt.from(50),
      );
      expect(
        service.submittedScores[AuraLeaderboard.maxAuraPerMovement],
        BigInt.from(25),
      );
      final calls = service.scoreCalls;

      now = now.add(const Duration(minutes: 1));
      await coordinator.captureForTesting(
        snapshot(total: 100, aps: 40, movement: 20),
        now,
      );
      await coordinator.flush(force: true);
      expect(service.scoreCalls, calls);
    });

    test('throttles regular flushes until the next checkpoint', () async {
      await coordinator.captureForTesting(snapshot(total: 167), now);
      await coordinator.flush();
      final calls = service.scoreCalls;
      await coordinator.captureForTesting(snapshot(total: 200), now);
      await coordinator.flush();
      expect(service.scoreCalls, calls);
      now = now.add(const Duration(seconds: 46));
      await coordinator.flush();
      expect(service.scoreCalls, greaterThan(calls));
    });

    test('rolls only the weekly counter at a new Play Games week', () async {
      await coordinator.captureForTesting(snapshot(total: 167), now);
      expect(coordinator.weeklyAura, BigInt.from(67));
      now = DateTime.utc(2026, 8, 2, 7);
      await coordinator.captureForTesting(snapshot(total: 200), now);
      expect(coordinator.weeklyAura, BigInt.from(33));
      expect(coordinator.maxAuraPerSecond, isNotNull);
    });

    test('does not duplicate deltas after persistence and restart', () async {
      await coordinator.captureForTesting(
        snapshot(total: 167, manual: 2),
        now,
      );
      final persisted = Map<String, dynamic>.from(store.value);
      coordinator.dispose();
      store = MemoryPlayGamesStore(persisted);
      coordinator = PlayGamesCoordinator(
        controller: controller,
        service: service,
        store: store,
        clock: () => now,
      );
      await coordinator.initialize();
      await coordinator.captureForTesting(
        snapshot(total: 167, manual: 2),
        now,
      );
      final delta = GameStatsDelta.fromJson(
        Map<String, dynamic>.from(store.value['pendingStatsDelta'] as Map),
      );
      expect(delta.auraEarnedDelta, BigInt.zero);
      expect(delta.manualActionsDelta, 0);
      expect(service.statsDeltas.single.auraEarnedDelta, BigInt.from(67));
      expect(service.statsDeltas.single.manualActionsDelta, 2);
    });

    test('restore updates snapshots without rebuilding SUM deltas', () async {
      await coordinator.captureForTesting(
        snapshot(total: 999999, manual: 999, restoration: 1),
        now,
      );
      expect(coordinator.weeklyAura, BigInt.zero);
      final delta = GameStatsDelta.fromJson(
        Map<String, dynamic>.from(store.value['pendingStatsDelta'] as Map),
      );
      expect(delta.auraEarnedDelta, BigInt.zero);
      expect(delta.manualActionsDelta, 0);
      expect(store.value['pendingProgress'], isA<Map>());
    });

    test('persists friends consent granted', () async {
      service.friendsAvailability = PlayGamesAvailability.consentRequired;
      await coordinator.loadLeaderboard(
        leaderboard: AuraLeaderboard.weeklyAura,
        timeScope: LeaderboardTimeScope.weekly,
        playerScope: LeaderboardPlayerScope.friends,
      );
      expect(
        coordinator.friendsConsentState,
        FriendsConsentState.required,
      );
      service.consentAvailability = PlayGamesAvailability.available;
      expect(await coordinator.requestFriendsConsent(), isTrue);
      expect(
        coordinator.friendsConsentState,
        FriendsConsentState.granted,
      );
    });

    test('persists friends consent denial without retry loops', () async {
      service.friendsAvailability = PlayGamesAvailability.consentRequired;
      await coordinator.loadLeaderboard(
        leaderboard: AuraLeaderboard.weeklyAura,
        timeScope: LeaderboardTimeScope.weekly,
        playerScope: LeaderboardPlayerScope.friends,
      );
      service.consentAvailability = PlayGamesAvailability.permissionDenied;
      expect(await coordinator.requestFriendsConsent(), isFalse);
      expect(coordinator.friendsConsentState, FriendsConsentState.denied);
      expect(store.value['friendsConsent'], FriendsConsentState.denied.name);
      service.consentAvailability = PlayGamesAvailability.available;
      expect(await coordinator.requestFriendsConsent(), isTrue);
      expect(coordinator.friendsConsentState, FriendsConsentState.granted);
    });
  });

  test('unsupported service is a safe no-op', () async {
    const service = UnsupportedPlayGamesService();
    expect(
      (await service.initialize()).availability,
      PlayGamesAvailability.unsupportedPlatform,
    );
    expect(await service.isAuthenticated(), isFalse);
  });

  test('production Play Games resource IDs are configured centrally', () {
    expect(PlayGamesIds.gameProjectId, '293539263998');
    expect(PlayGamesIds.leaderboardsConfigured, isTrue);
    expect(
      PlayGamesIds.idFor(AuraLeaderboard.weeklyAura),
      'CgkI_uu2wsUIEAIQAQ',
    );
    expect(
      PlayGamesIds.idFor(AuraLeaderboard.maxAuraPerSecond),
      'CgkI_uu2wsUIEAIQAg',
    );
    expect(
      PlayGamesIds.idFor(AuraLeaderboard.maxAuraPerMovement),
      'CgkI_uu2wsUIEAIQAw',
    );
  });

  test('completed manual movement persists its personal record', () async {
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({
        'total': '0',
        'available': '0',
        'journey': '0',
        'remainder': '0',
        'multiplier': '100',
      }),
    });
    final controller = await GameController.loadForTesting();
    controller.tap();
    controller.tap();
    expect(controller.cycles, 1);
    expect(controller.maxAuraPerMovement, BigInt.one);
    controller.dispose();
  });
}

AuraProgressSnapshot snapshot({
  int total = 100,
  int aps = 0,
  int movement = 0,
  int manual = 0,
  int items = 0,
  int prestiges = 0,
  int restoration = 0,
}) =>
    AuraProgressSnapshot(
      totalAura: BigInt.from(total),
      auraPerSecond: BigInt.from(aps),
      maxAuraPerMovement: BigInt.from(movement),
      manualActions: manual,
      itemsUnlocked: items,
      prestiges: prestiges,
      restorationRevision: restoration,
    );

class MemoryPlayGamesStore implements PlayGamesStore {
  MemoryPlayGamesStore([Map<String, dynamic>? initial])
      : value = initial ?? <String, dynamic>{};

  Map<String, dynamic> value;

  @override
  Future<Map<String, dynamic>> read() async => Map<String, dynamic>.from(value);

  @override
  Future<void> write(Map<String, dynamic> state) async {
    value = Map<String, dynamic>.from(state);
  }
}

class FakePlayGamesService implements PlayGamesService {
  bool authenticated = true;
  PlayGamesAvailability initialization = PlayGamesAvailability.available;
  final Map<AuraLeaderboard, BigInt> submittedScores = {};
  final List<GameStatsDelta> statsDeltas = [];
  int scoreCalls = 0;
  PlayGamesAvailability friendsAvailability = PlayGamesAvailability.available;
  PlayGamesAvailability consentAvailability = PlayGamesAvailability.available;

  @override
  Future<PlayGamesOperationResult> initialize() async =>
      PlayGamesOperationResult(initialization);

  @override
  Future<bool> isAuthenticated() async => authenticated;

  @override
  Future<PlayGamesPlayer?> loadCurrentPlayer() async => authenticated
      ? const PlayGamesPlayer(playerId: 'me', displayName: 'Player')
      : null;

  @override
  Future<PlayGamesOperationResult> signIn() async {
    authenticated = true;
    return const PlayGamesOperationResult.available();
  }

  @override
  Future<PlayGamesOperationResult> submitLeaderboardScore(
    AuraLeaderboard leaderboard,
    BigInt value,
  ) async {
    scoreCalls++;
    submittedScores[leaderboard] = value;
    return const PlayGamesOperationResult.available();
  }

  @override
  Future<PlayGamesOperationResult> recordGameStatsDelta(
    String eventId,
    GameStatsDelta delta,
  ) async {
    statsDeltas.add(delta);
    return const PlayGamesOperationResult.available();
  }

  @override
  Future<PlayGamesOperationResult> recordProgressUpdate(
    String eventId,
    AuraProgress progress,
  ) async =>
      const PlayGamesOperationResult.available();

  @override
  Future<PlayGamesOperationResult> requestEventsUpload() async =>
      const PlayGamesOperationResult.available();

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required AuraLeaderboard leaderboard,
    required LeaderboardTimeScope timeScope,
    required LeaderboardPlayerScope playerScope,
    bool forceReload = false,
  }) async =>
      const LeaderboardPage(entries: []);

  @override
  Future<FriendsPage> loadFriends({bool forceReload = false}) async =>
      friendsAvailability == PlayGamesAvailability.available
          ? const FriendsPage(friends: [])
          : FriendsPage.unavailable(friendsAvailability);

  @override
  Future<PlayGamesOperationResult> requestFriendsConsent() async =>
      PlayGamesOperationResult(consentAvailability);

  @override
  Future<PlayGamesOperationResult> showCompareProfile({
    required String playerId,
    String? otherPlayerInGameName,
    String? currentPlayerInGameName,
  }) async =>
      const PlayGamesOperationResult.available();

  @override
  Future<PlayGamesOperationResult> showNativeLeaderboard(
    AuraLeaderboard leaderboard,
  ) async =>
      const PlayGamesOperationResult.available();
}
