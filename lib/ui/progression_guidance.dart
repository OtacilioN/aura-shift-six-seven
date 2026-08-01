import 'package:flutter/material.dart';

import '../core/formatting.dart';
import '../core/game_controller.dart';
import '../main.dart';

class AuraTierProgress {
  const AuraTierProgress({
    required this.threshold,
    required this.previousThreshold,
    required this.formId,
    required this.upgradeIds,
    required this.includesAscension,
    required this.progress,
  });

  final BigInt threshold;
  final BigInt previousThreshold;
  final String formId;
  final List<String> upgradeIds;
  final bool includesAscension;
  final double progress;
}

class AuraUnlockGoal {
  const AuraUnlockGoal({required this.upgrade, required this.pending});

  final Upgrade upgrade;
  final List<UpgradeRequirement> pending;
}

class AuraMilestoneGoal {
  const AuraMilestoneGoal({
    required this.upgrade,
    required this.level,
    required this.targetLevel,
  });

  final Upgrade upgrade;
  final int level;
  final int targetLevel;
}

class AuraProgressionPlan {
  const AuraProgressionPlan({
    required this.tier,
    required this.unlockGoals,
    required this.milestoneGoals,
  });

  final AuraTierProgress? tier;
  final List<AuraUnlockGoal> unlockGoals;
  final List<AuraMilestoneGoal> milestoneGoals;
}

class _TierDefinition {
  const _TierDefinition({
    required this.threshold,
    required this.formId,
    required this.upgradeIds,
    this.includesAscension = false,
  });

  final int threshold;
  final String formId;
  final List<String> upgradeIds;
  final bool includesAscension;
}

const _tierDefinitions = <_TierDefinition>[
  _TierDefinition(
    threshold: 1000,
    formId: 'FORM-01',
    upgradeIds: [
      'ITEM-CONV-01',
      'TECH-02',
      'ITEM-A-02',
      'ITEM-B-02',
      'ITEM-C-02',
    ],
  ),
  _TierDefinition(
    threshold: 1000000,
    formId: 'FORM-02',
    upgradeIds: ['TECH-03', 'ITEM-A-03', 'ITEM-B-03', 'ITEM-C-03'],
  ),
  _TierDefinition(
    threshold: 1000000000,
    formId: 'FORM-03',
    upgradeIds: [
      'ITEM-CONV-02',
      'TECH-04',
      'ITEM-A-04',
      'ITEM-B-04',
      'ITEM-C-04',
    ],
  ),
  _TierDefinition(
    threshold: 1000000000000,
    formId: 'FORM-04',
    upgradeIds: ['TECH-05', 'ITEM-A-05', 'ITEM-B-05', 'ITEM-C-05'],
  ),
  _TierDefinition(
    threshold: 1000000000000000,
    formId: 'FORM-05',
    upgradeIds: ['ITEM-CONV-03', 'TECH-06'],
    includesAscension: true,
  ),
];

const _visualProgressionOrder = <String>[
  'ITEM-A-01',
  'ITEM-B-01',
  'ITEM-C-01',
  'ITEM-CONV-01',
  'TECH-02',
  'ITEM-A-02',
  'ITEM-B-02',
  'ITEM-C-02',
  'TECH-03',
  'ITEM-A-03',
  'ITEM-B-03',
  'ITEM-C-03',
  'ITEM-CONV-02',
  'TECH-04',
  'ITEM-A-04',
  'ITEM-B-04',
  'ITEM-C-04',
  'TECH-05',
  'ITEM-A-05',
  'ITEM-B-05',
  'ITEM-C-05',
  'ITEM-CONV-03',
  'TECH-06',
];

AuraProgressionPlan buildAuraProgressionPlan(GameController controller) {
  AuraTierProgress? tier;
  var previous = BigInt.zero;
  for (final definition in _tierDefinitions) {
    final threshold = BigInt.from(definition.threshold);
    if (controller.total < threshold) {
      final completed = controller.total > previous
          ? controller.total - previous
          : BigInt.zero;
      final span = threshold - previous;
      tier = AuraTierProgress(
        threshold: threshold,
        previousThreshold: previous,
        formId: definition.formId,
        upgradeIds: definition.upgradeIds,
        includesAscension: definition.includesAscension,
        progress: (completed.toDouble() / span.toDouble()).clamp(0, 1),
      );
      break;
    }
    previous = threshold;
  }

  final byId = {for (final upgrade in upgrades) upgrade.id: upgrade};
  final unlockGoals = <AuraUnlockGoal>[];
  for (final id in _visualProgressionOrder) {
    final upgrade = byId[id];
    if (upgrade == null || controller.isUnlocked(upgrade)) continue;
    final pending = controller
        .requirementsFor(upgrade)
        .where((requirement) => !controller.requirementMet(requirement))
        .toList(growable: false);
    if (pending.isNotEmpty) {
      unlockGoals.add(AuraUnlockGoal(upgrade: upgrade, pending: pending));
    }
  }

  final milestoneGoals = upgrades
      .where((upgrade) => controller.level(upgrade.id) > 0)
      .map((upgrade) {
    final level = controller.level(upgrade.id);
    return AuraMilestoneGoal(
      upgrade: upgrade,
      level: level,
      targetLevel: nextAuraLevelMilestone(level),
    );
  }).toList()
    ..sort((a, b) {
      final remainingA = a.targetLevel - a.level;
      final remainingB = b.targetLevel - b.level;
      final remaining = remainingA.compareTo(remainingB);
      if (remaining != 0) return remaining;
      return _progressionIndex(a.upgrade.id)
          .compareTo(_progressionIndex(b.upgrade.id));
    });

  return AuraProgressionPlan(
    tier: tier,
    unlockGoals: List.unmodifiable(unlockGoals),
    milestoneGoals: List.unmodifiable(milestoneGoals),
  );
}

