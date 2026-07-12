import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _quanta = 10000000;
const _ascensionThreshold = 1000000000000000;
const _ascensionScale = 100000000000;
const balanceVersion = 'balance-v0.2';
const achievementIds = <String>[
  'ACH-V-01',
  'ACH-V-02',
  'ACH-V-03',
  'ACH-V-04',
  'ACH-V-05',
  'ACH-V-06',
  'ACH-S-01',
  'ACH-S-02',
  'ACH-S-03',
  'ACH-S-04',
  'ACH-S-05',
  'ACH-S-06',
  'ACH-S-07',
];

enum CyclePhase { six, seven }

class AuraComplementQuote {
  const AuraComplementQuote(
      {required this.upgradeId,
      required this.level,
      required this.price,
      required this.spend,
      required this.missing});
  final String upgradeId;
  final int level;
  final BigInt price;
  final BigInt spend;
  final BigInt missing;
}

enum UpgradeRequirementKind { totalAura, upgradeLevel }

class UpgradeRequirement {
  const UpgradeRequirement.totalAura(this.total)
      : kind = UpgradeRequirementKind.totalAura,
        upgradeId = null,
        level = 0;

  const UpgradeRequirement.upgradeLevel(this.upgradeId, this.level)
      : kind = UpgradeRequirementKind.upgradeLevel,
        total = null;

  final UpgradeRequirementKind kind;
  final BigInt? total;
  final String? upgradeId;
  final int level;
}

class UpgradePurchaseQuote {
  const UpgradePurchaseQuote({
    required this.quantity,
    required this.cost,
    required this.affordable,
  });

  final int quantity;
  final BigInt cost;
  final bool affordable;
}

class Upgrade {
  const Upgrade({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.baseCost,
    required this.base20,
    required this.isTechnique,
    this.requiredTotal,
    this.prerequisite,
    this.prerequisiteLevel = 0,
    this.branch = '',
  });

  final String id;
  final String nameKey;
  final String descriptionKey;
  final BigInt baseCost;
  final BigInt base20;
  final bool isTechnique;
  final BigInt? requiredTotal;
  final String? prerequisite;
  final int prerequisiteLevel;
  final String branch;
}

final upgrades = <Upgrade>[
  Upgrade(
      id: 'TECH-01',
      nameKey: 'content.tech_01.name',
      descriptionKey: 'content.tech_01.description',
      baseCost: BigInt.from(45),
      base20: BigInt.from(20),
      isTechnique: true),
  Upgrade(
      id: 'TECH-02',
      nameKey: 'content.tech_02.name',
      descriptionKey: 'content.tech_02.description',
      baseCost: BigInt.from(67),
      base20: BigInt.from(100),
      isTechnique: true,
      requiredTotal: BigInt.from(1000)),
  Upgrade(
      id: 'TECH-03',
      nameKey: 'content.tech_03.name',
      descriptionKey: 'content.tech_03.description',
      baseCost: BigInt.from(67000),
      base20: BigInt.from(100000),
      isTechnique: true,
      requiredTotal: BigInt.from(1000000)),
  Upgrade(
      id: 'TECH-04',
      nameKey: 'content.tech_04.name',
      descriptionKey: 'content.tech_04.description',
      baseCost: BigInt.from(67000000),
      base20: BigInt.from(100000000),
      isTechnique: true,
      requiredTotal: BigInt.from(1000000000)),
  Upgrade(
      id: 'TECH-05',
      nameKey: 'content.tech_05.name',
      descriptionKey: 'content.tech_05.description',
      baseCost: BigInt.from(67000000000),
      base20: BigInt.from(100000000000),
      isTechnique: true,
      requiredTotal: BigInt.from(1000000000000)),
  Upgrade(
      id: 'TECH-06',
      nameKey: 'content.tech_06.name',
      descriptionKey: 'content.tech_06.description',
      baseCost: BigInt.from(67000000000000),
      base20: BigInt.from(100000000000000),
      isTechnique: true,
      requiredTotal: BigInt.from(_ascensionThreshold)),
  ..._branch('A', 'item_a', 270, 15),
  ..._branch('B', 'item_b', 270, 15),
  ..._branch('C', 'item_c', 270, 15),
  Upgrade(
      id: 'ITEM-CONV-01',
      nameKey: 'content.item_conv_01.name',
      descriptionKey: 'content.item_conv_01.description',
      baseCost: BigInt.from(6700),
      base20: BigInt.from(150),
      isTechnique: false,
      requiredTotal: BigInt.from(1000),
      prerequisite: 'ROOTS-10',
      prerequisiteLevel: 10,
      branch: 'Spectrum'),
  Upgrade(
      id: 'ITEM-CONV-02',
      nameKey: 'content.item_conv_02.name',
      descriptionKey: 'content.item_conv_02.description',
      baseCost: BigInt.from(26800000),
      base20: BigInt.from(67000),
      isTechnique: false,
      requiredTotal: BigInt.from(1000000000),
      prerequisite: 'DEPTH-03',
      prerequisiteLevel: 25,
      branch: 'Spectrum'),
  Upgrade(
      id: 'ITEM-CONV-03',
      nameKey: 'content.item_conv_03.name',
      descriptionKey: 'content.item_conv_03.description',
      baseCost: BigInt.from(670000000000000),
      base20: BigInt.from(268000000000),
      isTechnique: false,
      requiredTotal: BigInt.from(_ascensionThreshold),
      prerequisite: 'DEPTH-05',
      prerequisiteLevel: 50,
      branch: 'Spectrum'),
];

