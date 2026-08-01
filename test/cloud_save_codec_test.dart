import 'dart:convert';

import 'package:aura_shift_six_seven/cloud_save/cloud_save_envelope.dart';
import 'package:aura_shift_six_seven/cloud_save/game_save_migration_service.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cloud_save_test_support.dart';

void main() {
  const codec = GameSaveCodec();

  group('GameSaveCodec', () {
    test('canonical encoding and payload hash are deterministic', () {
      final first = validGameState(
        total: 67,
        appearances: const <String>['ITEM-B-01', 'ITEM-A-01'],
        levels: const <String, int>{'ITEM-B-01': 2, 'TECH-01': 1},
      );
      final second = <String, dynamic>{
        for (final entry in first.entries.toList().reversed)
          entry.key: entry.value,
      };
      second['appearances'] = <String>['ITEM-A-01', 'ITEM-B-01'];
      second['levels'] = <String, int>{'TECH-01': 1, 'ITEM-B-01': 2};

      final firstEnvelope = envelopeFor(state: first);
      final secondEnvelope = envelopeFor(state: second);

      expect(firstEnvelope.payloadHash, secondEnvelope.payloadHash);
      expect(codec.encode(firstEnvelope),
          orderedEquals(codec.encode(secondEnvelope)));
      expect(
        firstEnvelope.payloadHash,
        GameSaveCodec.payloadHash(firstEnvelope.gameState),
      );
    });

    test('round-trips the versioned envelope without losing metadata', () {
      final envelope = envelopeFor(
        state: validGameState(total: 6700, totalPlayTimeMillis: 1234),
        revision: 7,
        parentPayloadHash: 'a' * 64,
        totalPlayTime: const Duration(milliseconds: 1234),
      );

      final decoded = codec.decode(codec.encode(envelope));

      expect(decoded.schemaVersion, cloudSaveSchemaVersion);
      expect(decoded.saveId, envelope.saveId);
      expect(decoded.revision, 7);
      expect(decoded.installationId, envelope.installationId);
      expect(decoded.parentPayloadHash, 'a' * 64);
      expect(decoded.payloadHash, envelope.payloadHash);
      expect(decoded.savedAtUtc, envelope.savedAtUtc);
      expect(decoded.totalPlayTime, const Duration(milliseconds: 1234));
      expect(decoded.gameState, envelope.gameState);
    });

    test('decodes a canonical balance-v0.3 envelope for migration', () {
      final state = validGameState()
        ..addAll(<String, dynamic>{
          'balanceVersion': 'balance-v0.3',
          'available': '0',
          'journey': '0',
          'total': '81000000000000000',
          'multiplier': '1000',
          'ascensions': 10,
          'ascensionAura': '81000000000000000',
        });
      final at = DateTime.utc(2026, 7, 26);
      final envelope = CloudSaveEnvelope(
        schemaVersion: cloudSaveSchemaVersion,
        saveId: 'legacy-v03',
        revision: 1,
        installationId: 'legacy-installation',
        payloadHash: GameSaveCodec.payloadHash(state),
        savedAtUtc: at,
        lastActiveAtUtc: at,
        totalPlayTime: Duration.zero,
        gameState: state,
      );

      final decoded = codec.decode(codec.encode(envelope));

      expect(decoded.gameState['balanceVersion'], 'balance-v0.3');
      expect(decoded.gameState['ascensionAura'], '81000000000000000');
      expect(decoded.gameState['multiplier'], '1000');
    });

    test('rejects payloads above the strict 3 MiB limit', () {
      final state = validGameState()..['padding'] = 'x' * cloudSaveMaximumBytes;
      final envelope = envelopeFor(state: state);

      expect(
        () => codec.encode(envelope),
        throwsA(
          isA<CloudSaveValidationException>().having(
            (error) => error.failure,
            'failure',
            CloudSaveValidationFailure.sizeLimit,
          ),
        ),
      );
      expect(
        () => codec.decode(List<int>.filled(cloudSaveMaximumBytes + 1, 0)),
        throwsA(
          isA<CloudSaveValidationException>().having(
            (error) => error.failure,
            'failure',
            CloudSaveValidationFailure.sizeLimit,
          ),
        ),
      );
    });

    test('rejects a future schema before attempting restoration', () {
      final envelope = envelopeFor(state: validGameState());
      final json = (jsonDecode(utf8.decode(codec.encode(envelope))) as Map)
          .cast<String, dynamic>()
        ..['schemaVersion'] = cloudSaveSchemaVersion + 1;

      expect(
        () => codec.decode(utf8.encode(jsonEncode(json))),
        throwsA(
          isA<CloudSaveValidationException>().having(
            (error) => error.failure,
            'failure',
            CloudSaveValidationFailure.unsupportedSchema,
          ),
        ),
      );
    });

    test('rejects tampering through the SHA-256 payload hash', () {
      final envelope = envelopeFor(state: validGameState(total: 67));
      final json = (jsonDecode(utf8.decode(codec.encode(envelope))) as Map)
          .cast<String, dynamic>();
      final gameState = (json['gameState'] as Map).cast<String, dynamic>()
        ..['total'] = '68';
      json['gameState'] = gameState;

      expect(
        () => codec.decode(utf8.encode(jsonEncode(json))),
        throwsA(
          isA<CloudSaveValidationException>().having(
            (error) => error.failure,
            'failure',
            CloudSaveValidationFailure.hashMismatch,
          ),
        ),
      );
    });

    test('rejects invalid economic and collection invariants', () {
      final invalidStates = <Map<String, dynamic>>[
        validGameState(total: 10)..['available'] = '11',
        validGameState()..['remainder'] = '10000000',
        validGameState()..['levels'] = <String, int>{'UNKNOWN': 1},
        validGameState()
          ..['appearances'] = <String>[]
          ..['equippedAppearances'] = <String>['ITEM-A-01'],
        validGameState()..['achievements'] = <String>['ACH-UNKNOWN'],
      ];

      for (final state in invalidStates) {
        expect(
          () => envelopeFor(state: state),
          throwsA(
            isA<CloudSaveValidationException>().having(
              (error) => error.failure,
              'failure',
              CloudSaveValidationFailure.invalidGameState,
            ),
          ),
        );
      }
    });

    test('normalization strips device-only and transient fields', () {
      final state = validGameState()
        ..addAll(<String, dynamic>{
          'analyticsEnabled': true,
          'analyticsDecided': true,
          'returnReminderEnabled': true,
          'returnReminderPrompted': true,
          'storeReviewRequested': true,
          'rewardedUpgradeQuote': <String, Object>{'id': 'ITEM-A-01'},
          'sixStartedAt': 123,
          'exportedAt': 'legacy',
        });

      final normalized = codec.normalizeGameState(state);

      expect(
        normalized.keys,
        isNot(containsAll(<String>[
          'analyticsEnabled',
          'analyticsDecided',
          'returnReminderEnabled',
          'returnReminderPrompted',
          'storeReviewRequested',
          'rewardedUpgradeQuote',
          'sixStartedAt',
          'exportedAt',
        ])),
      );
    });
  });

  group('GameSaveMigrationService', () {
    const migration = GameSaveMigrationService();

    test('migration is idempotent and fills legacy defaults', () {
      final once = migration.migrate(<String, dynamic>{
        'total': '67',
        'available': '67',
        'journey': '67',
        'equipped': 'ITEM-A-01',
        'appearances': <String>['ITEM-A-01'],
      });
      final twice = migration.migrate(once);

      expect(GameSaveCodec.canonicalJson(twice),
          GameSaveCodec.canonicalJson(once));
      expect(once['saveVersion'], 1);
      expect(once['arithVersion'], 'arith-v1');
      expect(once['balanceVersion'], isNotEmpty);
      expect(once['equipped'], isNull);
      expect(once['equippedAppearances'], <String>['ITEM-A-01']);
      expect(once['levels'], isEmpty);
      expect(once['totalPlayTimeMillis'], 0);
    });

    test('balance-v0.3 migration preserves L and applies the new curve', () {
      final migrated = migration.migrate(<String, dynamic>{
        'saveVersion': 1,
        'arithVersion': 'arith-v1',
        'balanceVersion': 'balance-v0.3',
        'available': '0',
        'journey': '0',
        'total': '81000000000000000',
        'remainder': '0',
        'multiplier': '1000',
        'ascensions': 10,
        'ascensionAura': '81000000000000000',
      });

      expect(migrated['balanceVersion'], balanceVersion);
      expect(migrated['ascensionAura'], '81000000000000000');
      expect(migrated['multiplier'], '675');
    });
  });
}
