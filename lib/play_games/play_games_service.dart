import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'aura_leaderboard_score_codec.dart';
import 'play_games_ids.dart';
import 'play_games_models.dart';

abstract interface class PlayGamesService {
  Future<PlayGamesOperationResult> initialize();
  Future<PlayGamesOperationResult> signIn();
  Future<bool> isAuthenticated();
  Future<PlayGamesPlayer?> loadCurrentPlayer();
  Future<PlayGamesOperationResult> submitLeaderboardScore(
    AuraLeaderboard leaderboard,
    BigInt value,
  );
  Future<LeaderboardPage> loadLeaderboard({
    required AuraLeaderboard leaderboard,
    required LeaderboardTimeScope timeScope,
    required LeaderboardPlayerScope playerScope,
    bool forceReload = false,
  });
  Future<PlayGamesOperationResult> showNativeLeaderboard(
    AuraLeaderboard leaderboard,
  );
  Future<FriendsPage> loadFriends({bool forceReload = false});
  Future<PlayGamesOperationResult> requestFriendsConsent();
  Future<PlayGamesOperationResult> showCompareProfile({
    required String playerId,
    String? otherPlayerInGameName,
    String? currentPlayerInGameName,
  });
  Future<PlayGamesOperationResult> recordGameStatsDelta(
    String eventId,
    GameStatsDelta delta,
  );
  Future<PlayGamesOperationResult> recordProgressUpdate(
    String eventId,
    AuraProgress progress,
  );
  Future<PlayGamesOperationResult> requestEventsUpload();
}

PlayGamesService createPlayGamesService() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const UnsupportedPlayGamesService();
  }
  return MethodChannelPlayGamesService();
}

class UnsupportedPlayGamesService implements PlayGamesService {
  const UnsupportedPlayGamesService();

  static const _unsupported = PlayGamesOperationResult(
    PlayGamesAvailability.unsupportedPlatform,
  );

  @override
  Future<PlayGamesOperationResult> initialize() async => _unsupported;

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<PlayGamesPlayer?> loadCurrentPlayer() async => null;

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required AuraLeaderboard leaderboard,
    required LeaderboardTimeScope timeScope,
    required LeaderboardPlayerScope playerScope,
    bool forceReload = false,
  }) async =>
      const LeaderboardPage.unavailable(
        PlayGamesAvailability.unsupportedPlatform,
      );

  @override
  Future<FriendsPage> loadFriends({bool forceReload = false}) async =>
      const FriendsPage.unavailable(
        PlayGamesAvailability.unsupportedPlatform,
      );

  @override
  Future<PlayGamesOperationResult> recordGameStatsDelta(
    String eventId,
    GameStatsDelta delta,
  ) async =>
      _unsupported;

  @override
  Future<PlayGamesOperationResult> recordProgressUpdate(
    String eventId,
    AuraProgress progress,
  ) async =>
      _unsupported;

  @override
  Future<PlayGamesOperationResult> requestEventsUpload() async => _unsupported;

  @override
  Future<PlayGamesOperationResult> requestFriendsConsent() async =>
      _unsupported;

  @override
  Future<PlayGamesOperationResult> showCompareProfile({
    required String playerId,
    String? otherPlayerInGameName,
    String? currentPlayerInGameName,
  }) async =>
      _unsupported;

  @override
  Future<PlayGamesOperationResult> showNativeLeaderboard(
    AuraLeaderboard leaderboard,
  ) async =>
      _unsupported;

  @override
  Future<PlayGamesOperationResult> signIn() async => _unsupported;

  @override
  Future<PlayGamesOperationResult> submitLeaderboardScore(
    AuraLeaderboard leaderboard,
    BigInt value,
  ) async =>
      _unsupported;
}

