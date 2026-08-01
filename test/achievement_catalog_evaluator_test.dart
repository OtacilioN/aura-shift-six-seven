import 'package:aura_shift_six_seven/achievements/achievement_catalog.dart';
import 'package:aura_shift_six_seven/achievements/achievement_evaluator.dart';
import 'package:aura_shift_six_seven/achievements/achievement_models.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = AchievementEvaluator();

  group('catalog contract', () {
    final definitions = AchievementCatalog.definitions;

    test('contains exactly 26 achievements totaling 935 points', () {
      expect(definitions, hasLength(26));
      expect(
        definitions.fold<int>(0, (sum, definition) => sum + definition.points),
        935,
      );
    });

    test('points and incremental step limits follow Play Games rules', () {
      for (final definition in definitions) {
        expect(definition.points % 5, 0, reason: definition.key.name);
        expect(definition.points, inInclusiveRange(5, 200));
        if (definition.type == AchievementType.incremental) {
          expect(definition.requiredSteps, isNotNull);
          expect(definition.requiredSteps!, inInclusiveRange(1, 10000));
        }
      }
    });

    test('names and list orders are unique', () {
      expect(
        definitions.map((definition) => definition.namePtBr).toSet(),
        hasLength(26),
      );
      expect(
        definitions.map((definition) => definition.nameEnUs).toSet(),
        hasLength(26),
      );
      expect(
        definitions.map((definition) => definition.listOrder).toSet(),
        hasLength(26),
      );
    });

    test('Forty Two is the only hidden achievement', () {
      final hidden = definitions
          .where(
            (definition) =>
                definition.visibility == AchievementVisibility.hidden,
          )
          .toList();
      expect(hidden, hasLength(1));
      expect(hidden.single.key, AuraAchievement.fortyTwo);
    });
  });

  group('standard evaluation', () {
    test('first movement requires a movement that actually produced aura', () {
      expect(
        _evaluate(evaluator, auraProducingMovements: 0),
        isNot(contains(AuraAchievement.firstMovement)),
      );
      expect(
        _evaluate(evaluator, auraProducingMovements: 1),
        contains(AuraAchievement.firstMovement),
      );
    });

    test('Six and Seven use independent persisted movement counts', () {
      expect(
        _evaluate(evaluator, sixMovements: 1),
        contains(AuraAchievement.firstSix),
      );
      expect(
        _evaluate(evaluator, sevenMovements: 1),
        contains(AuraAchievement.firstSeven),
      );
    });

    test('67 aura purchase and automatic production use real state', () {
      final standards = _evaluate(
        evaluator,
        totalAura: BigInt.from(67),
        purchaseCount: 1,
        automaticProductionSources: 1,
      );
      expect(
        standards,
        containsAll({
          AuraAchievement.sixSeven,
          AuraAchievement.firstPurchase,
          AuraAchievement.firstAutomaticProduction,
        }),
      );
    });

    test('offline reward must have been applied with positive value', () {
      expect(
        _evaluate(evaluator, offlineRewardsCollected: 0),
        isNot(contains(AuraAchievement.firstOfflineReward)),
      );
      expect(
        _evaluate(evaluator, offlineRewardsCollected: 1),
        contains(AuraAchievement.firstOfflineReward),
      );
    });

    test('all five lifetime aura thresholds are BigInt-safe', () {
      final standards = _evaluate(
        evaluator,
        totalAura: BigInt.parse('1000000000000000000000000000000'),
      );
      expect(
        standards,
        containsAll({
          AuraAchievement.totalAura1000,
          AuraAchievement.totalAura1Million,
          AuraAchievement.totalAura1Billion,
          AuraAchievement.totalAura1Trillion,
          AuraAchievement.totalAura1Quintillion,
        }),
      );
    });

    test('item catalog is frozen and excludes future IDs', () {
      final items = {
        ...AchievementCatalog.originalCatalogItemIds,
        'ITEM-FUTURE-99',
      };
      final standards = _evaluate(evaluator, unlockedItemIds: items);
      expect(standards, contains(AuraAchievement.tenItems));
      expect(standards, contains(AuraAchievement.originalItemCatalog));
    });

    test('three transformations and frozen roster replace absent characters',
        () {
      expect(
        _evaluate(
          evaluator,
          unlockedCharacterIds: {'FORM-01', 'FORM-02', 'FORM-03'},
        ),
        contains(AuraAchievement.fiveCharacters),
      );
      expect(
        _evaluate(
          evaluator,
          unlockedCharacterIds: AchievementCatalog.originalCharacterRosterIds,
        ),
        contains(AuraAchievement.originalCharacterRoster),
      );
    });

    test('maximum state and Forty Two use persisted domain IDs', () {
      final standards = _evaluate(
        evaluator,
        maximumAuraStateId: AchievementCatalog.maximumAuraStateId,
        unlockedTechniqueIds: {AchievementCatalog.fortyTwoTechniqueId},
      );
      expect(standards, contains(AuraAchievement.maximumAuraState));
      expect(standards, contains(AuraAchievement.fortyTwo));
    });

    test('production and single movement thresholds use effective values', () {
      final standards = _evaluate(
        evaluator,
        auraPerSecond: BigInt.from(1000000),
        maximumAuraPerMovement: BigInt.from(1000000),
      );
      expect(standards, contains(AuraAchievement.auraPerSecond67));
      expect(standards, contains(AuraAchievement.auraPerSecond1Million));
      expect(standards, contains(AuraAchievement.singleMovement1Million));
    });
  });

  group('incremental evaluation', () {
    test('manual progress is absolute and clamped for all three targets', () {
      final progress = evaluator
          .evaluateAchievements(_snapshot(manualMovements: 12345))
          .incrementalSteps;
      expect(progress[AuraAchievement.manualMovements100], 100);
      expect(progress[AuraAchievement.manualMovements1000], 1000);
      expect(progress[AuraAchievement.manualMovements10000], 10000);
    });

    test('seven and thirty distinct local dates are monotonic set progress',
        () {
      final days = {
        for (var day = 1; day <= 30; day++)
          '2026-07-${day.toString().padLeft(2, '0')}',
      };
      final progress = evaluator
          .evaluateAchievements(_snapshot(distinctPlayDays: days))
          .incrementalSteps;
      expect(progress[AuraAchievement.sevenDistinctDays], 7);
      expect(progress[AuraAchievement.thirtyDistinctDays], 30);
    });

    test(
        'same local date is not duplicated and timezone keys never remove days',
        () {
      final dayA = GameController.localDayKey(
        DateTime.parse('2026-07-27T23:30:00-03:00'),
      );
      final dayB = GameController.localDayKey(
        DateTime.parse('2026-07-28T03:30:00+02:00'),
      );
      final keys = {dayA, dayA, dayB};
      expect(keys.length, inInclusiveRange(1, 2));
      final progress = evaluator
          .evaluateAchievements(_snapshot(distinctPlayDays: keys))
          .incrementalSteps;
      expect(progress[AuraAchievement.sevenDistinctDays], keys.length);
    });
  });

  test('invalid or unmigrated snapshots award nothing', () {
    final result = evaluator.evaluateAchievements(
      _snapshot(totalAura: BigInt.from(-1), saveMigrated: false),
    );
    expect(result.standardsToUnlock, isEmpty);
    expect(result.incrementalSteps, isEmpty);
  });
}

