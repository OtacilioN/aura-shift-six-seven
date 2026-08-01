import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../core/ascension_curve.dart';
import '../core/game_controller.dart';
import '../play_games/play_games_models.dart';

const cloudSaveSchemaVersion = 1;
const cloudSaveMaximumBytes = 3 * 1024 * 1024;
const _cloudAscensionScale = 100000000000;
const _cloudMaximumUpgradeLevel = 100000;

enum CloudSaveValidationFailure {
  malformed,
  unsupportedSchema,
  hashMismatch,
  invalidGameState,
  sizeLimit,
}

class CloudSaveValidationException implements Exception {
  const CloudSaveValidationException(this.failure, [this.message]);

  final CloudSaveValidationFailure failure;
  final String? message;

  @override
  String toString() => 'CloudSaveValidationException($failure, $message)';
}

class CloudSaveEnvelope {
  const CloudSaveEnvelope({
    required this.schemaVersion,
    required this.saveId,
    required this.revision,
    required this.installationId,
    required this.payloadHash,
    required this.savedAtUtc,
    required this.lastActiveAtUtc,
    required this.totalPlayTime,
    required this.gameState,
    this.parentPayloadHash,
  });

  final int schemaVersion;
  final String saveId;
  final int revision;
  final String installationId;
  final String? parentPayloadHash;
  final String payloadHash;
  final DateTime savedAtUtc;
  final DateTime lastActiveAtUtc;
  final Duration totalPlayTime;
  final Map<String, dynamic> gameState;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'saveId': saveId,
        'revision': revision,
        'installationId': installationId,
        if (parentPayloadHash != null) 'parentPayloadHash': parentPayloadHash,
        'payloadHash': payloadHash,
        'savedAtUtc': savedAtUtc.toUtc().toIso8601String(),
        'lastActiveAtUtc': lastActiveAtUtc.toUtc().toIso8601String(),
        'totalPlayTimeMillis': totalPlayTime.inMilliseconds,
        'gameState': gameState,
      };

  CloudSaveEnvelope copyWith({
    int? revision,
    String? installationId,
    String? parentPayloadHash,
    DateTime? savedAtUtc,
    DateTime? lastActiveAtUtc,
    Duration? totalPlayTime,
    Map<String, dynamic>? gameState,
  }) {
    final nextState = gameState ?? this.gameState;
    return CloudSaveEnvelope(
      schemaVersion: schemaVersion,
      saveId: saveId,
      revision: revision ?? this.revision,
      installationId: installationId ?? this.installationId,
      parentPayloadHash: parentPayloadHash ?? this.parentPayloadHash,
      payloadHash: GameSaveCodec.payloadHash(nextState),
      savedAtUtc: (savedAtUtc ?? this.savedAtUtc).toUtc(),
      lastActiveAtUtc: (lastActiveAtUtc ?? this.lastActiveAtUtc).toUtc(),
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      gameState: nextState,
    );
  }
}

class GameSaveCodec {
  const GameSaveCodec();

