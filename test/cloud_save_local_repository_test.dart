import 'dart:convert';

import 'package:aura_shift_six_seven/cloud_save/cloud_save_envelope.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_save_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('falls back to the last valid cloud envelope after local corruption',
      () async {
    const codec = GameSaveCodec();
    final lastValid = envelopeFor(
      state: validGameState(total: 67),
      revision: 6,
    );
    final harness = await CloudSaveHarness.create(
      preferences: <String, Object>{
        'cloud-save-envelope-v1': '{corrupt',
        'cloud-save-envelope-last-valid-v1':
            utf8.decode(codec.encode(lastValid)),
      },
    );
    addTearDown(harness.dispose);

    final restored = await harness.local.readEnvelope();

    expect(restored, isNotNull);
    expect(restored!.payloadHash, lastValid.payloadHash);
    expect(restored.revision, 6);
    expect(restored.gameState['total'], '67');
  });

  test('the immediate local save also restores its last valid checkpoint',
      () async {
    final lastValid = validGameState(total: 6700);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'save-v1': '{corrupt',
      'save-v1-last-valid': jsonEncode(lastValid),
    });

    final controller = await GameController.loadForTesting();
    addTearDown(controller.dispose);
    final preferences = await SharedPreferences.getInstance();

    expect(controller.total, BigInt.from(6700));
    expect(
      jsonDecode(preferences.getString('save-v1')!)['total'],
      '6700',
    );
  });

  test('capture keeps a stable revision until the game state changes',
      () async {
    final harness = await CloudSaveHarness.create(
      gameState: validGameState(total: 1),
      preferences: const <String, Object>{
        'cloud-save-installation-id': 'stable-installation',
      },
    );
    addTearDown(harness.dispose);
    final now = DateTime.utc(2026, 7, 27, 12);

    final first = await harness.local.captureCurrent(nowUtc: now);
    final unchanged = await harness.local.captureCurrent(nowUtc: now);

    expect(first.installationId, 'stable-installation');
    expect(unchanged.revision, first.revision);
    expect(unchanged.payloadHash, first.payloadHash);

    harness.controller.tap();
    await harness.controller.flushLocal();
    final changed = await harness.local.captureCurrent(
      nowUtc: now.add(const Duration(seconds: 1)),
    );

    expect(changed.revision, first.revision + 1);
    expect(changed.parentPayloadHash, first.payloadHash);
    expect(changed.payloadHash, isNot(first.payloadHash));
    expect(harness.local.hasPendingChanges, isTrue);
  });
}
