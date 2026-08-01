import 'package:flutter/material.dart';

import '../core/formatting.dart';
import '../core/game_controller.dart';
import '../main.dart';

/// Immutable copy of the Aura values displayed when the details sheet opens.
class AuraDetailsSnapshot {
  const AuraDetailsSnapshot({
    required this.available,
    required this.total,
    required this.journey,
    required this.powerNumerator,
    required this.passiveNumerator,
  });

  factory AuraDetailsSnapshot.fromController(GameController controller) =>
      AuraDetailsSnapshot(
        available: controller.available,
        total: controller.total,
        journey: controller.journey,
        powerNumerator: controller.powerNumerator,
        passiveNumerator: controller.passiveNumerator,
      );

  final BigInt available;
  final BigInt total;
  final BigInt journey;
  final BigInt powerNumerator;
  final BigInt passiveNumerator;
}

class AuraDetailsSheet extends StatelessWidget {
  const AuraDetailsSheet({
    super.key,
    required this.snapshot,
    required this.strings,
    required this.artwork,
  });

  final AuraDetailsSnapshot snapshot;
  final Strings strings;
  final Widget artwork;

  @override
  Widget build(BuildContext context) {
    final locale = strings.locale;
    final rows = <({String keyName, String label, String value})>[
      (
        keyName: 'available',
        label: strings('play_available_aura'),
        value: AuraFormat.exactInteger(snapshot.available, locale: locale),
      ),
      (
        keyName: 'total',
        label: strings('play_total_aura'),
        value: AuraFormat.exactInteger(snapshot.total, locale: locale),
      ),
      (
        keyName: 'journey',
        label: strings('play_journey_aura'),
        value: AuraFormat.exactInteger(snapshot.journey, locale: locale),
      ),
      (
        keyName: 'cycle-power',
        label: strings('play_cycle_power'),
        value: AuraFormat.exactRate(
          snapshot.powerNumerator,
          locale: locale,
        ),
      ),
      (
        keyName: 'passive-rate',
        label: strings('play_passive_rate'),
        value:
            '${AuraFormat.exactRate(snapshot.passiveNumerator, locale: locale)}/s',
      ),
    ];
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                artwork,
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    strings('play_aura_details'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.onSurface.withValues(alpha: 0.08),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < rows.length; index++) ...[
                    _AuraDetailRow(
                      key: ValueKey('aura-detail-${rows[index].keyName}'),
                      label: rows[index].label,
                      value: rows[index].value,
                    ),
                    if (index != rows.length - 1)
                      Divider(
                        height: 1,
                        color: colors.onSurface.withValues(alpha: 0.07),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuraDetailRow extends StatelessWidget {
  const _AuraDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Text(label, style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    value,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
