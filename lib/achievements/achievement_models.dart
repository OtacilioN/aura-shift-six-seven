import '../play_games/play_games_models.dart';

const achievementCatalogVersion = 1;

enum AuraAchievement {
  firstMovement,
  firstSix,
  firstSeven,
  sixSeven,
  firstPurchase,
  firstAutomaticProduction,
  firstOfflineReward,
  manualMovements100,
  manualMovements1000,
  manualMovements10000,
  totalAura1000,
  totalAura1Million,
  totalAura1Billion,
  totalAura1Trillion,
  totalAura1Quintillion,
  tenItems,
  originalItemCatalog,
  fiveCharacters,
  originalCharacterRoster,
  maximumAuraState,
  fortyTwo,
  sevenDistinctDays,
  thirtyDistinctDays,
  auraPerSecond67,
  auraPerSecond1Million,
  singleMovement1Million,
}

enum AchievementType { standard, incremental }

enum AchievementVisibility { revealed, hidden }

enum AchievementMetric {
  auraProducingMovements,
  sixMovements,
  sevenMovements,
  totalAura,
  purchases,
  automaticProductionSources,
  auraPerSecond,
  offlineRewardsCollected,
  manualMovements,
  unlockedItems,
  originalItemCatalog,
  unlockedCharacters,
  originalCharacterRoster,
  maximumAuraState,
  fortyTwo,
  distinctPlayDays,
  maximumAuraPerMovement,
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.key,
    required this.type,
    required this.visibility,
    required this.points,
    required this.metric,
    required this.listOrder,
    required this.namePtBr,
    required this.descriptionPtBr,
    required this.nameEnUs,
    required this.descriptionEnUs,
    this.requiredSteps,
    this.intThreshold,
    this.bigIntThreshold,
  });

  final AuraAchievement key;
  final AchievementType type;
  final AchievementVisibility visibility;
  final int points;
  final int? requiredSteps;
  final AchievementMetric metric;
  final int? intThreshold;
  final BigInt? bigIntThreshold;
  final int listOrder;
  final String namePtBr;
  final String descriptionPtBr;
  final String nameEnUs;
  final String descriptionEnUs;
}

class PlayerProgressSnapshot {
  const PlayerProgressSnapshot({
    required this.totalAura,
    required this.manualMovements,
    required this.auraProducingMovements,
    required this.sixMovements,
    required this.sevenMovements,
    required this.purchaseCount,
    required this.automaticProductionSources,
    required this.auraPerSecond,
    required this.maximumAuraPerMovement,
    required this.offlineRewardsCollected,
    required this.unlockedItemIds,
    required this.unlockedCharacterIds,
    required this.unlockedTechniqueIds,
    required this.distinctPlayDays,
    required this.maximumAuraStateId,
    required this.saveMigrated,
  });

  final BigInt totalAura;
  final int manualMovements;
  final int auraProducingMovements;
  final int sixMovements;
  final int sevenMovements;
  final int purchaseCount;
  final int automaticProductionSources;
  final BigInt auraPerSecond;
  final BigInt maximumAuraPerMovement;
  final int offlineRewardsCollected;
  final Set<String> unlockedItemIds;
  final Set<String> unlockedCharacterIds;
  final Set<String> unlockedTechniqueIds;
  final Set<String> distinctPlayDays;
  final String? maximumAuraStateId;
  final bool saveMigrated;

  bool get isValid =>
      saveMigrated &&
      !totalAura.isNegative &&
      manualMovements >= 0 &&
      auraProducingMovements >= 0 &&
      sixMovements >= 0 &&
      sevenMovements >= 0 &&
      purchaseCount >= 0 &&
      automaticProductionSources >= 0 &&
      !auraPerSecond.isNegative &&
      !maximumAuraPerMovement.isNegative &&
      offlineRewardsCollected >= 0 &&
      distinctPlayDays.every(_validLocalDateKey);
}

class AchievementEvaluation {
  const AchievementEvaluation({
    required this.standardsToUnlock,
    required this.incrementalSteps,
  });

  const AchievementEvaluation.empty()
      : standardsToUnlock = const {},
        incrementalSteps = const {};

  final Set<AuraAchievement> standardsToUnlock;
  final Map<AuraAchievement, int> incrementalSteps;
}

enum RemoteAchievementStatus { hidden, revealed, unlocked }

class RemoteAchievementState {
  const RemoteAchievementState({
    required this.id,
    required this.status,
    required this.type,
    this.currentSteps = 0,
    this.totalSteps = 0,
  });

  factory RemoteAchievementState.fromMap(Map<Object?, Object?> map) {
    final status = switch ('${map['state'] ?? ''}') {
      'hidden' => RemoteAchievementStatus.hidden,
      'unlocked' => RemoteAchievementStatus.unlocked,
      _ => RemoteAchievementStatus.revealed,
    };
    final type = '${map['type'] ?? ''}' == 'incremental'
        ? AchievementType.incremental
        : AchievementType.standard;
    return RemoteAchievementState(
      id: '${map['id'] ?? ''}',
      status: status,
      type: type,
      currentSteps: (map['currentSteps'] as num?)?.toInt() ?? 0,
      totalSteps: (map['totalSteps'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final RemoteAchievementStatus status;
  final AchievementType type;
  final int currentSteps;
  final int totalSteps;
}

class AchievementsInitializationResult {
  const AchievementsInitializationResult(this.availability, {this.message});

  final PlayGamesAvailability availability;
  final String? message;

  bool get succeeded => availability == PlayGamesAvailability.available;
}

class AchievementSyncResult {
  const AchievementSyncResult({
    required this.availability,
    this.sent = 0,
    this.pending = 0,
    this.message,
  });

  final PlayGamesAvailability availability;
  final int sent;
  final int pending;
  final String? message;

  bool get succeeded => availability == PlayGamesAvailability.available;
}

bool _validLocalDateKey(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return false;
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null || month == null || day == null) return false;
  final parsed = DateTime(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day;
}
