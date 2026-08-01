import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'achievement_models.dart';

class AchievementQueueState {
  AchievementQueueState({
    this.ownerPlayerId,
    Set<AuraAchievement>? pendingUnlocks,
    Map<AuraAchievement, int>? pendingSteps,
    Set<AuraAchievement>? pendingReveals,
    Set<AuraAchievement>? confirmedUnlocks,
    Map<AuraAchievement, int>? confirmedSteps,
    this.lastSync,
    this.failedAttempts = 0,
    this.authenticated = false,
    this.reconciliationVersion = 0,
  })  : pendingUnlocks = pendingUnlocks ?? {},
        pendingSteps = pendingSteps ?? {},
        pendingReveals = pendingReveals ?? {},
        confirmedUnlocks = confirmedUnlocks ?? {},
        confirmedSteps = confirmedSteps ?? {};

  factory AchievementQueueState.fromJson(Map<String, dynamic> json) {
    Set<AuraAchievement> keys(String name) => {
          for (final value in (json[name] as List? ?? const []))
            if (_achievement(value) case final achievement?) achievement,
        };
    Map<AuraAchievement, int> steps(String name) => {
          for (final entry
              in (json[name] as Map? ?? const <String, dynamic>{}).entries)
            if (_achievement(entry.key) case final achievement?)
              achievement:
                  ((entry.value as num?)?.toInt() ?? 0).clamp(0, 10000),
        };
    return AchievementQueueState(
      ownerPlayerId: _nullableString(json['ownerPlayerId']),
      pendingUnlocks: keys('pendingUnlocks'),
      pendingSteps: steps('pendingSteps'),
      pendingReveals: keys('pendingReveals'),
      confirmedUnlocks: keys('confirmedUnlocks'),
      confirmedSteps: steps('confirmedSteps'),
      lastSync: DateTime.tryParse('${json['lastSync'] ?? ''}'),
      failedAttempts:
          ((json['failedAttempts'] as num?)?.toInt() ?? 0).clamp(0, 1000000),
      authenticated: json['authenticated'] == true,
      reconciliationVersion:
          ((json['reconciliationVersion'] as num?)?.toInt() ?? 0)
              .clamp(0, achievementCatalogVersion),
    );
  }

  String? ownerPlayerId;
  final Set<AuraAchievement> pendingUnlocks;
  final Map<AuraAchievement, int> pendingSteps;
  final Set<AuraAchievement> pendingReveals;
  final Set<AuraAchievement> confirmedUnlocks;
  final Map<AuraAchievement, int> confirmedSteps;
  DateTime? lastSync;
  int failedAttempts;
  bool authenticated;
  int reconciliationVersion;

  bool get hasPending =>
      pendingUnlocks.isNotEmpty ||
      pendingSteps.entries.any(
        (entry) => entry.value > (confirmedSteps[entry.key] ?? 0),
      ) ||
      pendingReveals.isNotEmpty;

  int get pendingCount =>
      pendingUnlocks.length +
      pendingReveals.length +
      pendingSteps.entries
          .where((entry) => entry.value > (confirmedSteps[entry.key] ?? 0))
          .length;

  void resetForOwner(String playerId) {
    ownerPlayerId = playerId;
    pendingUnlocks.clear();
    pendingSteps.clear();
    pendingReveals.clear();
    confirmedUnlocks.clear();
    confirmedSteps.clear();
    lastSync = null;
    failedAttempts = 0;
    authenticated = true;
    reconciliationVersion = 0;
  }

  Map<String, dynamic> toJson() => {
        if (ownerPlayerId != null) 'ownerPlayerId': ownerPlayerId,
        'pendingUnlocks': _ordered(pendingUnlocks),
        'pendingSteps': {
          for (final entry in pendingSteps.entries) entry.key.name: entry.value,
        },
        'pendingReveals': _ordered(pendingReveals),
        'confirmedUnlocks': _ordered(confirmedUnlocks),
        'confirmedSteps': {
          for (final entry in confirmedSteps.entries)
            entry.key.name: entry.value,
        },
        if (lastSync != null) 'lastSync': lastSync!.toUtc().toIso8601String(),
        'failedAttempts': failedAttempts,
        'authenticated': authenticated,
        'reconciliationVersion': reconciliationVersion,
      };
}

abstract interface class AchievementProgressRepository {
  Future<AchievementQueueState> read();
  Future<void> write(AchievementQueueState state);
}

class SharedPreferencesAchievementProgressRepository
    implements AchievementProgressRepository {
  SharedPreferencesAchievementProgressRepository(this._preferences);

  static const storageKey = 'play-games-achievements-v1';
  final SharedPreferences _preferences;

  static Future<SharedPreferencesAchievementProgressRepository>
      create() async => SharedPreferencesAchievementProgressRepository(
            await SharedPreferences.getInstance(),
          );

  @override
  Future<AchievementQueueState> read() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null) return AchievementQueueState();
    try {
      return AchievementQueueState.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return AchievementQueueState();
    }
  }

  @override
  Future<void> write(AchievementQueueState state) =>
      _preferences.setString(storageKey, jsonEncode(state.toJson()));
}

AuraAchievement? _achievement(Object? value) {
  final name = '$value';
  for (final achievement in AuraAchievement.values) {
    if (achievement.name == name) return achievement;
  }
  return null;
}

List<String> _ordered(Set<AuraAchievement> values) {
  final result = values.map((value) => value.name).toList();
  result.sort();
  return result;
}

String? _nullableString(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}
