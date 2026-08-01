import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:aura_shift_six_seven/cloud_save/cloud_game_save_repository.dart';
import 'package:aura_shift_six_seven/cloud_save/cloud_save_coordinator.dart';
import 'package:aura_shift_six_seven/cloud_save/cloud_save_envelope.dart';
import 'package:aura_shift_six_seven/cloud_save/game_save_migration_service.dart';
import 'package:aura_shift_six_seven/cloud_save/local_game_save_repository.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/play_games/play_games_models.dart';
import 'package:aura_shift_six_seven/play_games/play_games_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> validGameState({
  int total = 0,
  int? available,
  int? journey,
  int cycles = 0,
  int ascensions = 0,
  int totalPlayTimeMillis = 0,
  List<String> appearances = const <String>[],
  Map<String, int> levels = const <String, int>{},
}) =>
    const GameSaveMigrationService().migrate(<String, dynamic>{
      'available': '${available ?? total}',
      'total': '$total',
      'journey': '${journey ?? total}',
      'remainder': '0',
      'multiplier': '100',
      'ascensionAura': '0',
      'maxAuraPerMovement': '0',
      'cycles': cycles,
      'ascensions': ascensions,
      'totalPlayTimeMillis': totalPlayTimeMillis,
      'levels': levels,
      'achievements': <String>[],
      'appearances': appearances,
      'equippedAppearances': <String>[],
      'transformations': <String>[],
      'seals': <String>[],
    });

CloudSaveEnvelope envelopeFor({
  required Map<String, dynamic> state,
  int revision = 1,
  String installationId = 'installation-test',
  String saveId = 'save-test',
  String? parentPayloadHash,
  DateTime? savedAtUtc,
  Duration? totalPlayTime,
}) {
  final at = savedAtUtc ?? DateTime.utc(2026, 7, 27, 12);
  return const GameSaveCodec().create(
    saveId: saveId,
    revision: revision,
    installationId: installationId,
    parentPayloadHash: parentPayloadHash,
    savedAtUtc: at,
    lastActiveAtUtc: at,
    totalPlayTime: totalPlayTime ??
        Duration(
          milliseconds: state['totalPlayTimeMillis'] as int? ?? 0,
        ),
    gameState: state,
  );
}

CloudRemoteData remoteDataFor(CloudSaveEnvelope envelope) {
  const codec = GameSaveCodec();
  return CloudRemoteData(
    CloudRemoteSnapshot(
      payload: codec.encode(envelope),
      metadata: CloudRemoteMetadata(
        deviceName: 'Test device',
        lastModifiedAt: envelope.savedAtUtc,
        playedTime: envelope.totalPlayTime,
      ),
    ),
  );
}

class CloudSaveHarness {
  CloudSaveHarness({
    required this.controller,
    required this.local,
    required this.cloud,
    required this.playGames,
    required this.coordinator,
  });

  final GameController controller;
  final LocalGameSaveRepository local;
  final FakeCloudGameSaveRepository cloud;
  final FakeCloudPlayGamesService playGames;
  final CloudSaveCoordinator coordinator;

  static Future<CloudSaveHarness> create({
    Map<String, dynamic>? gameState,
    Map<String, Object>? preferences,
    FakeCloudGameSaveRepository? cloud,
    FakeCloudPlayGamesService? playGames,
    Duration syncInterval = const Duration(milliseconds: 10),
    Duration operationTimeout = const Duration(milliseconds: 100),
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (gameState != null) 'save-v1': jsonEncode(gameState),
      ...?preferences,
    });
    final prefs = await SharedPreferences.getInstance();
    final controller =
        await GameController.loadForTesting(deferOfflineProgress: true);
    final local = LocalGameSaveRepository(
      controller: controller,
      preferences: prefs,
    );
    final cloudRepository = cloud ?? FakeCloudGameSaveRepository();
    final playGamesService = playGames ?? FakeCloudPlayGamesService();
    final coordinator = CloudSaveCoordinator(
      controller: controller,
      localRepository: local,
      cloudRepository: cloudRepository,
      playGamesService: playGamesService,
      clock: () => DateTime.utc(2026, 7, 27, 12),
      syncInterval: syncInterval,
      operationTimeout: operationTimeout,
    );
    return CloudSaveHarness(
      controller: controller,
      local: local,
      cloud: cloudRepository,
      playGames: playGamesService,
      coordinator: coordinator,
    );
  }

  void dispose() {
    coordinator.dispose();
    controller.dispose();
  }
}

class FakeCloudGameSaveRepository implements CloudGameSaveRepository {
  FakeCloudGameSaveRepository({
    this.supported = true,
    this.openResult = const CloudRemoteMissing(),
  });