List<Upgrade> _branch(String branch, String key, int rootCost, int root20) {
  const costs = [270, 2350, 67000, 67000, 67000000000];
  const effects = [15, 134, 1340, 134000, 1340000000];
  const totals = [0, 1000, 1000000, 1000000000, 1000000000000];
  const gates = [0, 10, 25, 50, 100];
  return List.generate(
      5,
      (i) => Upgrade(
            id: 'ITEM-$branch-0${i + 1}',
            nameKey: 'content.${key}_0${i + 1}.name',
            descriptionKey: 'content.${key}_0${i + 1}.description',
            baseCost: BigInt.from(i == 0 ? rootCost : costs[i]),
            base20: BigInt.from(i == 0 ? root20 : effects[i]),
            isTechnique: false,
            requiredTotal: BigInt.from(totals[i]),
            prerequisite: i == 0 ? 'TECH-01' : 'ITEM-$branch-0$i',
            prerequisiteLevel: i == 0 ? 1 : gates[i],
            branch: branch,
          ));
}

class GameController extends ChangeNotifier {
  GameController._(this._prefs, this._data);
  final SharedPreferences _prefs;
  final Map<String, dynamic> _data;
  Timer? _ticker;
  int _lastTick = 0;
  final Stopwatch _foregroundClock = Stopwatch()..start();
  bool _disposed = false;
  bool _returnAudioCuePending = false;
  Future<void> _writeQueue = Future.value();

  static Future<GameController> load() => _load(startTicker: true);

  @visibleForTesting
  static Future<GameController> loadForTesting() => _load(startTicker: false);

  static Future<GameController> _load({required bool startTicker}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('save-v1');
    Map<String, dynamic> data = <String, dynamic>{};
    if (raw != null) {
      try {
        data = (jsonDecode(raw) as Map).cast<String, dynamic>();
      } catch (_) {
        await prefs.remove('save-v1');
      }
    }
    final controller = GameController._(prefs, data);
    controller._migrateBalanceState();
    controller._migrateAppearanceState();
    controller._lastTick = controller._foregroundClock.elapsedMilliseconds;
    // Process a persisted background interval before the first frame. The
    // operation is idempotent, so a later platform `resumed` callback cannot
    // credit the same interval twice.
    controller.resume();
    if (startTicker) {
      controller._ticker = Timer.periodic(
          const Duration(milliseconds: 500), (_) => controller.integrate());
    }
    return controller;
  }

  BigInt get available => _big('available');
  BigInt get total => _big('total');
  BigInt get journey => _big('journey');
  BigInt get remainder => _big('remainder');
  BigInt get multiplier => _big('multiplier', '100');
  BigInt get ascensionAura => _big('ascensionAura');

  void _migrateBalanceState() {
    if (_int('ascensions') < 0) {
      _data['ascensions'] = 0;
    }
    final ascensions = _int('ascensions');
    final storedAscensionAura =
        BigInt.tryParse('${_data['ascensionAura'] ?? ''}');
    var migratedAscensionAura =
        storedAscensionAura != null && storedAscensionAura >= BigInt.zero
            ? storedAscensionAura
            : _data['balanceVersion'] == balanceVersion
                ? _ascensionAuraForMultiplier(multiplier)
                : _legacyAscensionAura();
    final minimum = BigInt.from(ascensions) * BigInt.from(_ascensionThreshold);
    if (migratedAscensionAura < minimum) {
      migratedAscensionAura = minimum;
    }
    _setBig('ascensionAura', migratedAscensionAura);
    _setBig('multiplier', _multiplierForAscensionAura(migratedAscensionAura));
    _data['balanceVersion'] = balanceVersion;
  }

