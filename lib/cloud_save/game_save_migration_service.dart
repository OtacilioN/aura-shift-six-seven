import 'dart:convert';

import '../core/ascension_curve.dart';
import '../core/game_controller.dart';
import 'cloud_save_envelope.dart';

const _migrationAscensionScale = 100000000000;

/// Idempotent migration boundary between the long-lived local `save-v1`
/// representation and the current cloud payload schema.
class GameSaveMigrationService {
  const GameSaveMigrationService({GameSaveCodec codec = const GameSaveCodec()})
      : _codec = codec;

  final GameSaveCodec _codec;

  Map<String, dynamic> migrate(Map<String, dynamic> source) {
    final state =
        (jsonDecode(jsonEncode(source)) as Map).cast<String, dynamic>();
    final sourceBalanceVersion = state['balanceVersion'];
    final sourceAscensionAura =
        BigInt.tryParse('${state['ascensionAura'] ?? ''}');
    state
      ..['saveVersion'] = 1
      ..['arithVersion'] = 'arith-v1'
      ..['balanceVersion'] = balanceVersion
      ..putIfAbsent('available', () => '0')
      ..putIfAbsent('total', () => '0')
      ..putIfAbsent('journey', () => '0')
      ..putIfAbsent('remainder', () => '0')
      ..putIfAbsent('multiplier', () => '100')
      ..putIfAbsent('ascensionAura', () => '0')
      ..putIfAbsent('maxAuraPerMovement', () => '0')
      ..putIfAbsent('cycles', () => 0)
      ..putIfAbsent('ascensions', () => 0)
      ..putIfAbsent('levels', () => <String, int>{})
      ..putIfAbsent('achievements', () => <String>[])
      ..putIfAbsent('appearances', () => <String>[])
      ..putIfAbsent('transformations', () => <String>[])
      ..putIfAbsent('seals', () => <String>[])
      ..putIfAbsent('totalPlayTimeMillis', () => 0);

    final ascensions =
        state['ascensions'] is int ? state['ascensions'] as int : 0;
    var ascensionAura = sourceAscensionAura;
    if (ascensionAura == null || ascensionAura.isNegative) {
      final multiplier =
          BigInt.tryParse('${state['multiplier'] ?? 100}') ?? BigInt.from(100);
      final bonus = multiplier > BigInt.from(100)
          ? multiplier - BigInt.from(100)
          : BigInt.zero;
      final estimate = sourceBalanceVersion == balanceVersion
          ? AscensionCurve.auraForMultiplier(multiplier)
          : ascensions > 0
              ? bonus *
                  bonus *
                  BigInt.from(_migrationAscensionScale) ~/
                  BigInt.from(ascensions)
              : bonus * bonus * BigInt.from(_migrationAscensionScale);
      final minimum = BigInt.from(ascensions) * BigInt.from(ascensionThreshold);
      ascensionAura = estimate > minimum ? estimate : minimum;
    }
    state
      ..['ascensionAura'] = ascensionAura.toString()
      ..['multiplier'] =
          AscensionCurve.multiplierForAura(ascensionAura).toString();

    final legacyEquipped = state.remove('equipped');
    if (state['equippedAppearances'] == null) {
      state['equippedAppearances'] =
          legacyEquipped is String ? <String>[legacyEquipped] : <String>[];
    }
    return _codec.normalizeGameState(state);
  }
}
