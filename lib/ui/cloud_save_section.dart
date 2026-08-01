import 'dart:async';

import 'package:flutter/material.dart';

import '../cloud_save/cloud_save_coordinator.dart';
import '../cloud_save/cloud_save_models.dart';
import '../core/formatting.dart';
import '../main.dart';

class CloudSaveSection extends StatelessWidget {
  const CloudSaveSection({
    super.key,
    required this.coordinator,
    required this.strings,
  });

  final CloudSaveCoordinator coordinator;
  final Strings strings;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: coordinator,
        builder: (context, _) {
          final state = coordinator.state;
          final action = _actionFor(state);
          final lastSync = state is CloudSaveSynced
              ? state.syncedAt
              : coordinator.lastSuccessfulSync;
          return Card(
            key: const ValueKey('cloud-save-section'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_iconFor(state), size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings('cloud_save_title'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(strings('cloud_save_explain')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (state is CloudSaveSyncing)
                        const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(_iconFor(state), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings(_statusKeyFor(state)),
                          key: const ValueKey('cloud-save-status'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  if (coordinator.player?.displayName case final name?)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(name),
                    ),
                  if (lastSync case final syncedAt?)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        strings('cloud_save_last_sync', {
                          'date': _formatDate(syncedAt),
                        }),
                      ),
                    ),
                  if (state.hasPendingChanges)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        strings('cloud_save_pending_changes', {
                          'count': '1+',
                        }),
                        key: const ValueKey('cloud-save-pending'),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: state is CloudSaveConflictPending
                        ? FilledButton(
                            key: const ValueKey(
                              'cloud-save-resolve-conflict',
                            ),
                            onPressed: () => showCloudSaveConflictDialog(
                              context,
                              coordinator: coordinator,
                              strings: strings,
                            ),
                            child: Text(strings('cloud_save_conflict')),
                          )
                        : OutlinedButton.icon(
                            key: const ValueKey('cloud-save-action'),
                            onPressed: state is CloudSaveSyncing ||
                                    state is CloudSaveUnavailable ||
                                    (state is CloudSaveFailure &&
                                        !state.retryable)
                                ? null
                                : () => unawaited(
                                      _runAction(context, action),
                                    ),
                            icon: Icon(action.icon),
                            label: Text(strings(action.labelKey)),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Future<void> _runAction(
    BuildContext context,
    _CloudAction action,
  ) async {
    final result = await action.callback(coordinator);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(strings(_statusKeyFor(result.state))),
        ),
      );
  }

  _CloudAction _actionFor(CloudSaveState state) {
    if (state is CloudSaveUnauthenticated) {
      return const _CloudAction(
        'cloud_save_connect',
        Icons.sports_esports_outlined,
        _connect,
      );
    }
    if (state is CloudSaveFailure ||
        state is CloudSaveOffline ||
        state is CloudSavePending) {
      return const _CloudAction(
        'cloud_save_retry',
        Icons.refresh,
        _retry,
      );
    }
    return const _CloudAction(
      'cloud_save_sync_now',
      Icons.sync,
      _sync,
    );
  }

  static Future<CloudSyncResult> _connect(
    CloudSaveCoordinator coordinator,
  ) =>
      coordinator.connect();

  static Future<CloudSyncResult> _retry(
    CloudSaveCoordinator coordinator,
  ) =>
      coordinator.retry();

  static Future<CloudSyncResult> _sync(
    CloudSaveCoordinator coordinator,
  ) =>
      coordinator.uploadCurrentSave();
}

Future<void> showCloudSaveConflictDialog(
  BuildContext context, {
  required CloudSaveCoordinator coordinator,
  required Strings strings,
}) async {
  final conflict = coordinator.pendingConflict;
  if (conflict == null) return;
  final selected = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('cloud-save-conflict-dialog'),
      title: Text(strings(conflict.accountSwitch
          ? 'cloud_save_account_switch_title'
          : 'cloud_save_conflict_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings(conflict.accountSwitch
                ? 'cloud_save_account_switch_body'
                : 'cloud_save_conflict_body')),
            const SizedBox(height: 16),
            for (final candidate in conflict.candidates) ...[
              _CandidateCard(
                candidate: candidate,
                recommended: conflict.recommendedCandidateId == candidate.id,
                strings: strings,
                actionLabel: conflict.accountSwitch
                    ? strings('cloud_save_link_progress')
                    : strings('cloud_save_use_this'),
                onSelected: () => Navigator.pop(dialogContext, candidate.id),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings('cloud_save_later')),
        ),
      ],
    ),
  );
  if (selected == null) {
    await coordinator.postponeConflict();
  } else {
    await coordinator.resolveConflict(selected);
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.recommended,
    required this.strings,
    required this.actionLabel,
    required this.onSelected,
  });

  final CloudSaveCandidate candidate;
  final bool recommended;
  final Strings strings;
  final String actionLabel;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final summary = candidate.summary;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: recommended
              ? Theme.of(context).colorScheme.primary
              : Colors.white24,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings(_originKey(candidate.origin)),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (recommended)
                  Chip(label: Text(strings('cloud_save_recommended'))),
              ],
            ),
            if (summary.deviceName case final device?)
              Text(device, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            _line(
              'cloud_save_updated',
              'date',
              _formatDate(summary.savedAtUtc),
            ),
            _line('cloud_save_level', 'level', '${summary.auraLevel}'),
            _line(
              'cloud_save_total_aura',
              'amount',
              AuraFormat.integer(summary.totalAura, locale: strings.locale),
            ),
            _line(
              'cloud_save_aura_per_second',
              'amount',
              AuraFormat.integer(
                summary.auraPerSecond,
                locale: strings.locale,
              ),
            ),
            _line('cloud_save_ascensions', 'count', '${summary.ascensions}'),
            _line('cloud_save_items', 'count', '${summary.itemsUnlocked}'),
            _line(
              'cloud_save_play_time',
              'duration',
              _formatDuration(summary.totalPlayTime),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSelected,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String key, String placeholder, String value) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(strings(key, {placeholder: value})),
      );
}

