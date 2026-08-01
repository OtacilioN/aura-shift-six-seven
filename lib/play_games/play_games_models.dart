import 'dart:math' as math;
import 'dart:typed_data';

enum PlayGamesAvailability {
  available,
  unsupportedPlatform,
  notConfigured,
  unauthenticated,
  permissionDenied,
  consentRequired,
  offline,
  temporarilyUnavailable,
}

enum AuraLeaderboard { weeklyAura, maxAuraPerSecond, maxAuraPerMovement }

enum LeaderboardTimeScope { daily, weekly, allTime }

enum LeaderboardPlayerScope { global, friends }

enum FriendsConsentState { unknown, required, granted, denied }

class PlayGamesOperationResult {
  const PlayGamesOperationResult(this.availability, {this.message});

  const PlayGamesOperationResult.available()
      : availability = PlayGamesAvailability.available,
        message = null;

  final PlayGamesAvailability availability;
  final String? message;

  bool get succeeded => availability == PlayGamesAvailability.available;
}

class PlayGamesPlayer {
  const PlayGamesPlayer({
    required this.playerId,
    required this.displayName,
    this.avatarUrl,
    this.avatarBytes,
  });

  factory PlayGamesPlayer.fromMap(Map<Object?, Object?> map) => PlayGamesPlayer(
        playerId: '${map['playerId'] ?? ''}',
        displayName: '${map['displayName'] ?? ''}',
        avatarUrl: _nullableString(map['avatarUrl']),
        avatarBytes: map['avatarBytes'] as Uint8List?,
      );

  final String playerId;
  final String displayName;
  final String? avatarUrl;
  final Uint8List? avatarBytes;
}

class PlayGamesFriend extends PlayGamesPlayer {
  const PlayGamesFriend({
    required super.playerId,
    required super.displayName,
    super.avatarUrl,
    super.avatarBytes,
  });

  factory PlayGamesFriend.fromMap(Map<Object?, Object?> map) => PlayGamesFriend(
        playerId: '${map['playerId'] ?? ''}',
        displayName: '${map['displayName'] ?? ''}',
        avatarUrl: _nullableString(map['avatarUrl']),
        avatarBytes: map['avatarBytes'] as Uint8List?,
      );
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerId,
    required this.displayName,
    required this.rank,
    required this.encodedScore,
    required this.auraValue,
    this.avatarUrl,
    this.avatarBytes,
    this.isCurrentPlayer = false,
    this.hasScore = true,
  });

  final String playerId;
  final String displayName;
  final int? rank;
  final int? encodedScore;
  final BigInt? auraValue;
  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final bool isCurrentPlayer;
  final bool hasScore;
}

class LeaderboardPage {
  const LeaderboardPage({
    required this.entries,
    this.currentPlayer,
    this.availability = PlayGamesAvailability.available,
    this.message,
  });

  const LeaderboardPage.unavailable(
    this.availability, {
    this.message,
  })  : entries = const [],
        currentPlayer = null;

  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? currentPlayer;
  final PlayGamesAvailability availability;
  final String? message;
}

class FriendsPage {
  const FriendsPage({
    required this.friends,
    this.availability = PlayGamesAvailability.available,
    this.message,
  });

  const FriendsPage.unavailable(
    this.availability, {
    this.message,
  }) : friends = const [];

  final List<PlayGamesFriend> friends;
  final PlayGamesAvailability availability;
  final String? message;
}

class GameStatsDelta {
  GameStatsDelta({
    BigInt? auraEarnedDelta,
    this.manualActionsDelta = 0,
    BigInt? maxAuraPerSecond,
    this.prestigesDelta = 0,
    this.itemsUnlockedDelta = 0,
  })  : auraEarnedDelta = auraEarnedDelta ?? BigInt.zero,
        maxAuraPerSecond = maxAuraPerSecond ?? BigInt.zero;

  factory GameStatsDelta.fromJson(Map<String, dynamic> json) => GameStatsDelta(
        auraEarnedDelta:
            BigInt.tryParse('${json['auraEarnedDelta'] ?? 0}') ?? BigInt.zero,
        manualActionsDelta: _safeInt(json['manualActionsDelta']),
        maxAuraPerSecond:
            BigInt.tryParse('${json['maxAuraPerSecond'] ?? 0}') ?? BigInt.zero,
        prestigesDelta: _safeInt(json['prestigesDelta']),
        itemsUnlockedDelta: _safeInt(json['itemsUnlockedDelta']),
      );