  void _migrateAppearanceState() {
    final storedAppearances = _data['appearances'];
    final owned = _orderedAppearanceIds(
      storedAppearances is List
          ? storedAppearances.whereType<String>()
          : const <String>[],
    );
    final storedEquipped = _data['equippedAppearances'];
    final legacyEquipped = _data['equipped'];
    final requested = storedEquipped is List
        ? storedEquipped.whereType<String>()
        : legacyEquipped is String
            ? <String>[legacyEquipped]
            : const <String>[];
    final ownedSet = owned.toSet();

    _data['appearances'] = owned;
    _data['equippedAppearances'] =
        _orderedAppearanceIds(requested.where(ownedSet.contains));
    _data.remove('equipped');
  }

  List<String> _orderedAppearanceIds(Iterable<String> ids) {
    final requested = ids.toSet();
    return upgrades
        .where(
            (upgrade) => !upgrade.isTechnique && requested.contains(upgrade.id))
        .map((upgrade) => upgrade.id)
        .toList(growable: false);
  }

  bool _isKnownAppearanceId(String id) =>
      upgrades.any((upgrade) => !upgrade.isTechnique && upgrade.id == id);

  BigInt _legacyAscensionAura() {
    final bonus = multiplier > BigInt.from(100)
        ? multiplier - BigInt.from(100)
        : BigInt.zero;
    final ascensions = _int('ascensions');
    final estimate = ascensions > 0
        ? bonus *
            bonus *
            BigInt.from(_ascensionScale) ~/
            BigInt.from(ascensions)
        : bonus * bonus * BigInt.from(_ascensionScale);
    final minimum = BigInt.from(ascensions) * BigInt.from(_ascensionThreshold);
    return estimate > minimum ? estimate : minimum;
  }

  BigInt _ascensionAuraForMultiplier(BigInt value) {
    final bonus =
        value > BigInt.from(100) ? value - BigInt.from(100) : BigInt.zero;
    return bonus * bonus * BigInt.from(_ascensionScale);
  }

  BigInt _multiplierForAscensionAura(BigInt aura) {
    if (aura <= BigInt.zero) {
      return BigInt.from(100);
    }
    return BigInt.from(100) +
        _integerSqrt(aura ~/ BigInt.from(_ascensionScale));
  }

  int get cycles => _int('cycles');
  CyclePhase get phase =>
      _data['phase'] == 'seven' ? CyclePhase.seven : CyclePhase.six;
  String get locale =>
      _data['locale'] as String? ??
      PlatformDispatcher.instance.locale.toLanguageTag();
  bool get analyticsDecided => _data['analyticsDecided'] == true;
  bool get analyticsEnabled => _data['analyticsEnabled'] == true;
  bool get reduceMotion => _data['reduceMotion'] == true;
  bool get highContrast => _data['highContrast'] == true;
  Set<String> get achievements => Set<String>.from(
      (_data['achievements'] as List? ?? const []).whereType<String>());
  Map<String, int> get levels => Map<String, int>.fromEntries((_data['levels']
              as Map? ??
          const {})
      .entries
      .where((entry) => entry.value is num)
      .map((entry) => MapEntry('${entry.key}', (entry.value as num).toInt())));
  List<String> get appearances => List<String>.from(
      (_data['appearances'] as List? ?? const []).whereType<String>());
  Set<String> get equippedAppearances => Set<String>.unmodifiable(
        (_data['equippedAppearances'] as List? ?? const []).whereType<String>(),
      );
  Set<String> get transformations => Set<String>.from(
      (_data['transformations'] as List? ?? const []).cast<String>());
  Set<String> get seals =>
      Set<String>.from((_data['seals'] as List? ?? const []).cast<String>());
  bool get returnBonusAvailable =>
      (_data['returnReward'] as Map?)?['bonusStatus'] == 'available';
  bool consumeReturnAudioCue() {
    final pending = _returnAudioCuePending;
    _returnAudioCuePending = false;
    return pending;
  }

  BigInt get returnBase =>
      BigInt.tryParse(
          '${(_data['returnReward'] as Map?)?['baseQuanta'] ?? '0'}') ??
      BigInt.zero;
  BigInt get returnBonus =>
      BigInt.tryParse(
          '${(_data['returnReward'] as Map?)?['bonusQuanta'] ?? '0'}') ??
      BigInt.zero;