  @override
  final bool supported;
  CloudRemoteResult openResult;
  CloudRepositoryException? openError;
  Completer<CloudRemoteResult>? blockedOpen;
  Completer<void>? blockedCommit;
  int openCalls = 0;
  int commitCalls = 0;
  int resolveCalls = 0;
  int abandonCalls = 0;
  int activeOperations = 0;
  int maximumConcurrentOperations = 0;
  final List<Uint8List> committedPayloads = <Uint8List>[];
  final List<String> resolvedTokens = <String>[];

  @override
  Future<int> maximumPayloadBytes() async => cloudSaveMaximumBytes;

  @override
  Future<CloudRemoteResult> open() async {
    openCalls += 1;
    activeOperations += 1;
    if (activeOperations > maximumConcurrentOperations) {
      maximumConcurrentOperations = activeOperations;
    }
    try {
      final error = openError;
      if (error != null) throw error;
      final blocker = blockedOpen;
      return blocker == null ? openResult : await blocker.future;
    } finally {
      activeOperations -= 1;
    }
  }

  @override
  Future<CloudRemoteResult> commit({
    required Uint8List payload,
    required String description,
    required Duration playedTime,
    required int progressValue,
  }) async {
    commitCalls += 1;
    activeOperations += 1;
    if (activeOperations > maximumConcurrentOperations) {
      maximumConcurrentOperations = activeOperations;
    }
    try {
      final blocker = blockedCommit;
      if (blocker != null) await blocker.future;
      committedPayloads.add(Uint8List.fromList(payload));
      return CloudRemoteData(
        CloudRemoteSnapshot(
          payload: Uint8List.fromList(payload),
          metadata: CloudRemoteMetadata(
            description: description,
            playedTime: playedTime,
            progressValue: progressValue,
          ),
        ),
      );
    } finally {
      activeOperations -= 1;
    }
  }

  @override
  Future<CloudRemoteResult> resolveConflict({
    required String token,
    required Uint8List payload,
    required String description,
    required Duration playedTime,
    required int progressValue,
  }) async {
    resolveCalls += 1;
    resolvedTokens.add(token);
    return CloudRemoteData(
      CloudRemoteSnapshot(
        payload: Uint8List.fromList(payload),
        metadata: CloudRemoteMetadata(
          description: description,
          playedTime: playedTime,
          progressValue: progressValue,
        ),
      ),
    );
  }

  @override
  Future<void> abandonConflict(String token) async {
    abandonCalls += 1;
  }
}

class FakeCloudPlayGamesService implements PlayGamesService {
  FakeCloudPlayGamesService({
    this.initializeResult = const PlayGamesOperationResult.available(),
    this.signInResult = const PlayGamesOperationResult.available(),
    this.authenticated = true,
    this.player = const PlayGamesPlayer(
      playerId: 'player-test',
      displayName: 'Player Test',
    ),
  });

  PlayGamesOperationResult initializeResult;
  PlayGamesOperationResult signInResult;
  bool authenticated;
  PlayGamesPlayer? player;
  Completer<PlayGamesOperationResult>? blockedInitialization;
  int initializeCalls = 0;
  int signInCalls = 0;

  @override
  Future<PlayGamesOperationResult> initialize() async {
    initializeCalls += 1;
    final blocker = blockedInitialization;
    return blocker == null ? initializeResult : blocker.future;
  }

  @override
  Future<PlayGamesOperationResult> signIn() async {
    signInCalls += 1;
    return signInResult;
  }

  @override
  Future<bool> isAuthenticated() async => authenticated;

  @override
  Future<PlayGamesPlayer?> loadCurrentPlayer() async => player;

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required AuraLeaderboard leaderboard,
    required LeaderboardTimeScope timeScope,
    required LeaderboardPlayerScope playerScope,
    bool forceReload = false,
  }) async =>
      const LeaderboardPage(entries: <LeaderboardEntry>[]);

  @override
  Future<FriendsPage> loadFriends({bool forceReload = false}) async =>
      const FriendsPage(friends: <PlayGamesFriend>[]);

  @override
  Future<PlayGamesOperationResult> recordGameStatsDelta(
    String eventId,
    GameStatsDelta delta,
  ) async =>
      const PlayGamesOperationResult.available();

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
  Future<PlayGamesOperationResult> requestFriendsConsent() async =>
      const PlayGamesOperationResult.available();

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

  @override
  Future<PlayGamesOperationResult> submitLeaderboardScore(
    AuraLeaderboard leaderboard,
    BigInt value,
  ) async =>
      const PlayGamesOperationResult.available();
}
