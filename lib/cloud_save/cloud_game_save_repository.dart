import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cloud_save_envelope.dart';
import 'cloud_save_models.dart';

const cloudSaveSlotName = 'aura_shift_primary';

class CloudRemoteMetadata {
  const CloudRemoteMetadata({
    this.snapshotId,
    this.description,
    this.deviceName,
    this.lastModifiedAt,
    this.playedTime = Duration.zero,
    this.progressValue = 0,
  });

  factory CloudRemoteMetadata.fromMap(Map<Object?, Object?> map) =>
      CloudRemoteMetadata(
        snapshotId: _nullableText(map['snapshotId']),
        description: _nullableText(map['description']),
        deviceName: _nullableText(map['deviceName']),
        lastModifiedAt: map['lastModifiedAtMs'] is num
            ? DateTime.fromMillisecondsSinceEpoch(
                (map['lastModifiedAtMs'] as num).toInt(),
                isUtc: true,
              )
            : null,
        playedTime: Duration(
          milliseconds: (map['playedTimeMs'] as num?)?.toInt() ?? 0,
        ),
        progressValue: (map['progressValue'] as num?)?.toInt() ?? 0,
      );

  final String? snapshotId;
  final String? description;
  final String? deviceName;
  final DateTime? lastModifiedAt;
  final Duration playedTime;
  final int progressValue;
}

class CloudRemoteSnapshot {
  const CloudRemoteSnapshot({
    required this.payload,
    required this.metadata,
  });

  final Uint8List payload;
  final CloudRemoteMetadata metadata;
}

sealed class CloudRemoteResult {
  const CloudRemoteResult();
}

class CloudRemoteMissing extends CloudRemoteResult {
  const CloudRemoteMissing();
}

class CloudRemoteData extends CloudRemoteResult {
  const CloudRemoteData(this.snapshot);

  final CloudRemoteSnapshot snapshot;
}

class CloudRemoteConflict extends CloudRemoteResult {
  const CloudRemoteConflict({
    required this.token,
    required this.server,
    required this.conflicting,
  });

  final String token;
  final CloudRemoteSnapshot server;
  final CloudRemoteSnapshot conflicting;
}

class CloudRepositoryException implements Exception {
  const CloudRepositoryException(
    this.type, {
    this.message,
    this.retryable = true,
  });

  final CloudSaveErrorType type;
  final String? message;
  final bool retryable;
}

abstract interface class CloudGameSaveRepository {
  bool get supported;

  Future<int> maximumPayloadBytes();

  Future<CloudRemoteResult> open();

  Future<CloudRemoteResult> commit({
    required Uint8List payload,
    required String description,
    required Duration playedTime,
    required int progressValue,
  });

  Future<CloudRemoteResult> resolveConflict({
    required String token,
    required Uint8List payload,
    required String description,
    required Duration playedTime,
    required int progressValue,
  });

  Future<void> abandonConflict(String token);
}

CloudGameSaveRepository createCloudGameSaveRepository() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const UnsupportedCloudGameSaveRepository();
  }
  return MethodChannelCloudGameSaveRepository();
}

class UnsupportedCloudGameSaveRepository implements CloudGameSaveRepository {
  const UnsupportedCloudGameSaveRepository();

  @override
  bool get supported => false;

  @override
  Future<int> maximumPayloadBytes() async => cloudSaveMaximumBytes;

  @override
  Future<CloudRemoteResult> open() async =>
      throw const CloudRepositoryException(
        CloudSaveErrorType.unsupportedPlatform,
        retryable: false,
      );

  @override
  Future<CloudRemoteResult> commit({
    required Uint8List payload,
    required String description,
    required Duration playedTime,
    required int progressValue,
  }) =>
      open();

  @override
  Future<CloudRemoteResult> resolveConflict({
    required String token,
    required Uint8List payload,
    required String description,
    required Duration playedTime,
    required int progressValue,
  }) =>
      open();

  @override
  Future<void> abandonConflict(String token) async {}
}