  BigInt _big(String key, [String fallback = '0']) =>
      BigInt.tryParse('${_data[key] ?? fallback}') ?? BigInt.zero;
  int _int(String key, [int fallback = 0]) {
    final value = _data[key];
    return value is num ? value.toInt() : fallback;
  }

  int level(String id) => levels[id] ?? 0;
  void _setBig(String key, BigInt value) => _data[key] = value.toString();

  int milestoneFactor(int level) =>
      1 <<
      ((level >= 10 ? 1 : 0) +
          (level >= 25 ? 1 : 0) +
          (level >= 50 ? 1 : 0) +
          (level ~/ 100));
  BigInt get power20 =>
      BigInt.from(20) +
      upgrades.where((u) => u.isTechnique).fold(
          BigInt.zero,
          (sum, u) =>
              sum +
              u.base20 *
                  BigInt.from(level(u.id) * milestoneFactor(level(u.id))));
  BigInt get passive20 => upgrades.where((u) => !u.isTechnique).fold(
      BigInt.zero,
      (sum, u) =>
          sum +
          u.base20 * BigInt.from(level(u.id) * milestoneFactor(level(u.id))));
  BigInt get powerNumerator => power20 * multiplier;
  BigInt get passiveNumerator => passive20 * multiplier;
  BigInt price(Upgrade upgrade, [int? atLevel]) {
    final n = atLevel ?? level(upgrade.id);
    final top = upgrade.baseCost * BigInt.from(23).pow(n);
    final bottom = BigInt.from(20).pow(n);
    return (top + bottom - BigInt.one) ~/ bottom;
  }

  List<UpgradeRequirement> requirementsFor(Upgrade upgrade) {
    final requirements = <UpgradeRequirement>[];
    final requiredTotal = upgrade.requiredTotal;
    if (requiredTotal != null && requiredTotal > BigInt.zero) {
      requirements.add(UpgradeRequirement.totalAura(requiredTotal));
    }
    final prerequisite = upgrade.prerequisite;
    if (prerequisite == 'ROOTS-10') {
      requirements.addAll([
        for (final branch in const ['A', 'B', 'C'])
          UpgradeRequirement.upgradeLevel('ITEM-$branch-01', 10),
      ]);
    } else if (prerequisite == 'DEPTH-03') {
      requirements.addAll([
        for (final branch in const ['A', 'B', 'C'])
          UpgradeRequirement.upgradeLevel('ITEM-$branch-03', 25),
      ]);
    } else if (prerequisite == 'DEPTH-05') {
      requirements.addAll([
        for (final branch in const ['A', 'B', 'C'])
          UpgradeRequirement.upgradeLevel('ITEM-$branch-05', 50),
      ]);
    } else if (prerequisite != null) {
      requirements.add(UpgradeRequirement.upgradeLevel(
        prerequisite,
        upgrade.prerequisiteLevel,
      ));
    }
    return List.unmodifiable(requirements);
  }

  bool requirementMet(UpgradeRequirement requirement) =>
      switch (requirement.kind) {
        UpgradeRequirementKind.totalAura => total >= requirement.total!,
        UpgradeRequirementKind.upgradeLevel =>
          level(requirement.upgradeId!) >= requirement.level,
      };

  UpgradePurchaseQuote purchaseQuote(Upgrade upgrade, int quantity) {
    if (quantity == 0) {
      return UpgradePurchaseQuote(
        quantity: 0,
        cost: BigInt.zero,
        affordable: false,
      );
    }
    final startLevel = level(upgrade.id);
    if (quantity > 0) {
      var cost = BigInt.zero;
      for (var offset = 0; offset < quantity; offset++) {
        cost += price(upgrade, startLevel + offset);
      }
      return UpgradePurchaseQuote(
        quantity: quantity,
        cost: cost,
        affordable: available >= cost,
      );
    }

    var cost = BigInt.zero;
    var count = 0;
    while (true) {
      final next = price(upgrade, startLevel + count);
      if (cost + next > available) break;
      cost += next;
      count++;
    }
    return UpgradePurchaseQuote(
      quantity: count,
      cost: cost,
      affordable: count > 0,
    );
  }

  bool isUnlocked(Upgrade upgrade) =>
      requirementsFor(upgrade).every(requirementMet);

  String missingRequirement(Upgrade u) {
    if (total < (u.requiredTotal ?? BigInt.zero)) {
      return 'Reach ${u.requiredTotal} Total Aura';
    }
    if (u.prerequisite == 'ROOTS-10') return 'Get all three roots to level 10';
    if (u.prerequisite == 'DEPTH-03') {
      return 'Get all three depth-03 items to level 25';
    }
    if (u.prerequisite == 'DEPTH-05') {
      return 'Get all three depth-05 items to level 50';
    }
    if (u.prerequisite != null) {
      return '${u.prerequisite} level ${u.prerequisiteLevel}';
    }
    return '';
  }

