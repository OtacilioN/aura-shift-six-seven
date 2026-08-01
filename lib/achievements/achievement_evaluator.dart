import 'dart:math' as math;

import 'achievement_catalog.dart';
import 'achievement_models.dart';

class AchievementEvaluator {
  const AchievementEvaluator();

  AchievementEvaluation evaluateAchievements(PlayerProgressSnapshot progress) {
    if (!progress.isValid) return const AchievementEvaluation.empty();

    final standards = <AuraAchievement>{};
    final incremental = <AuraAchievement, int>{};
    for (final definition in AchievementCatalog.definitions) {
      if (definition.type == AchievementType.incremental) {
        final current = _intMetric(definition.metric, progress);
        incremental[definition.key] =
            math.min(current, definition.requiredSteps!);
      } else if (_standardReached(definition, progress)) {
        standards.add(definition.key);
      }
    }
    return AchievementEvaluation(
      standardsToUnlock: Set.unmodifiable(standards),
      incrementalSteps: Map.unmodifiable(incremental),
    );
  }

  bool _standardReached(
    AchievementDefinition definition,
    PlayerProgressSnapshot progress,
  ) {
    final intThreshold = definition.intThreshold;
    if (intThreshold != null) {
      return _intMetric(definition.metric, progress) >= intThreshold;
    }
    final bigThreshold = definition.bigIntThreshold;
    if (bigThreshold != null) {
      return _bigMetric(definition.metric, progress) >= bigThreshold;
    }
    return switch (definition.metric) {
      AchievementMetric.originalItemCatalog => progress.unlockedItemIds
          .containsAll(AchievementCatalog.originalCatalogItemIds),
      AchievementMetric.originalCharacterRoster => progress.unlockedCharacterIds
          .containsAll(AchievementCatalog.originalCharacterRosterIds),
      AchievementMetric.maximumAuraState =>
        progress.maximumAuraStateId == AchievementCatalog.maximumAuraStateId,
      AchievementMetric.fortyTwo => progress.unlockedTechniqueIds
          .contains(AchievementCatalog.fortyTwoTechniqueId),
      _ => false,
    };
  }

  int _intMetric(
    AchievementMetric metric,
    PlayerProgressSnapshot progress,
  ) =>
      switch (metric) {
        AchievementMetric.auraProducingMovements =>
          progress.auraProducingMovements,
        AchievementMetric.sixMovements => progress.sixMovements,
        AchievementMetric.sevenMovements => progress.sevenMovements,
        AchievementMetric.purchases => progress.purchaseCount,
        AchievementMetric.automaticProductionSources =>
          progress.automaticProductionSources,
        AchievementMetric.offlineRewardsCollected =>
          progress.offlineRewardsCollected,
        AchievementMetric.manualMovements => progress.manualMovements,
        AchievementMetric.unlockedItems => progress.unlockedItemIds.length,
        AchievementMetric.unlockedCharacters =>
          progress.unlockedCharacterIds.length,
        AchievementMetric.distinctPlayDays => progress.distinctPlayDays.length,
        _ => 0,
      };

  BigInt _bigMetric(
    AchievementMetric metric,
    PlayerProgressSnapshot progress,
  ) =>
      switch (metric) {
        AchievementMetric.totalAura => progress.totalAura,
        AchievementMetric.auraPerSecond => progress.auraPerSecond,
        AchievementMetric.maximumAuraPerMovement =>
          progress.maximumAuraPerMovement,
        _ => BigInt.zero,
      };
}
