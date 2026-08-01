import 'cloud_save_envelope.dart';

enum CloudConflictDecision {
  equivalent,
  first,
  second,
  ambiguous,
}

class CloudConflictResolution {
  const CloudConflictResolution(this.decision, {this.selected});

  final CloudConflictDecision decision;
  final CloudSaveEnvelope? selected;
}

/// Chooses whole saves only. No field-level merge is ever performed.
class CloudConflictResolver {
  const CloudConflictResolver();

  CloudConflictResolution resolve(
    CloudSaveEnvelope first,
    CloudSaveEnvelope second,
  ) {
    if (first.payloadHash == second.payloadHash) {
      final selected = first.revision > second.revision
          ? first
          : second.revision > first.revision
              ? second
              : first.savedAtUtc.isAfter(second.savedAtUtc)
                  ? first
                  : second;
      return CloudConflictResolution(
        CloudConflictDecision.equivalent,
        selected: selected,
      );
    }

    if (first.parentPayloadHash == second.payloadHash &&
        first.revision > second.revision) {
      return CloudConflictResolution(
        CloudConflictDecision.first,
        selected: first,
      );
    }
    if (second.parentPayloadHash == first.payloadHash &&
        second.revision > first.revision) {
      return CloudConflictResolution(
        CloudConflictDecision.second,
        selected: second,
      );
    }

    final firstProgress = CloudProgressVector.fromEnvelope(first);
    final secondProgress = CloudProgressVector.fromEnvelope(second);
    if (firstProgress.dominates(secondProgress)) {
      return CloudConflictResolution(
        CloudConflictDecision.first,
        selected: first,
      );
    }
    if (secondProgress.dominates(firstProgress)) {
      return CloudConflictResolution(
        CloudConflictDecision.second,
        selected: second,
      );
    }
    return const CloudConflictResolution(CloudConflictDecision.ambiguous);
  }
}