  void integrate() {
    final now = _foregroundClock.elapsedMilliseconds;
    final delta = now - _lastTick;
    if (delta <= 0) return;
    _lastTick = now;
    _credit(passive20 * multiplier * BigInt.from(delta) * BigInt.from(5));
    _persist(notify: true);
  }

  /// Freezes the exact passive-rate numerator before backgrounding. Offline time
  /// is never treated as open-app time and is capped at eight hours.
  void pause() {
    if (!_foregroundClock.isRunning) return;
    integrate();
    _foregroundClock.stop();
    if (returnBonusAvailable) {
      _persist();
      return;
    }
    _data['offlineAt'] = DateTime.now().millisecondsSinceEpoch;
    _data['offlineRate'] = (passive20 * multiplier).toString();
    _persist();
  }

  void resume() {
    final leftAt = (_data['offlineAt'] as num?)?.toInt();
    if (leftAt == null && _foregroundClock.isRunning) return;
    if (returnBonusAvailable && leftAt == null) {
      _foregroundClock
        ..reset()
        ..start();
      _lastTick = _foregroundClock.elapsedMilliseconds;
      return;
    }
    final nowWall = DateTime.now().millisecondsSinceEpoch;
    final rate =
        BigInt.tryParse('${_data['offlineRate'] ?? '0'}') ?? BigInt.zero;
    _foregroundClock
      ..reset()
      ..start();
    _lastTick = _foregroundClock.elapsedMilliseconds;
    if (leftAt == null) return;
    final elapsed = nowWall - leftAt;
    _data.remove('offlineAt');
    _data.remove('offlineRate');
    if (elapsed > 0) {
      final valid = elapsed > 28800000 ? 28800000 : elapsed;
      final base = rate * BigInt.from(valid) * BigInt.from(5);
      final bonusEligible = elapsed > 28800000;
      _credit(base);
      if (base > BigInt.zero) _returnAudioCuePending = true;
      _data['returnReward'] = <String, dynamic>{
        'id': '${leftAt}_$valid',
        'baseQuanta': base.toString(),
        'bonusQuanta':
            (bonusEligible ? base ~/ BigInt.from(5) : BigInt.zero).toString(),
        'baseStatus': 'credited',
        'bonusStatus': bonusEligible ? 'available' : 'unavailable',
      };
      if (elapsed >= 22020000) _unlock('ACH-S-02');
    }
    _persist(notify: true);
  }

  /// Called only after the rewarded-ad adapter reports a valid completion.
  bool resolveReturnBonus({required bool rewarded}) {
    final reward = (_data['returnReward'] as Map?)?.cast<String, dynamic>();
    if (reward == null || reward['bonusStatus'] != 'available') return false;
    if (!rewarded) return false;
    _credit(BigInt.parse('${reward['bonusQuanta']}'));
    reward['bonusStatus'] = 'credited';
    _data['returnReward'] = reward;
    _persist(notify: true);
    return true;
  }

  bool declineReturnBonus() {
    final reward = (_data['returnReward'] as Map?)?.cast<String, dynamic>();
    if (reward == null || reward['bonusStatus'] != 'available') return false;
    reward['bonusStatus'] = 'declined';
    _data['returnReward'] = reward;
    _persist(notify: true);
    return true;
  }

  /// [quality] (0..1) scales the Six-Seven reward by how completely the player
  /// let the gesture animation finish before completing it. 1.0 is a perfectly
  /// timed cycle (full aura); mashing before the swing lands earns proportionally
  /// less, down to a 10% floor.
  void tap([double quality = 1.0]) {
    integrate();
    if (phase == CyclePhase.six) {
      _data['phase'] = 'seven';
      _data['sixStartedAt'] = _foregroundClock.elapsedMilliseconds;
    } else {
      final sixAt = (_data['sixStartedAt'] as num?)?.toInt();
      _data['phase'] = 'six';
      _data.remove('sixStartedAt');
      _data['cycles'] = cycles + 1;
      final factor = (5000 * quality.clamp(0.1, 1.0)).round();
      _credit(power20 * multiplier * BigInt.from(factor));
      _unlock('ACH-V-01');
      if (cycles >= 67) _unlock('ACH-V-02');
      if (sixAt != null &&
          _foregroundClock.elapsedMilliseconds - sixAt >= 67000) {
        _unlock('ACH-S-01');
      }
    }
    _persist(notify: true);
  }