  Uint8List encode(CloudSaveEnvelope envelope) {
    validateEnvelope(envelope);
    final bytes = Uint8List.fromList(
      utf8.encode(canonicalJson(envelope.toJson())),
    );
    if (bytes.length > cloudSaveMaximumBytes) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.sizeLimit,
      );
    }
    return bytes;
  }

  CloudSaveEnvelope decode(List<int> bytes) {
    if (bytes.length > cloudSaveMaximumBytes) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.sizeLimit,
      );
    }
    try {
      final raw = jsonDecode(utf8.decode(bytes));
      if (raw is! Map) {
        throw const CloudSaveValidationException(
          CloudSaveValidationFailure.malformed,
        );
      }
      final json = raw.cast<String, dynamic>();
      final schema = json['schemaVersion'];
      if (schema is! int || schema != cloudSaveSchemaVersion) {
        throw const CloudSaveValidationException(
          CloudSaveValidationFailure.unsupportedSchema,
        );
      }
      final state = (json['gameState'] as Map).cast<String, dynamic>();
      final envelope = CloudSaveEnvelope(
        schemaVersion: schema,
        saveId: _requiredText(json, 'saveId'),
        revision: _requiredNonNegativeInt(json, 'revision'),
        installationId: _requiredText(json, 'installationId'),
        parentPayloadHash: _optionalText(json['parentPayloadHash']),
        payloadHash: _requiredText(json, 'payloadHash'),
        savedAtUtc: _requiredUtc(json, 'savedAtUtc'),
        lastActiveAtUtc: _requiredUtc(json, 'lastActiveAtUtc'),
        totalPlayTime: Duration(
          milliseconds: _requiredNonNegativeInt(
            json,
            'totalPlayTimeMillis',
          ),
        ),
        gameState: state,
      );
      validateEnvelope(envelope);
      return envelope;
    } on CloudSaveValidationException {
      rethrow;
    } catch (_) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.malformed,
      );
    }
  }

  CloudSaveEnvelope create({
    required String saveId,
    required int revision,
    required String installationId,
    required DateTime savedAtUtc,
    required DateTime lastActiveAtUtc,
    required Duration totalPlayTime,
    required Map<String, dynamic> gameState,
    String? parentPayloadHash,
  }) {
    final normalized = normalizeGameState(gameState);
    final envelope = CloudSaveEnvelope(
      schemaVersion: cloudSaveSchemaVersion,
      saveId: saveId,
      revision: revision,
      installationId: installationId,
      parentPayloadHash: parentPayloadHash,
      payloadHash: payloadHash(normalized),
      savedAtUtc: savedAtUtc.toUtc(),
      lastActiveAtUtc: lastActiveAtUtc.toUtc(),
      totalPlayTime: totalPlayTime,
      gameState: normalized,
    );
    validateEnvelope(envelope);
    return envelope;
  }

  void validateEnvelope(CloudSaveEnvelope envelope) {
    if (envelope.schemaVersion != cloudSaveSchemaVersion) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.unsupportedSchema,
      );
    }
    if (envelope.saveId.isEmpty ||
        envelope.installationId.isEmpty ||
        envelope.revision < 0 ||
        envelope.totalPlayTime.isNegative ||
        !envelope.savedAtUtc.isUtc ||
        !envelope.lastActiveAtUtc.isUtc) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.malformed,
      );
    }
    final hashPattern = RegExp(r'^[0-9a-f]{64}$');
    if (!hashPattern.hasMatch(envelope.payloadHash) ||
        (envelope.parentPayloadHash != null &&
            !hashPattern.hasMatch(envelope.parentPayloadHash!))) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.malformed,
      );
    }
    validateGameState(envelope.gameState);
    if (payloadHash(envelope.gameState) != envelope.payloadHash) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.hashMismatch,
      );
    }
  }

  Map<String, dynamic> normalizeGameState(Map<String, dynamic> source) {
    final state =
        (jsonDecode(jsonEncode(source)) as Map).cast<String, dynamic>();
    state
      ..remove('analyticsEnabled')
      ..remove('analyticsDecided')
      ..remove('returnReminderEnabled')
      ..remove('returnReminderPrompted')
      ..remove('storeReviewRequested')
      ..remove('rewardedUpgradeQuote')
      ..remove('sixStartedAt')
      ..remove('exportedAt')
      ..['saveVersion'] = 1
      ..['arithVersion'] = 'arith-v1'
      ..['balanceVersion'] = balanceVersion;

    for (final key in const [
      'achievements',
      'appearances',
      'equippedAppearances',
      'transformations',
      'seals',
      'rewardedUpgradeStreakItems',
    ]) {
      final value = state[key];
      if (value is List) {
        state[key] = value.map((item) => '$item').toSet().toList()..sort();
      }
    }
    final levels = state['levels'];
    if (levels is Map) {
      state['levels'] = <String, dynamic>{
        for (final key in levels.keys.map((key) => '$key').toList()..sort())
          key: levels[key],
      };
    }
    return _canonicalize(state) as Map<String, dynamic>;
  }

  void validateGameState(Map<String, dynamic> state) {
    if (state['saveVersion'] != 1 ||
        state['arithVersion'] != 'arith-v1' ||
        !const {
          'balance-v0.1',
          'balance-v0.2',
          'balance-v0.3',
          balanceVersion,
        }.contains(state['balanceVersion'])) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }

    final available = _big(state, 'available');
    final total = _big(state, 'total');
    final journey = _big(state, 'journey');
    final remainder = _big(state, 'remainder');
    final multiplier = _big(state, 'multiplier', fallback: '100');
    final ascensionAura = _big(state, 'ascensionAura');
    final maxAuraPerMovement = _big(state, 'maxAuraPerMovement');
    if (available.isNegative ||
        total.isNegative ||
        journey.isNegative ||
        remainder.isNegative ||
        multiplier < BigInt.from(100) ||
        ascensionAura.isNegative ||
        maxAuraPerMovement.isNegative ||
        available > journey ||
        journey > total ||
        remainder >= BigInt.from(10000000)) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    final ascensions = state['ascensions'] ?? 0;
    final expectedMultiplier = state['balanceVersion'] == balanceVersion
        ? AscensionCurve.multiplierForAura(ascensionAura)
        : _legacyCloudMultiplierForAscensionAura(ascensionAura);
    if (ascensions is! int ||
        ascensions < 0 ||
        ascensionAura + journey > total ||
        ascensionAura <
            BigInt.from(ascensions) * BigInt.from(ascensionThreshold) ||
        expectedMultiplier != multiplier) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }

    for (final key in const [
      'cycles',
      'ascensions',
      'totalPlayTimeMillis',
      'manualMovements',
      'auraProducingMovements',
      'sixMovements',
      'sevenMovements',
      'purchaseCount',
      'offlineRewardsCollected',
      'achievementMetricsVersion',
    ]) {
      final value = state[key] ?? 0;
      if (value is! int || value < 0) {
        throw const CloudSaveValidationException(
          CloudSaveValidationFailure.invalidGameState,
        );
      }
    }

    final knownUpgradeIds = upgrades.map((upgrade) => upgrade.id).toSet();
    final levels = state['levels'] ?? const <String, int>{};
    if (levels is! Map ||
        levels.entries.any((entry) =>
            entry.key is! String ||
            !knownUpgradeIds.contains(entry.key) ||
            entry.value is! int ||
            (entry.value as int) < 0 ||
            (entry.value as int) > _cloudMaximumUpgradeLevel)) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }

    _validateKnownList(
      state['achievements'],
      achievementIds.toSet(),
    );
    final knownAppearances = upgrades
        .where((upgrade) => !upgrade.isTechnique)
        .map((upgrade) => upgrade.id)
        .toSet();
    final appearances = _validateKnownList(
      state['appearances'],
      knownAppearances,
    );
    final equipped = _validateKnownList(
      state['equippedAppearances'],
      knownAppearances,
    );
    if (!appearances.containsAll(equipped)) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }

    _validateKnownList(
      state['transformations'],
      const {'FORM-01', 'FORM-02', 'FORM-03', 'FORM-04', 'FORM-05'},
    );
    _validateKnownList(
      state['unlockedTechniqueIds'],
      upgrades
          .where((upgrade) => upgrade.isTechnique)
          .map((upgrade) => upgrade.id)
          .toSet(),
    );
    final distinctDays = state['distinctPlayDays'] ?? const <String>[];
    if (distinctDays is! List ||
        distinctDays.any(
          (value) => value is! String || !_validLocalDayKey(value),
        ) ||
        distinctDays.toSet().length != distinctDays.length) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    final seals = state['seals'] ?? const <String>[];
    if (seals is! List ||
        seals.any((id) => id is! String || !RegExp(r'^67e\d+$').hasMatch(id))) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }

    final phase = state['phase'];
    if (phase != null && phase != 'six' && phase != 'seven') {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    final offlineAt = state['offlineAt'];
    if (offlineAt != null && (offlineAt is! int || offlineAt < 0)) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    if (state['offlineRate'] != null &&
        (BigInt.tryParse('${state['offlineRate']}')?.isNegative ?? true)) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    if ((offlineAt == null) != (state['offlineRate'] == null)) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    _validateReturnReward(state['returnReward']);
  }

  static bool _validLocalDayKey(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return false;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return false;
    final parsed = DateTime(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day;
  }

  static String payloadHash(Map<String, dynamic> gameState) =>
      sha256.convert(utf8.encode(canonicalJson(gameState))).toString();

  static String canonicalJson(Object? value) =>
      jsonEncode(_canonicalize(value));

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => '$key').toList()..sort();
      return <String, dynamic>{
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }
    if (value is List) {
      return value.map(_canonicalize).toList(growable: false);
    }
    if (value is num && !value.isFinite) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    return value;
  }

  static Set<String> _validateKnownList(
    Object? raw,
    Set<String> known,
  ) {
    final values = raw ?? const <String>[];
    if (values is! List ||
        values.any((id) => id is! String || !known.contains(id))) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    return values.cast<String>().toSet();
  }

  static void _validateReturnReward(Object? raw) {
    if (raw == null) return;
    if (raw is! Map) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    for (final key in const ['baseQuanta', 'bonusQuanta']) {
      final value = BigInt.tryParse('${raw[key] ?? 0}');
      if (value == null || value.isNegative) {
        throw const CloudSaveValidationException(
          CloudSaveValidationFailure.invalidGameState,
        );
      }
    }
    for (final key in const ['awayMilliseconds', 'creditedMilliseconds']) {
      final value = raw[key] ?? 0;
      if (value is! int || value < 0) {
        throw const CloudSaveValidationException(
          CloudSaveValidationFailure.invalidGameState,
        );
      }
    }
    final away = raw['awayMilliseconds'] as int? ?? 0;
    final credited = raw['creditedMilliseconds'] as int? ?? 0;
    if (credited > away || credited > const Duration(hours: 4).inMilliseconds) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    const statuses = {'available', 'credited', 'declined', 'ineligible'};
    if (!statuses.contains(raw['baseStatus']) ||
        !statuses.contains(raw['bonusStatus'])) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
  }

  static BigInt _big(
    Map<String, dynamic> state,
    String key, {
    String fallback = '0',
  }) {
    final parsed = BigInt.tryParse('${state[key] ?? fallback}');
    if (parsed == null) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.invalidGameState,
      );
    }
    return parsed;
  }

  static BigInt _legacyCloudMultiplierForAscensionAura(BigInt aura) {
    if (aura <= BigInt.zero) return BigInt.from(100);
    return BigInt.from(100) +
        _integerSqrt(aura ~/ BigInt.from(_cloudAscensionScale));
  }

  static BigInt _integerSqrt(BigInt value) {
    if (value <= BigInt.one) return value;
    var estimate = BigInt.one << ((value.bitLength + 1) >> 1);
    while (true) {
      final next = (estimate + value ~/ estimate) >> 1;
      if (next >= estimate) return estimate;
      estimate = next;
    }
  }

  static String _requiredText(Map<String, dynamic> json, String key) {
    final text = json[key];
    if (text is! String || text.isEmpty) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.malformed,
      );
    }
    return text;
  }

  static String? _optionalText(Object? value) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.malformed,
      );
    }
    return value;
  }

  static int _requiredNonNegativeInt(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is! int || value < 0) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.malformed,
      );
    }
    return value;
  }

  static DateTime _requiredUtc(Map<String, dynamic> json, String key) {
    final parsed = DateTime.tryParse('${json[key] ?? ''}');
    if (parsed == null) {
      throw const CloudSaveValidationException(
        CloudSaveValidationFailure.malformed,
      );
    }
    return parsed.toUtc();
  }
}