class _CloudAction {
  const _CloudAction(this.labelKey, this.icon, this.callback);

  final String labelKey;
  final IconData icon;
  final Future<CloudSyncResult> Function(CloudSaveCoordinator) callback;
}

String _statusKeyFor(CloudSaveState state) => switch (state) {
      CloudSaveSynced() => 'cloud_save_synced',
      CloudSaveSyncing() => 'cloud_save_syncing',
      CloudSaveLocalOnly() => 'cloud_save_local',
      CloudSavePending() => 'cloud_save_pending',
      CloudSaveOffline() => 'cloud_save_offline',
      CloudSaveUnauthenticated() => 'cloud_save_unauthenticated',
      CloudSaveUnavailable() => 'cloud_save_unavailable',
      CloudSaveConflictPending() => 'cloud_save_conflict',
      CloudSaveFailure() => 'cloud_save_failed',
    };

IconData _iconFor(CloudSaveState state) => switch (state) {
      CloudSaveSynced() => Icons.cloud_done_outlined,
      CloudSaveSyncing() => Icons.cloud_sync_outlined,
      CloudSaveLocalOnly() => Icons.phone_android_outlined,
      CloudSavePending() => Icons.cloud_upload_outlined,
      CloudSaveOffline() => Icons.cloud_off_outlined,
      CloudSaveUnauthenticated() => Icons.person_off_outlined,
      CloudSaveUnavailable() => Icons.cloud_off_outlined,
      CloudSaveConflictPending() => Icons.compare_arrows,
      CloudSaveFailure() => Icons.error_outline,
    };

String _originKey(CloudSaveCandidateOrigin origin) => switch (origin) {
      CloudSaveCandidateOrigin.thisDevice => 'cloud_save_this_device',
      CloudSaveCandidateOrigin.cloud => 'cloud_save_cloud',
      CloudSaveCandidateOrigin.otherDevice => 'cloud_save_other_device',
    };

String _formatDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _formatDuration(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  return '${hours}h ${minutes}m';
}