  void _credit(BigInt quanta) {
    final before = total;
    final sum = remainder + quanta;
    final credit = sum ~/ BigInt.from(_quanta);
    _setBig('remainder', sum % BigInt.from(_quanta));
    if (credit == BigInt.zero) return;
    _setBig('available', available + credit);
    _setBig('total', total + credit);
    _setBig('journey', journey + credit);
    _recordProgression(before, total);
  }

  void _recordProgression(BigInt before, BigInt after) {
    const forms = <String, int>{
      'FORM-01': 1000,
      'FORM-02': 1000000,
      'FORM-03': 1000000000,
      'FORM-04': 1000000000000,
      'FORM-05': _ascensionThreshold
    };
    final nextForms = transformations;
    for (final entry in forms.entries) {
      if (after >= BigInt.from(entry.value)) nextForms.add(entry.key);
    }
    if (nextForms.isNotEmpty) {
      _data['transformations'] = nextForms.toList();
      if (nextForms.contains('FORM-01')) _unlock('ACH-V-05');
    }
    var threshold = BigInt.from(67);
    var magnitude = 0;
    var crossed = 0;
    final nextSeals = seals;
    while (threshold <= after) {
      if (before < threshold) {
        nextSeals.add('67e${magnitude * 3}');
        crossed++;
      }
      threshold *= BigInt.from(1000);
      magnitude++;
    }
    if (nextSeals.isNotEmpty) _data['seals'] = nextSeals.toList();
    if (crossed > 1) _unlock('ACH-S-04');
  }

  bool buy(Upgrade u, int quantity) {
    integrate();
    if (!isUnlocked(u)) return false;
    final quote = purchaseQuote(u, quantity);
    if (!quote.affordable || quote.quantity == 0) return false;
    _setBig('available', available - quote.cost);
    final next = levels..[u.id] = level(u.id) + quote.quantity;
    _data['levels'] = next;
    if (!u.isTechnique) {
      _collectAppearance(u.id);
      _unlock('ACH-V-03');
    }
    if (['ITEM-A-01', 'ITEM-B-01', 'ITEM-C-01'].every((id) => level(id) > 0)) {
      _unlock('ACH-V-04');
    }
    if (u.id.startsWith('ITEM-CONV')) _unlock('ACH-S-05');
    if (['ITEM-CONV-01', 'ITEM-CONV-02', 'ITEM-CONV-03']
        .every((id) => level(id) > 0)) {
      _unlock('ACH-S-06');
    }
    if (available == BigInt.from(67)) _unlock('ACH-S-03');
    _persist(notify: true);
    return true;
  }

  void setLocale(String value) {
    _data['locale'] = value;
    _persist(notify: true);
  }

  void setBool(String key, bool value) {
    _data[key] = value;
    _persist(notify: true);
  }

  void chooseAnalytics(bool value) {
    _data['analyticsDecided'] = true;
    _data['analyticsEnabled'] = value;
    _persist(notify: true);
  }

  bool setAppearanceEquipped(String item, {required bool equipped}) {
    if (!appearances.contains(item)) return false;
    final next = equippedAppearances.toSet();
    final changed = equipped ? next.add(item) : next.remove(item);
    if (!changed) return false;
    _data['equippedAppearances'] = _orderedAppearanceIds(next);
    _persist(notify: true);
    return true;
  }

  void _collectAppearance(String item) {
    final owned = appearances.toSet();
    final firstAcquisition = owned.add(item);
    _data['appearances'] = _orderedAppearanceIds(owned);
    if (!firstAcquisition) return;
    _data['equippedAppearances'] =
        _orderedAppearanceIds({...equippedAppearances, item});
  }

  AuraComplementQuote? complementQuote(Upgrade upgrade, {int nowMillis = 0}) {
    if (!isUnlocked(upgrade)) return null;
    final current = available;
    final nextPrice = price(upgrade);
    if (!(BigInt.from(7) * nextPrice <= BigInt.from(10) * current &&
        BigInt.from(10) * current < BigInt.from(10) * nextPrice)) {
      return null;
    }
    final now =
        nowMillis == 0 ? DateTime.now().millisecondsSinceEpoch : nowMillis;
    final recent = _complementUses()
        .where((at) => now - at >= 0 && now - at < 86400000)
        .toList();
    if (recent.length >= 3) return null;
    return AuraComplementQuote(
        upgradeId: upgrade.id,
        level: level(upgrade.id),
        price: nextPrice,
        spend: current,
        missing: nextPrice - current);
  }

