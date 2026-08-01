import 'package:aura_shift_six_seven/cloud_save/cloud_conflict_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cloud_save_test_support.dart';

void main() {
  const resolver = CloudConflictResolver();

  test('equal payloads are equivalent and prefer newer metadata', () {
    final older = envelopeFor(
      state: validGameState(total: 67),
      revision: 1,
      savedAtUtc: DateTime.utc(2026, 7, 27, 10),
    );
    final newer = envelopeFor(
      state: validGameState(total: 67),
      revision: 2,
      savedAtUtc: DateTime.utc(2026, 7, 27, 11),
    );

    final resolution = resolver.resolve(older, newer);

    expect(resolution.decision, CloudConflictDecision.equivalent);
    expect(resolution.selected, same(newer));
  });

  test('direct ancestry chooses the descendant whole save', () {
    final parent = envelopeFor(
      state: validGameState(total: 67),
      revision: 4,
    );
    final child = envelopeFor(
      state: validGameState(total: 68),
      revision: 5,
      parentPayloadHash: parent.payloadHash,
    );

    final forward = resolver.resolve(child, parent);
    final reverse = resolver.resolve(parent, child);

    expect(forward.decision, CloudConflictDecision.first);
    expect(forward.selected, same(child));
    expect(reverse.decision, CloudConflictDecision.second);
    expect(reverse.selected, same(child));
  });

  test('monotonic dominance chooses the save ahead in every dimension', () {
    final behind = envelopeFor(
      state: validGameState(
        total: 67,
        cycles: 1,
        totalPlayTimeMillis: const Duration(minutes: 2).inMilliseconds,
      ),
      totalPlayTime: const Duration(minutes: 2),
    );
    final ahead = envelopeFor(
      state: validGameState(
        total: 6700,
        cycles: 2,
        totalPlayTimeMillis: const Duration(minutes: 3).inMilliseconds,
        appearances: const <String>['ITEM-A-01'],
      ),
      totalPlayTime: const Duration(minutes: 3),
    );

    final resolution = resolver.resolve(behind, ahead);

    expect(resolution.decision, CloudConflictDecision.second);
    expect(resolution.selected, same(ahead));
  });

  test('trade-offs remain ambiguous and never create a field-level merge', () {
    final moreAura = envelopeFor(
      state: validGameState(
        total: 6700,
        totalPlayTimeMillis: const Duration(minutes: 1).inMilliseconds,
      ),
      totalPlayTime: const Duration(minutes: 1),
    );
    final moreTime = envelopeFor(
      state: validGameState(
        total: 67,
        totalPlayTimeMillis: const Duration(hours: 1).inMilliseconds,
      ),
      totalPlayTime: const Duration(hours: 1),
    );

    final resolution = resolver.resolve(moreAura, moreTime);

    expect(resolution.decision, CloudConflictDecision.ambiguous);
    expect(resolution.selected, isNull);
    expect(moreAura.gameState['total'], '6700');
    expect(moreTime.totalPlayTime, const Duration(hours: 1));
  });
}