class MethodChannelPlayGamesService implements PlayGamesService {
  MethodChannelPlayGamesService({
    MethodChannel channel = const MethodChannel(
      'com.otaciliomaia.aurashiftsixseven/play_games',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<PlayGamesOperationResult> initialize() => _operation('initialize');

  @override
  Future<PlayGamesOperationResult> signIn() => _operation('signIn');

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await _channel.invokeMethod<bool>('isAuthenticated') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<PlayGamesPlayer?> loadCurrentPlayer() async {
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'loadCurrentPlayer',
      );
      return raw == null ? null : PlayGamesPlayer.fromMap(raw);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<PlayGamesOperationResult> submitLeaderboardScore(
    AuraLeaderboard leaderboard,
    BigInt value,
  ) async {
    final id = PlayGamesIds.idFor(leaderboard);
    if (id.isEmpty) {
      return const PlayGamesOperationResult(
        PlayGamesAvailability.notConfigured,
      );
    }
    final encoded = AuraLeaderboardScoreCodec.encode(value);
    return _operation('submitScore', {
      'leaderboardId': id,
      'score': encoded,
      'scoreTag': 'aura-score-codec-v1',
    });
  }

  @override
  Future<LeaderboardPage> loadLeaderboard({
    required AuraLeaderboard leaderboard,
    required LeaderboardTimeScope timeScope,
    required LeaderboardPlayerScope playerScope,
    bool forceReload = false,
  }) async {
    final id = PlayGamesIds.idFor(leaderboard);
    if (id.isEmpty) {
      return const LeaderboardPage.unavailable(
        PlayGamesAvailability.notConfigured,
      );
    }
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'loadLeaderboard',
        {
          'leaderboardId': id,
          'timeScope': timeScope.name,
          'playerScope': playerScope.name,
          'forceReload': forceReload,
        },
      );
      if (raw == null) {
        return const LeaderboardPage.unavailable(
          PlayGamesAvailability.temporarilyUnavailable,
        );
      }
      final entries = <LeaderboardEntry>[];
      for (final value in (raw['entries'] as List? ?? const [])) {
        if (value is! Map) continue;
        final entry = value.cast<Object?, Object?>();
        final encoded = (entry['score'] as num?)?.toInt();
        entries.add(LeaderboardEntry(
          playerId: '${entry['playerId'] ?? ''}',
          displayName: '${entry['displayName'] ?? ''}',
          avatarUrl: _nullableString(entry['avatarUrl']),
          avatarBytes: entry['avatarBytes'] as Uint8List?,
          rank: (entry['rank'] as num?)?.toInt(),
          encodedScore: encoded,
          auraValue: encoded == null
              ? null
              : AuraLeaderboardScoreCodec.decodeApproximate(encoded),
          isCurrentPlayer: entry['isCurrentPlayer'] == true,
        ));
      }
      final current =
          entries.where((entry) => entry.isCurrentPlayer).firstOrNull;
      return LeaderboardPage(
        entries: List.unmodifiable(entries),
        currentPlayer: current,
      );
    } on PlatformException catch (error) {
      return LeaderboardPage.unavailable(
        _availabilityForCode(error.code),
        message: error.message,
      );
    } on MissingPluginException {
      return const LeaderboardPage.unavailable(
        PlayGamesAvailability.unsupportedPlatform,
      );
    }
  }

  @override
  Future<PlayGamesOperationResult> showNativeLeaderboard(
    AuraLeaderboard leaderboard,
  ) {
    final id = PlayGamesIds.idFor(leaderboard);
    if (id.isEmpty) {
      return Future.value(const PlayGamesOperationResult(
        PlayGamesAvailability.notConfigured,
      ));
    }
    return _operation('showNativeLeaderboard', {'leaderboardId': id});
  }

  @override
  Future<FriendsPage> loadFriends({bool forceReload = false}) async {
    try {
      final raw = await _channel.invokeListMethod<Object?>(
            'loadFriends',
            {'pageSize': 25, 'forceReload': forceReload},
          ) ??
          const [];
      return FriendsPage(
        friends: List.unmodifiable([
          for (final item in raw)
            if (item is Map)
              PlayGamesFriend.fromMap(item.cast<Object?, Object?>()),
        ]),
      );
    } on PlatformException catch (error) {
      return FriendsPage.unavailable(
        _availabilityForCode(error.code),
        message: error.message,
      );
    } on MissingPluginException {
      return const FriendsPage.unavailable(
        PlayGamesAvailability.unsupportedPlatform,
      );
    }
  }

  @override
  Future<PlayGamesOperationResult> requestFriendsConsent() =>
      _operation('requestFriendsConsent');

  @override
  Future<PlayGamesOperationResult> showCompareProfile({
    required String playerId,
    String? otherPlayerInGameName,
    String? currentPlayerInGameName,
  }) =>
      _operation('showCompareProfile', {
        'playerId': playerId,
        if (otherPlayerInGameName != null)
          'otherPlayerInGameName': otherPlayerInGameName,
        if (currentPlayerInGameName != null)
          'currentPlayerInGameName': currentPlayerInGameName,
      });

  @override
  Future<PlayGamesOperationResult> recordGameStatsDelta(
    String eventId,
    GameStatsDelta delta,
  ) {
    if (!PlayGamesIds.gameStatsEnabled) {
      return Future.value(const PlayGamesOperationResult(
        PlayGamesAvailability.notConfigured,
      ));
    }
    return _operation('recordGameStats', {
      'eventId': eventId,
      'eventName': 'auraActivityDelta',
      'properties': {
        'auraEarnedDelta': _safeDouble(delta.auraEarnedDelta),
        'manualActionsDelta': delta.manualActionsDelta,
        'maxAuraPerSecond':
            AuraLeaderboardScoreCodec.encode(delta.maxAuraPerSecond),
        'prestigesDelta': delta.prestigesDelta,
        'itemsUnlockedDelta': delta.itemsUnlockedDelta,
      },
    });
  }

  @override
  Future<PlayGamesOperationResult> recordProgressUpdate(
    String eventId,
    AuraProgress progress,
  ) {
    if (!PlayGamesIds.gameStatsEnabled) {
      return Future.value(const PlayGamesOperationResult(
        PlayGamesAvailability.notConfigured,
      ));
    }
    return _operation('recordGameStats', {
      'eventId': eventId,
      'eventName': 'progressUpdate',
      'properties': progress.toMap(),
    });
  }

  @override
  Future<PlayGamesOperationResult> requestEventsUpload() {
    if (!PlayGamesIds.gameStatsEnabled) {
      return Future.value(const PlayGamesOperationResult(
        PlayGamesAvailability.notConfigured,
      ));
    }
    return _operation('requestEventsUpload');
  }

  Future<PlayGamesOperationResult> _operation(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
      return const PlayGamesOperationResult.available();
    } on PlatformException catch (error) {
      return PlayGamesOperationResult(
        _availabilityForCode(error.code),
        message: error.message,
      );
    } on MissingPluginException {
      return const PlayGamesOperationResult(
        PlayGamesAvailability.unsupportedPlatform,
      );
    }
  }

  static PlayGamesAvailability _availabilityForCode(String code) =>
      switch (code) {
        'not_configured' => PlayGamesAvailability.notConfigured,
        'unauthenticated' => PlayGamesAvailability.unauthenticated,
        'consent_required' => PlayGamesAvailability.consentRequired,
        'permission_denied' => PlayGamesAvailability.permissionDenied,
        'offline' => PlayGamesAvailability.offline,
        'unsupported' => PlayGamesAvailability.unsupportedPlatform,
        _ => PlayGamesAvailability.temporarilyUnavailable,
      };
}

double _safeDouble(BigInt value) {
  final parsed = double.tryParse(value.toString());
  if (parsed == null || !parsed.isFinite) return double.maxFinite;
  return parsed;
}

String? _nullableString(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}