  AuraComplementQuote? beginComplement(Upgrade upgrade, {int nowMillis = 0}) {
    final quote = complementQuote(upgrade, nowMillis: nowMillis);
    if (quote == null) return null;
    _data['complementQuote'] = <String, dynamic>{
      'upgradeId': quote.upgradeId,
      'level': quote.level,
      'price': quote.price.toString(),
      'spend': quote.spend.toString(),
      'missing': quote.missing.toString(),
    };
    _persist(notify: true);
    return quote;
  }

  bool redeemComplement(AuraComplementQuote quote,
      {required bool rewarded, int nowMillis = 0}) {
    if (!rewarded) return false;
    final upgrade = upgrades.where((u) => u.id == quote.upgradeId).firstOrNull;
    if (upgrade == null ||
        level(upgrade.id) != quote.level ||
        available < quote.spend) {
      return false;
    }
    final stored = (_data['complementQuote'] as Map?)?.cast<String, dynamic>();
    if (stored == null ||
        stored['upgradeId'] != quote.upgradeId ||
        stored['level'] != quote.level ||
        '${stored['price']}' != quote.price.toString() ||
        '${stored['spend']}' != quote.spend.toString()) {
      return false;
    }
    _setBig('available', available - quote.spend);
    final next = levels..[upgrade.id] = quote.level + 1;
    _data['levels'] = next;
    if (!upgrade.isTechnique) {
      _collectAppearance(upgrade.id);
      _unlock('ACH-V-03');
    }
    if (['ITEM-A-01', 'ITEM-B-01', 'ITEM-C-01'].every((id) => level(id) > 0)) {
      _unlock('ACH-V-04');
    }
    if (upgrade.id.startsWith('ITEM-CONV')) _unlock('ACH-S-05');
    if (['ITEM-CONV-01', 'ITEM-CONV-02', 'ITEM-CONV-03']
        .every((id) => level(id) > 0)) {
      _unlock('ACH-S-06');
    }
    final now =
        nowMillis == 0 ? DateTime.now().millisecondsSinceEpoch : nowMillis;
    _data['complementUses'] =
        [..._complementUses(), now].where((at) => now - at < 86400000).toList();
    _data.remove('complementQuote');
    _persist(notify: true);
    return true;
  }

  List<int> _complementUses() =>
      List<int>.from((_data['complementUses'] as List? ?? const [])
          .map((value) => (value as num).toInt()));

  /// The save body is intentionally portable: every economic integer is decimal text.
  String exportState() {
    final portable = Map<String, dynamic>.from(_data)
      ..remove('analyticsEnabled')
      ..remove('analyticsDecided');
    return jsonEncode({
      ...portable,
      'saveVersion': 1,
      'arithVersion': 'arith-v1',
      'balanceVersion': balanceVersion,
      'ascensionAura': ascensionAura.toString(),
      'exportedAt': DateTime.now().toUtc().toIso8601String()
    });
  }

