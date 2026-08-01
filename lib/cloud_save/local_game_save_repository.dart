import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_controller.dart';
import 'cloud_save_envelope.dart';
import 'game_save_migration_service.dart';

class LocalGameSaveRepository {
  LocalGameSaveRepository({
    required GameController controller,
    required SharedPreferences preferences,
    GameSaveCodec codec = const GameSaveCodec(),
    GameSaveMigrationService migration = const GameSaveMigrationService(),
  })  : _controller = controller,
        _preferences = preferences,
        _codec = codec,
        _migration = migration;

  static const _envelopeKey = 'cloud-save-envelope-v1';
  static const _lastValidEnvelopeKey = 'cloud-save-envelope-last-valid-v1';
  static const _installationIdKey = 'cloud-save-installation-id';
  static const _ownerPlayerIdKey = 'cloud-save-owner-player-id';
  static const _pendingKey = 'cloud-save-pending';
  static const _lastSyncKey = 'cloud-save-last-sync-at';
  static const _migrationVersionKey = 'cloudSaveMigrationVersion';

  final GameController _controller;
  final SharedPreferences _preferences;
  final GameSaveCodec _codec;
  final GameSaveMigrationService _migration;
  Future<void> _writeQueue = Future.value();
  String? _installationId;

  String get installationId {
    final cached = _installationId;
    if (cached != null) return cached;
    final existing = _preferences.getString(_installationIdKey);
    if (existing != null && existing.isNotEmpty) {
      _installationId = existing;
      return existing;
    }
    final created = _randomId('install');
    _installationId = created;
    unawaitedWrite(_preferences.setString(_installationIdKey, created));
    return created;
  }

  String? get ownerPlayerId => _preferences.getString(_ownerPlayerIdKey);

  bool get hasPendingChanges => _preferences.getBool(_pendingKey) ?? true;

  DateTime? get lastSuccessfulSync =>
      DateTime.tryParse(_preferences.getString(_lastSyncKey) ?? '')?.toUtc();

  int get migrationVersion => _preferences.getInt(_migrationVersionKey) ?? 0;

  bool get hasSignificantProgress =>
      _controller.total > BigInt.zero ||
      _controller.cycles > 0 ||
      _controller.ascensions > 0 ||
      _controller.levels.values.any((level) => level > 0) ||
      _controller.appearances.isNotEmpty;

  Future<CloudSaveEnvelope?> readEnvelope() async {
    for (final key in const [_envelopeKey, _lastValidEnvelopeKey]) {
      final raw = _preferences.getString(key);
      if (raw == null) continue;
      try {
        return _codec.decode(utf8.encode(raw));
      } on CloudSaveValidationException {
        continue;
      }
    }
    return null;
  }

  Future<CloudSaveEnvelope> captureCurrent({
    required DateTime nowUtc,
    bool forceRevision = false,
  }) async {
    final current = await readEnvelope();
    final state = _migration.migrate(_controller.captureSaveState());
    final currentHash = GameSaveCodec.payloadHash(state);
    if (!forceRevision &&
        current != null &&
        current.payloadHash == currentHash) {
      return current;
    }

    final offlineAt = state['offlineAt'];
    final lastActiveAt = offlineAt is int
        ? DateTime.fromMillisecondsSinceEpoch(
            offlineAt,
            isUtc: true,
          )
        : nowUtc.toUtc();
    final envelope = _codec.create(
      saveId: current?.saveId ?? _randomId('save'),
      revision: (current?.revision ?? 0) + 1,
      installationId: installationId,
      parentPayloadHash: current?.payloadHash,
      savedAtUtc: nowUtc.toUtc(),
      lastActiveAtUtc: lastActiveAt,
      totalPlayTime: Duration(
        milliseconds: _controller.totalPlayTimeMilliseconds,
      ),
      gameState: state,
    );
    await writeEnvelope(envelope, pending: true);
    return envelope;
  }

  Future<bool> applyEnvelope(
    CloudSaveEnvelope envelope, {
    required bool pending,
  }) async {
    _codec.validateEnvelope(envelope);
    final restored = await _controller.replaceAuthoritativeState(
      _migration.migrate(envelope.gameState),
    );
    if (!restored) return false;
    await writeEnvelope(envelope, pending: pending);
    return true;
  }

  Future<void> writeEnvelope(
    CloudSaveEnvelope envelope, {
    required bool pending,
  }) async {
    final serialized = utf8.decode(_codec.encode(envelope));
    _writeQueue = _writeQueue.then((_) async {
      final current = _preferences.getString(_envelopeKey);
      if (current != null && current != serialized) {
        await _preferences.setString(_lastValidEnvelopeKey, current);
      }
      await _preferences.setString(_envelopeKey, serialized);
      await _preferences.setBool(_pendingKey, pending);
    });
    await _writeQueue;
  }

  Future<void> setPending(bool value) async {
    _writeQueue =
        _writeQueue.then((_) => _preferences.setBool(_pendingKey, value));
    await _writeQueue;
  }

  Future<void> bindOwner(String playerId) async {
    _writeQueue = _writeQueue.then(
      (_) => _preferences.setString(_ownerPlayerIdKey, playerId),
    );
    await _writeQueue;
  }

  Future<void> markMigrationComplete() async {
    _writeQueue = _writeQueue.then(
      (_) => _preferences.setInt(
        _migrationVersionKey,
        cloudSaveSchemaVersion,
      ),
    );
    await _writeQueue;
  }

  Future<void> markSynced(
    DateTime atUtc, {
    bool pending = false,
  }) async {
    _writeQueue = _writeQueue.then((_) async {
      await _preferences.setBool(_pendingKey, pending);
      await _preferences.setString(
        _lastSyncKey,
        atUtc.toUtc().toIso8601String(),
      );
    });
    await _writeQueue;
  }

  Future<void> flush() async {
    await _controller.flushLocal();
    await _writeQueue;
  }

  void unawaitedWrite(Future<bool> write) {
    _writeQueue = _writeQueue.then((_) async {
      await write;
    });
  }

  static String _randomId(String prefix) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final body =
        bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '$prefix-$body';
  }
}
