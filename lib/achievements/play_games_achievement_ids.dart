import 'achievement_models.dart';

abstract final class PlayGamesAchievementIds {
  static const _values = <AuraAchievement, String>{
    AuraAchievement.firstMovement: String.fromEnvironment(
      'PGS_ACHIEVEMENT_FIRST_MOVEMENT',
      defaultValue: 'CgkI_uu2wsUIEAIQDw',
    ),
    AuraAchievement.firstSix: String.fromEnvironment(
      'PGS_ACHIEVEMENT_FIRST_SIX',
      defaultValue: 'CgkI_uu2wsUIEAIQBA',
    ),
    AuraAchievement.firstSeven: String.fromEnvironment(
      'PGS_ACHIEVEMENT_FIRST_SEVEN',
      defaultValue: 'CgkI_uu2wsUIEAIQEg',
    ),
    AuraAchievement.sixSeven: String.fromEnvironment(
      'PGS_ACHIEVEMENT_SIX_SEVEN',
      defaultValue: 'CgkI_uu2wsUIEAIQBQ',
    ),
    AuraAchievement.firstPurchase: String.fromEnvironment(
      'PGS_ACHIEVEMENT_FIRST_PURCHASE',
      defaultValue: 'CgkI_uu2wsUIEAIQDg',
    ),
    AuraAchievement.firstAutomaticProduction: String.fromEnvironment(
      'PGS_ACHIEVEMENT_FIRST_AUTOMATIC_PRODUCTION',
      defaultValue: 'CgkI_uu2wsUIEAIQDA',
    ),
    AuraAchievement.firstOfflineReward: String.fromEnvironment(
      'PGS_ACHIEVEMENT_FIRST_OFFLINE_REWARD',
      defaultValue: 'CgkI_uu2wsUIEAIQHA',
    ),
    AuraAchievement.manualMovements100: String.fromEnvironment(
      'PGS_ACHIEVEMENT_MANUAL_MOVEMENTS_100',
      defaultValue: 'CgkI_uu2wsUIEAIQFg',
    ),
    AuraAchievement.manualMovements1000: String.fromEnvironment(
      'PGS_ACHIEVEMENT_MANUAL_MOVEMENTS_1000',
      defaultValue: 'CgkI_uu2wsUIEAIQHQ',
    ),
    AuraAchievement.manualMovements10000: String.fromEnvironment(
      'PGS_ACHIEVEMENT_MANUAL_MOVEMENTS_10000',
      defaultValue: 'CgkI_uu2wsUIEAIQEw',
    ),
    AuraAchievement.totalAura1000: String.fromEnvironment(
      'PGS_ACHIEVEMENT_TOTAL_AURA_1000',
      defaultValue: 'CgkI_uu2wsUIEAIQEA',
    ),
    AuraAchievement.totalAura1Million: String.fromEnvironment(
      'PGS_ACHIEVEMENT_TOTAL_AURA_1_MILLION',
      defaultValue: 'CgkI_uu2wsUIEAIQCA',
    ),
    AuraAchievement.totalAura1Billion: String.fromEnvironment(
      'PGS_ACHIEVEMENT_TOTAL_AURA_1_BILLION',
      defaultValue: 'CgkI_uu2wsUIEAIQBw',
    ),
    AuraAchievement.totalAura1Trillion: String.fromEnvironment(
      'PGS_ACHIEVEMENT_TOTAL_AURA_1_TRILLION',
      defaultValue: 'CgkI_uu2wsUIEAIQFw',
    ),
    AuraAchievement.totalAura1Quintillion: String.fromEnvironment(
      'PGS_ACHIEVEMENT_TOTAL_AURA_1_QUINTILLION',
      defaultValue: 'CgkI_uu2wsUIEAIQGA',
    ),
    AuraAchievement.tenItems: String.fromEnvironment(
      'PGS_ACHIEVEMENT_TEN_ITEMS',
      defaultValue: 'CgkI_uu2wsUIEAIQCw',
    ),
    AuraAchievement.originalItemCatalog: String.fromEnvironment(
      'PGS_ACHIEVEMENT_ORIGINAL_ITEM_CATALOG',
      defaultValue: 'CgkI_uu2wsUIEAIQFA',
    ),
    AuraAchievement.fiveCharacters: String.fromEnvironment(
      'PGS_ACHIEVEMENT_FIVE_CHARACTERS',
      defaultValue: 'CgkI_uu2wsUIEAIQGQ',
    ),
    AuraAchievement.originalCharacterRoster: String.fromEnvironment(
      'PGS_ACHIEVEMENT_ORIGINAL_CHARACTER_ROSTER',
      defaultValue: 'CgkI_uu2wsUIEAIQCQ',
    ),
    AuraAchievement.maximumAuraState: String.fromEnvironment(
      'PGS_ACHIEVEMENT_MAXIMUM_AURA_STATE',
      defaultValue: 'CgkI_uu2wsUIEAIQGg',
    ),
    AuraAchievement.fortyTwo: String.fromEnvironment(
      'PGS_ACHIEVEMENT_FORTY_TWO',
      defaultValue: 'CgkI_uu2wsUIEAIQFQ',
    ),
    AuraAchievement.sevenDistinctDays: String.fromEnvironment(
      'PGS_ACHIEVEMENT_SEVEN_DISTINCT_DAYS',
      defaultValue: 'CgkI_uu2wsUIEAIQCg',
    ),
    AuraAchievement.thirtyDistinctDays: String.fromEnvironment(
      'PGS_ACHIEVEMENT_THIRTY_DISTINCT_DAYS',
      defaultValue: 'CgkI_uu2wsUIEAIQDQ',
    ),
    AuraAchievement.auraPerSecond67: String.fromEnvironment(
      'PGS_ACHIEVEMENT_AURA_PER_SECOND_67',
      defaultValue: 'CgkI_uu2wsUIEAIQEQ',
    ),
    AuraAchievement.auraPerSecond1Million: String.fromEnvironment(
      'PGS_ACHIEVEMENT_AURA_PER_SECOND_1_MILLION',
      defaultValue: 'CgkI_uu2wsUIEAIQGw',
    ),
    AuraAchievement.singleMovement1Million: String.fromEnvironment(
      'PGS_ACHIEVEMENT_SINGLE_MOVEMENT_1_MILLION',
      defaultValue: 'CgkI_uu2wsUIEAIQBg',
    ),
  };

  static String idFor(AuraAchievement achievement) =>
      _values[achievement] ?? '';

  static AuraAchievement? achievementForId(String id) {
    for (final entry in _values.entries) {
      if (entry.value.isNotEmpty && entry.value == id) return entry.key;
    }
    return null;
  }

  static bool get anyConfigured =>
      _values.values.any((value) => value.isNotEmpty);
  static bool get allConfigured =>
      _values.values.every((value) => value.isNotEmpty);
  static int get configuredCount =>
      _values.values.where((value) => value.isNotEmpty).length;
}