  Future<bool> restoreState(String body) async {
    final previous = Map<String, dynamic>.from(_data);
    try {
      final candidate = (jsonDecode(body) as Map).cast<String, dynamic>();
      final importedBalance = candidate['balanceVersion'];
      if (candidate['saveVersion'] != 1 ||
          candidate['arithVersion'] != 'arith-v1' ||
          (importedBalance != null &&
              importedBalance != 'balance-v0.1' &&
              importedBalance != balanceVersion)) {
        return false;
      }
      for (final key in ['available', 'total', 'journey', 'remainder']) {
        if (BigInt.tryParse('${candidate[key] ?? '0'}') == null) return false;
      }
      final candidateAvailable =
          BigInt.tryParse('${candidate['available'] ?? '0'}')!;
      final candidateJourney =
          BigInt.tryParse('${candidate['journey'] ?? '0'}')!;
      final candidateTotal = BigInt.tryParse('${candidate['total'] ?? '0'}')!;
      final candidateRemainder =
          BigInt.tryParse('${candidate['remainder'] ?? '0'}')!;
      final candidateAscensionAura = candidate['ascensionAura'] == null
          ? null
          : BigInt.tryParse('${candidate['ascensionAura']}');
      final candidateMultiplier =
          BigInt.tryParse('${candidate['multiplier'] ?? '100'}');
      final candidateAscensions = candidate['ascensions'] ?? 0;
      if (candidateAvailable < BigInt.zero ||
          candidateJourney < candidateAvailable ||
          candidateTotal < candidateJourney ||
          candidateRemainder < BigInt.zero ||
          candidateRemainder >= BigInt.from(_quanta) ||
          candidateMultiplier == null ||
          candidateMultiplier < BigInt.from(100) ||
          candidateAscensions is! int ||
          candidateAscensions < 0 ||
          (candidate['ascensionAura'] != null &&
              (candidateAscensionAura == null ||
                  candidateAscensionAura < BigInt.zero))) {
        return false;
      }
      if (importedBalance == balanceVersion) {
        if (candidateAscensionAura == null ||
            candidateAscensionAura + candidateJourney > candidateTotal ||
            candidateAscensionAura <
                BigInt.from(candidateAscensions) *
                    BigInt.from(_ascensionThreshold) ||
            _multiplierForAscensionAura(candidateAscensionAura) !=
                candidateMultiplier) {
          return false;
        }
      }
      if (candidate['levels'] != null && candidate['levels'] is! Map) {
        return false;
      }
      if (candidate['achievements'] != null &&
          candidate['achievements'] is! List) {
        return false;
      }
      final candidateAppearances = candidate['appearances'];
      if (candidateAppearances != null &&
          (candidateAppearances is! List ||
              candidateAppearances.any(
                (id) => id is! String || !_isKnownAppearanceId(id),
              ))) {
        return false;
      }
      final ownedAppearanceIds = candidateAppearances is List
          ? candidateAppearances.whereType<String>().toSet()
          : const <String>{};
      final candidateEquipped = candidate['equippedAppearances'];
      if (candidateEquipped != null &&
          (candidateEquipped is! List ||
              candidateEquipped.any(
                (id) =>
                    id is! String ||
                    !_isKnownAppearanceId(id) ||
                    !ownedAppearanceIds.contains(id),
              ))) {
        return false;
      }
      final legacyEquipped = candidate['equipped'];
      if (legacyEquipped != null &&
          (legacyEquipped is! String ||
              !_isKnownAppearanceId(legacyEquipped) ||
              !ownedAppearanceIds.contains(legacyEquipped))) {
        return false;
      }
      final analyticsDevicePreference = <String, dynamic>{
        if (_data.containsKey('analyticsEnabled'))
          'analyticsEnabled': _data['analyticsEnabled'],
        if (_data.containsKey('analyticsDecided'))
          'analyticsDecided': _data['analyticsDecided'],
      };
      _data
        ..clear()
        ..addAll(candidate)
        ..remove('exportedAt')
        ..addAll(analyticsDevicePreference);
      _migrateBalanceState();
      _migrateAppearanceState();
      _foregroundClock
        ..reset()
        ..start();
      _lastTick = _foregroundClock.elapsedMilliseconds;
      await _persist(notify: true);
      return true;
    } catch (_) {
      _data
        ..clear()
        ..addAll(previous);
      return false;
    }
  }

  bool get canAscend =>
      !returnBonusAvailable && journey >= BigInt.from(_ascensionThreshold);
  BigInt ascensionGain() {
    final projectedMultiplier =
        _multiplierForAscensionAura(ascensionAura + journey);
    return projectedMultiplier > multiplier
        ? projectedMultiplier - multiplier
        : BigInt.zero;
  }

  void ascend() {
    integrate();
    if (!canAscend) return;
    final nextAscensionAura = ascensionAura + journey;
    _setBig('multiplier', _multiplierForAscensionAura(nextAscensionAura));
    _setBig('ascensionAura', nextAscensionAura);
    _data['ascensions'] = _int('ascensions') + 1;
    _setBig('available', BigInt.zero);
    _setBig('journey', BigInt.zero);
    _data['levels'] = <String, int>{};
    _unlock('ACH-V-06');
    if (_int('ascensions') >= 2) _unlock('ACH-S-07');
    _persist(notify: true);
  }

  BigInt _integerSqrt(BigInt n) {
    if (n <= BigInt.one) return n;
    var x = BigInt.one << ((n.bitLength + 1) >> 1);
    while (true) {
      final y = (x + n ~/ x) >> 1;
      if (y >= x) return x;
      x = y;
    }
  }

  void _unlock(String id) {
    final next = achievements..add(id);
    _data['achievements'] = next.toList();
  }

  Future<void> _persist({bool notify = false}) async {
    final serialized = jsonEncode(_data);
    _writeQueue =
        _writeQueue.then((_) => _prefs.setString('save-v1', serialized));
    await _writeQueue;
    if (notify && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _disposed = true;
    super.dispose();
  }
}