  final BigInt auraEarnedDelta;
  final int manualActionsDelta;
  final BigInt maxAuraPerSecond;
  final int prestigesDelta;
  final int itemsUnlockedDelta;

  bool get isEmpty =>
      auraEarnedDelta == BigInt.zero &&
      manualActionsDelta == 0 &&
      maxAuraPerSecond == BigInt.zero &&
      prestigesDelta == 0 &&
      itemsUnlockedDelta == 0;

  GameStatsDelta merge(GameStatsDelta other) => GameStatsDelta(
        auraEarnedDelta: auraEarnedDelta + other.auraEarnedDelta,
        manualActionsDelta: manualActionsDelta + other.manualActionsDelta,
        maxAuraPerSecond: maxAuraPerSecond > other.maxAuraPerSecond
            ? maxAuraPerSecond
            : other.maxAuraPerSecond,
        prestigesDelta: prestigesDelta + other.prestigesDelta,
        itemsUnlockedDelta: itemsUnlockedDelta + other.itemsUnlockedDelta,
      );

  Map<String, dynamic> toJson() => {
        'auraEarnedDelta': auraEarnedDelta.toString(),
        'manualActionsDelta': manualActionsDelta,
        'maxAuraPerSecond': maxAuraPerSecond.toString(),
        'prestigesDelta': prestigesDelta,
        'itemsUnlockedDelta': itemsUnlockedDelta,
      };
}

class AuraProgress {
  const AuraProgress({
    required this.currentProgress,
    required this.auraTier,
  });

  final int currentProgress;
  final String auraTier;

  Map<String, Object> toMap() => {
        'currentProgress': currentProgress,
        'auraTier': auraTier,
      };
}

class AuraProgressSnapshot {
  const AuraProgressSnapshot({
    required this.totalAura,
    required this.auraPerSecond,
    required this.maxAuraPerMovement,
    required this.manualActions,
    required this.itemsUnlocked,
    required this.prestiges,
    required this.restorationRevision,
  });

  final BigInt totalAura;
  final BigInt auraPerSecond;
  final BigInt maxAuraPerMovement;
  final int manualActions;
  final int itemsUnlocked;
  final int prestiges;
  final int restorationRevision;
}

int auraProgressLevel(BigInt lifetimeAura) {
  if (lifetimeAura <= BigInt.zero) return 0;
  return math.min(lifetimeAura.toString().length, 2147483647);
}

String auraTierForLevel(int level) {
  if (level <= 0) return 'initial';
  if (level < 4) return 'awakening';
  if (level < 7) return 'flow';
  if (level < 13) return 'spectrum';
  if (level < 16) return 'legendary';
  return 'infinite';
}

List<LeaderboardEntry> mergeFriendsAndScores({
  required List<PlayGamesFriend> friends,
  required List<LeaderboardEntry> scores,
  required String? currentPlayerId,
}) {
  final scoresByPlayer = {
    for (final score in scores) score.playerId: score,
  };
  final merged = <LeaderboardEntry>[
    for (final friend in friends)
      scoresByPlayer.remove(friend.playerId) ??
          LeaderboardEntry(
            playerId: friend.playerId,
            displayName: friend.displayName,
            avatarUrl: friend.avatarUrl,
            avatarBytes: friend.avatarBytes,
            rank: null,
            encodedScore: null,
            auraValue: null,
            isCurrentPlayer: friend.playerId == currentPlayerId,
            hasScore: false,
          ),
    ...scoresByPlayer.values,
  ];
  merged.sort((left, right) {
    if (left.hasScore != right.hasScore) return left.hasScore ? -1 : 1;
    final rankComparison =
        (left.rank ?? 1 << 30).compareTo(right.rank ?? 1 << 30);
    if (rankComparison != 0) return rankComparison;
    return left.displayName.compareTo(right.displayName);
  });
  return List.unmodifiable(merged);
}

String? _nullableString(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

int _safeInt(Object? value) => value is num ? value.toInt() : 0;
