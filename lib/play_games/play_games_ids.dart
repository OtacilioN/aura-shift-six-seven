import 'play_games_models.dart';

abstract final class PlayGamesIds {
  static const gameProjectId = String.fromEnvironment(
    'PGS_GAME_PROJECT_ID',
    defaultValue: '293539263998',
  );
  static const weeklyAuraLeaderboard = String.fromEnvironment(
    'PGS_WEEKLY_AURA_LEADERBOARD_ID',
    defaultValue: 'CgkI_uu2wsUIEAIQAQ',
  );
  static const maxAuraPerSecondLeaderboard = String.fromEnvironment(
    'PGS_MAX_APS_LEADERBOARD_ID',
    defaultValue: 'CgkI_uu2wsUIEAIQAg',
  );
  static const maxAuraPerMovementLeaderboard = String.fromEnvironment(
    'PGS_MAX_MOVEMENT_LEADERBOARD_ID',
    defaultValue: 'CgkI_uu2wsUIEAIQAw',
  );
  static const gameStatsEnabled = bool.fromEnvironment(
    'PGS_GAME_STATS_ENABLED',
    defaultValue: false,
  );

  static bool get leaderboardsConfigured =>
      weeklyAuraLeaderboard.isNotEmpty &&
      maxAuraPerSecondLeaderboard.isNotEmpty &&
      maxAuraPerMovementLeaderboard.isNotEmpty;

  static String idFor(AuraLeaderboard leaderboard) => switch (leaderboard) {
        AuraLeaderboard.weeklyAura => weeklyAuraLeaderboard,
        AuraLeaderboard.maxAuraPerSecond => maxAuraPerSecondLeaderboard,
        AuraLeaderboard.maxAuraPerMovement => maxAuraPerMovementLeaderboard,
      };
}