int nextAuraLevelMilestone(int level) {
  for (final milestone in const [10, 25, 50]) {
    if (level < milestone) return milestone;
  }
  return ((level ~/ 100) + 1) * 100;
}

int _progressionIndex(String id) {
  final visualIndex = _visualProgressionOrder.indexOf(id);
  if (visualIndex >= 0) return visualIndex;
  final fallback = upgrades.indexWhere((upgrade) => upgrade.id == id);
  return _visualProgressionOrder.length + (fallback < 0 ? 999 : fallback);
}

class AuraNextStepsTrigger extends StatelessWidget {
  const AuraNextStepsTrigger({
    super.key,
    required this.strings,
    required this.onTap,
  });

  final Strings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        key: const ValueKey('next-steps-trigger'),
        tooltip: strings('progress_title'),
        onPressed: onTap,
        icon: const Icon(
          Icons.flag_outlined,
          color: Color(0xFFFFD166),
          size: 22,
        ),
      );
}

class AuraNextStepsSheet extends StatelessWidget {
  const AuraNextStepsSheet({
    super.key,
    required this.controller,
    required this.strings,
    required this.onOpenUpgrade,
  });

  final GameController controller;
  final Strings strings;
  final ValueChanged<String> onOpenUpgrade;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .86,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final plan = buildAuraProgressionPlan(controller);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 8, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined,
                            color: Color(0xFFFFD166)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            strings('progress_title'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: strings('action_close'),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      key: const PageStorageKey('next-steps-scroll'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        _TierSection(
                          tier: plan.tier,
                          strings: strings,
                        ),
                        const SizedBox(height: 20),
                        _SectionTitle(
                          icon: Icons.account_tree_outlined,
                          label: strings('progress_shop_unlocks'),
                        ),
                        const SizedBox(height: 6),
                        if (plan.unlockGoals.isEmpty)
                          _EmptyProgressCard(
                            label: strings('progress_no_pending_unlocks'),
                          )
                        else
                          for (final goal in plan.unlockGoals.take(3))
                            Card(
                              child: ListTile(
                                key: ValueKey('next-unlock-${goal.upgrade.id}'),
                                title: Text(strings(goal.upgrade.nameKey)),
                                subtitle: Text(
                                  goal.pending
                                      .map((requirement) => _requirementLabel(
                                            requirement,
                                            controller: controller,
                                            strings: strings,
                                          ))
                                      .join('\n'),
                                ),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () => onOpenUpgrade(goal.upgrade.id),
                              ),
                            ),
                        const SizedBox(height: 20),
                        _SectionTitle(
                          icon: Icons.emoji_events_outlined,
                          label: strings('progress_item_milestones'),
                        ),
                        const SizedBox(height: 6),
                        if (plan.milestoneGoals.isEmpty)
                          _EmptyProgressCard(
                            label: strings('progress_no_item_milestones'),
                          )
                        else
                          for (final goal in plan.milestoneGoals.take(3))
                            Card(
                              child: ListTile(
                                key: ValueKey(
                                    'next-milestone-${goal.upgrade.id}'),
                                title: Text(strings(goal.upgrade.nameKey)),
                                subtitle: Text(
                                  '${strings('shop_next_milestone', {
                                        'level': '${goal.targetLevel}',
                                      })} (${goal.level}/${goal.targetLevel})',
                                ),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () => onOpenUpgrade(goal.upgrade.id),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _TierSection extends StatelessWidget {
  const _TierSection({required this.tier, required this.strings});

  final AuraTierProgress? tier;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final current = tier;
    if (current == null) {
      return _EmptyProgressCard(label: strings('progress_all_tiers'));
    }
    final formKey = current.formId.toLowerCase().replaceAll('-', '_');
    final byId = {for (final upgrade in upgrades) upgrade.id: upgrade};
    final unlockLabels = <String>[
      strings('content.$formKey.name'),
      for (final id in current.upgradeIds)
        if (byId[id] case final upgrade?) strings(upgrade.nameKey),
      if (current.includesAscension) strings('ascension_title'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings('progress_next_tier'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              strings('shop_tier_required', {
                'amount': _ltr(AuraFormat.integer(
                  current.threshold,
                  locale: strings.locale,
                )),
              }),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: current.progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF43E6FF),
            ),
            const SizedBox(height: 12),
            Text(
              strings('progress_tier_unlocks'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final label in unlockLabels) Chip(label: Text(label))
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      );
}

class _EmptyProgressCard extends StatelessWidget {
  const _EmptyProgressCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFFB7F171)),
              const SizedBox(width: 10),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      );
}

String _requirementLabel(
  UpgradeRequirement requirement, {
  required GameController controller,
  required Strings strings,
}) {
  if (requirement.kind == UpgradeRequirementKind.totalAura) {
    final target = requirement.total!;
    return '${strings('shop_tier_required', {
          'amount': _ltr(AuraFormat.integer(target, locale: strings.locale)),
        })} ${_ltr('(${AuraFormat.integer(controller.total, locale: strings.locale)}/${AuraFormat.integer(target, locale: strings.locale)})')}';
  }
  final prerequisite = upgrades.firstWhere(
    (upgrade) => upgrade.id == requirement.upgradeId,
  );
  return '${strings('shop_item_required', {
        'name': strings(prerequisite.nameKey),
        'level': _ltr('${requirement.level}'),
      })} ${_ltr('(${controller.level(prerequisite.id)}/${requirement.level})')}';
}

String _ltr(String value) => '\u2066$value\u2069';