class CloudProgressVector {
  const CloudProgressVector({
    required this.ascensions,
    required this.totalAura,
    required this.auraLevel,
    required this.cycles,
    required this.itemsUnlocked,
    required this.totalPlayTime,
  });

  factory CloudProgressVector.fromEnvelope(CloudSaveEnvelope envelope) {
    final state = envelope.gameState;
    final total = BigInt.tryParse('${state['total'] ?? 0}') ?? BigInt.zero;
    return CloudProgressVector(
      ascensions: state['ascensions'] as int? ?? 0,
      totalAura: total,
      auraLevel: auraProgressLevel(total),
      cycles: state['cycles'] as int? ?? 0,
      itemsUnlocked:
          (state['appearances'] as List? ?? const <Object?>[]).length,
      totalPlayTime: envelope.totalPlayTime,
    );
  }

  final int ascensions;
  final BigInt totalAura;
  final int auraLevel;
  final int cycles;
  final int itemsUnlocked;
  final Duration totalPlayTime;

  bool dominates(CloudProgressVector other) {
    final allAtLeast = ascensions >= other.ascensions &&
        totalAura >= other.totalAura &&
        auraLevel >= other.auraLevel &&
        cycles >= other.cycles &&
        itemsUnlocked >= other.itemsUnlocked &&
        totalPlayTime >= other.totalPlayTime;
    final oneGreater = ascensions > other.ascensions ||
        totalAura > other.totalAura ||
        auraLevel > other.auraLevel ||
        cycles > other.cycles ||
        itemsUnlocked > other.itemsUnlocked ||
        totalPlayTime > other.totalPlayTime;
    return allAtLeast && oneGreater;
  }
}