class MethodChannelCloudGameSaveRepository implements CloudGameSaveRepository {
  MethodChannelCloudGameSaveRepository({
    MethodChannel channel = const MethodChannel(
      'com.otaciliomaia.aurashiftsixseven/play_games',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  bool get supported => true;

  @override
  Future<int> maximumPayloadBytes() async => cloudSaveMaximumBytes;

  @override
  Future<CloudRemoteResult> open() async {
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'cloudSaveOpen',
      );
      return _parse(raw);
    } on PlatformException catch (error) {
      throw _exception(error);
    } on MissingPluginException {
      throw const CloudRepositoryException(
        CloudSaveErrorType.unsupportedPlatform,
        retryable: false,
      );
    }
  }

  @override
  Future<CloudRemoteResult> commit({
    required Uint8List payload,
    required String description,
    required Duration playedTime,
    required int progressValue,
  }) async {
    _checkPayload(payload);
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'cloudSaveCommit',
        _writeArguments(
          payload,
          description,
          playedTime,
          progressValue,
        ),
      );
      return _parse(raw, committedPayload: payload);
    } on PlatformException catch (error) {
      throw _exception(error);
    } on MissingPluginException {
      throw const CloudRepositoryException(
        CloudSaveErrorType.unsupportedPlatform,
        retryable: false,
      );
    }
  }

  @override
  Future<CloudRemoteResult> resolveConflict({
    required String token,
    required Uint8List payload,
    required String description,
    required Duration playedTime,
    required int progressValue,
  }) async {
    _checkPayload(payload);
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'cloudSaveResolveConflict',
        <String, Object?>{
          'conflictToken': token,
          ..._writeArguments(
            payload,
            description,
            playedTime,
            progressValue,
          ),
        },
      );
      return _parse(raw, committedPayload: payload);
    } on PlatformException catch (error) {
      throw _exception(error);
    } on MissingPluginException {
      throw const CloudRepositoryException(
        CloudSaveErrorType.unsupportedPlatform,
        retryable: false,
      );
    }
  }

  @override
  Future<void> abandonConflict(String token) async {
    try {
      await _channel.invokeMethod<void>(
        'cloudSaveAbandonConflict',
        <String, Object?>{'conflictToken': token},
      );
    } on PlatformException {
      // Abandonment is best-effort; reopening the slot recreates the conflict.
    } on MissingPluginException {
      // No native handle exists on unsupported platforms.
    }
  }

  Map<String, Object?> _writeArguments(
    Uint8List payload,
    String description,
    Duration playedTime,
    int progressValue,
  ) =>
      <String, Object?>{
        'payload': payload,
        'description': description,
        'playedTimeMs': playedTime.inMilliseconds,
        'progressValue': progressValue,
      };

  CloudRemoteResult _parse(
    Map<Object?, Object?>? raw, {
    Uint8List? committedPayload,
  }) {
    if (raw == null) {
      throw const CloudRepositoryException(CloudSaveErrorType.unknown);
    }
    switch (raw['kind']) {
      case 'missing':
        return const CloudRemoteMissing();
      case 'snapshot':
      case 'committed':
      case 'resolved':
        if (raw['kind'] == 'snapshot' && raw['exists'] == false) {
          return const CloudRemoteMissing();
        }
        final payload =
            raw['payload'] as Uint8List? ?? committedPayload ?? Uint8List(0);
        if (payload.isEmpty && raw['kind'] == 'snapshot') {
          return const CloudRemoteMissing();
        }
        return CloudRemoteData(CloudRemoteSnapshot(
          payload: payload,
          metadata: CloudRemoteMetadata.fromMap(
            (raw['metadata'] as Map? ?? const <Object?, Object?>{})
                .cast<Object?, Object?>(),
          ),
        ));
      case 'conflict':
        return CloudRemoteConflict(
          token: '${raw['conflictToken'] ?? ''}',
          server: _snapshotFrom(raw['server']),
          conflicting: _snapshotFrom(raw['conflicting']),
        );
      default:
        throw const CloudRepositoryException(CloudSaveErrorType.unknown);
    }
  }

  CloudRemoteSnapshot _snapshotFrom(Object? raw) {
    if (raw is! Map || raw['payload'] is! Uint8List) {
      throw const CloudRepositoryException(CloudSaveErrorType.corruptSave);
    }
    return CloudRemoteSnapshot(
      payload: raw['payload'] as Uint8List,
      metadata: CloudRemoteMetadata.fromMap(
        (raw['metadata'] as Map? ?? const <Object?, Object?>{})
            .cast<Object?, Object?>(),
      ),
    );
  }

  void _checkPayload(Uint8List payload) {
    if (payload.length > cloudSaveMaximumBytes) {
      throw const CloudRepositoryException(
        CloudSaveErrorType.sizeLimit,
        retryable: false,
      );
    }
  }

  CloudRepositoryException _exception(PlatformException error) {
    final type = switch (error.code) {
      'unauthenticated' => CloudSaveErrorType.unauthenticated,
      'unsupported' => CloudSaveErrorType.unsupportedPlatform,
      'not_configured' => CloudSaveErrorType.notConfigured,
      'offline' => CloudSaveErrorType.offline,
      'timeout' => CloudSaveErrorType.timeout,
      'not_found' => CloudSaveErrorType.remoteMissing,
      'content_unavailable' => CloudSaveErrorType.corruptSave,
      'contents_unavailable' => CloudSaveErrorType.corruptSave,
      'write_failed' => CloudSaveErrorType.commitFailed,
      'commit_failed' => CloudSaveErrorType.commitFailed,
      'payload_too_large' => CloudSaveErrorType.sizeLimit,
      'size_limit' => CloudSaveErrorType.sizeLimit,
      'conflict_expired' => CloudSaveErrorType.conflictPending,
      'conflict_pending' => CloudSaveErrorType.conflictPending,
      'busy' => CloudSaveErrorType.busy,
      _ => CloudSaveErrorType.unknown,
    };
    return CloudRepositoryException(
      type,
      message: error.message,
      retryable: type != CloudSaveErrorType.unsupportedPlatform &&
          type != CloudSaveErrorType.notConfigured &&
          type != CloudSaveErrorType.sizeLimit,
    );
  }
}

String? _nullableText(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}