Set<AuraAchievement> _evaluate(
  AchievementEvaluator evaluator, {
  BigInt? totalAura,
  int manualMovements = 0,
  int auraProducingMovements = 0,
  int sixMovements = 0,
  int sevenMovements = 0,
  int purchaseCount = 0,
  int automaticProductionSources = 0,
  BigInt? auraPerSecond,
  BigInt? maximumAuraPerMovement,
  int offlineRewardsCollected = 0,
  Set<String> unlockedItemIds = const {},
  Set<String> unlockedCharacterIds = const {},
  Set<String> unlockedTechniqueIds = const {},
  Set<String> distinctPlayDays = const {},
  String? maximumAuraStateId,
}) =>
    evaluator
        .evaluateAchievements(
          _snapshot(
            totalAura: totalAura,
            manualMovements: manualMovements,
            auraProducingMovements: auraProducingMovements,
            sixMovements: sixMovements,
            sevenMovements: sevenMovements,
            purchaseCount: purchaseCount,
            automaticProductionSources: automaticProductionSources,
            auraPerSecond: auraPerSecond,
            maximumAuraPerMovement: maximumAuraPerMovement,
            offlineRewardsCollected: offlineRewardsCollected,
            unlockedItemIds: unlockedItemIds,
            unlockedCharacterIds: unlockedCharacterIds,
            unlockedTechniqueIds: unlockedTechniqueIds,
            distinctPlayDays: distinctPlayDays,
            maximumAuraStateId: maximumAuraStateId,
          ),
        )
        .standardsToUnlock;

PlayerProgressSnapshot _snapshot({
  BigInt? totalAura,
  int manualMovements = 0,
  int auraProducingMovements = 0,
  int sixMovements = 0,
  int sevenMovements = 0,
  int purchaseCount = 0,
  int automaticProductionSources = 0,
  BigInt? auraPerSecond,
  BigInt? maximumAuraPerMovement,
  int offlineRewardsCollected = 0,
  Set<String> unlockedItemIds = const {},
  Set<String> unlockedCharacterIds = const {},
  Set<String> unlockedTechniqueIds = const {},
  Set<String> distinctPlayDays = const {},
  String? maximumAuraStateId,
  bool saveMigrated = true,
}) =>
    PlayerProgressSnapshot(
      totalAura: totalAura ?? BigInt.zero,
      manualMovements: manualMovements,
      auraProducingMovements: auraProducingMovements,
      sixMovements: sixMovements,
      sevenMovements: sevenMovements,
      purchaseCount: purchaseCount,
      automaticProductionSources: automaticProductionSources,
      auraPerSecond: auraPerSecond ?? BigInt.zero,
      maximumAuraPerMovement: maximumAuraPerMovement ?? BigInt.zero,
      offlineRewardsCollected: offlineRewardsCollected,
      unlockedItemIds: unlockedItemIds,
      unlockedCharacterIds: unlockedCharacterIds,
      unlockedTechniqueIds: unlockedTechniqueIds,
      distinctPlayDays: distinctPlayDays,
      maximumAuraStateId: maximumAuraStateId,
      saveMigrated: saveMigrated,
    );
