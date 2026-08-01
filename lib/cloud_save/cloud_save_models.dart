import 'cloud_save_envelope.dart';

enum CloudSyncReason {
  startup,
  automatic,
  manual,
  pause,
  resume,
  priority,
  conflictResolution,
}

enum CloudSaveErrorType {
  unauthenticated,
  unsupportedPlatform,
  notConfigured,
  offline,
  timeout,
  remoteMissing,
  corruptSave,
  unsupportedSchema,
  conflictPending,
  commitFailed,
  sizeLimit,
  busy,
  unknown,
}

enum CloudSaveCandidateOrigin {
  thisDevice,
  cloud,
  otherDevice,
}

sealed class CloudSaveState {
  const CloudSaveState();

  bool get hasPendingChanges => false;
}

class CloudSaveUnavailable extends CloudSaveState {
  const CloudSaveUnavailable({
    this.type = CloudSaveErrorType.unsupportedPlatform,
  });

  final CloudSaveErrorType type;
}

class CloudSaveUnauthenticated extends CloudSaveState {
  const CloudSaveUnauthenticated({this.pending = true});

  final bool pending;

  @override
  bool get hasPendingChanges => pending;
}

class CloudSaveLocalOnly extends CloudSaveState {
  const CloudSaveLocalOnly({this.pending = false});

  final bool pending;

  @override
  bool get hasPendingChanges => pending;
}

class CloudSaveSyncing extends CloudSaveState {
  const CloudSaveSyncing({this.pending = true});

  final bool pending;

  @override
  bool get hasPendingChanges => pending;
}

class CloudSaveSynced extends CloudSaveState {
  const CloudSaveSynced({
    required this.syncedAt,
    required this.playerId,
    this.playerName,
    this.pending = false,
  });

  final DateTime syncedAt;
  final String playerId;
  final String? playerName;
  final bool pending;

  @override
  bool get hasPendingChanges => pending;
}

class CloudSavePending extends CloudSaveState {
  const CloudSavePending({
    this.type,
    this.lastAttemptAt,
  });

  final CloudSaveErrorType? type;
  final DateTime? lastAttemptAt;

  @override
  bool get hasPendingChanges => true;
}

class CloudSaveOffline extends CloudSaveState {
  const CloudSaveOffline();

  @override
  bool get hasPendingChanges => true;
}

class CloudSaveConflictPending extends CloudSaveState {
  const CloudSaveConflictPending(this.conflict);

  final CloudSaveConflict conflict;

  @override
  bool get hasPendingChanges => true;
}

class CloudSaveFailure extends CloudSaveState {
  const CloudSaveFailure({
    required this.type,
    required this.retryable,
    this.message,
  });

  final CloudSaveErrorType type;
  final bool retryable;
  final String? message;

  @override
  bool get hasPendingChanges => retryable;
}

class CloudSaveInitializationResult {
  const CloudSaveInitializationResult({
    required this.state,
    this.restoredRemote = false,
  });

  final CloudSaveState state;
  final bool restoredRemote;
}

class CloudSyncResult {
  const CloudSyncResult({
    required this.state,
    this.uploaded = false,
    this.restored = false,
  });

  final CloudSaveState state;
  final bool uploaded;
  final bool restored;

  bool get succeeded => state is CloudSaveSynced;
}

class CloudSaveProgressSummary {
  const CloudSaveProgressSummary({
    required this.savedAtUtc,
    required this.auraLevel,
    required this.totalAura,
    required this.auraPerSecond,
    required this.ascensions,
    required this.itemsUnlocked,
    required this.totalPlayTime,
    this.deviceName,
  });

  final DateTime savedAtUtc;
  final int auraLevel;
  final BigInt totalAura;
  final BigInt auraPerSecond;
  final int ascensions;
  final int itemsUnlocked;
  final Duration totalPlayTime;
  final String? deviceName;
}

class CloudSaveCandidate {
  const CloudSaveCandidate({
    required this.id,
    required this.origin,
    required this.envelope,
    required this.summary,
  });

  final String id;
  final CloudSaveCandidateOrigin origin;
  final CloudSaveEnvelope envelope;
  final CloudSaveProgressSummary summary;
}

class CloudSaveConflict {
  const CloudSaveConflict({
    required this.first,
    this.second,
    this.additional = const [],
    this.recommendedCandidateId,
    this.nativeConflictToken,
    this.accountSwitch = false,
    this.playerId,
    this.playerName,
  });

  final CloudSaveCandidate first;
  final CloudSaveCandidate? second;
  final List<CloudSaveCandidate> additional;
  final String? recommendedCandidateId;
  final String? nativeConflictToken;
  final bool accountSwitch;
  final String? playerId;
  final String? playerName;

  List<CloudSaveCandidate> get candidates => [
        first,
        if (second != null) second!,
        ...additional,
      ];
}

abstract interface class CloudSaveService {
  Stream<CloudSaveState> watchState();

  CloudSaveState get state;

  Future<CloudSaveInitializationResult> initialize();

  Future<CloudSyncResult> synchronize({
    CloudSyncReason reason = CloudSyncReason.automatic,
  });

  Future<CloudSyncResult> uploadCurrentSave();

  Future<CloudSyncResult> retry();

  Future<void> onAppPaused();

  Future<void> onAppResumed();
}
