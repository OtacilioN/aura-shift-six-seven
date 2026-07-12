import 'dart:convert';

import 'package:flutter/services.dart';

/// Stable IDs from the promoted `audio-manifest-v1.json`.
abstract final class AudioIds {
  static const gameBase = 'MUS-GAME-BASE';
  static const gameGroove = 'MUS-GAME-GROOVE';
  static const gameHype = 'MUS-GAME-HYPE';
  static const menu = 'MUS-MENU';
  static const shop = 'MUS-SHOP';
  static const gameMixes = <String>[
    'MUS-GAME-I0-MIX',
    'MUS-GAME-I1-MIX',
    'MUS-GAME-I2-MIX',
    'MUS-GAME-I3-MIX',
  ];
  static const six = <String>[
    'SFX-SIX-01',
    'SFX-SIX-02',
    'SFX-SIX-03',
    'SFX-SIX-04',
    'SFX-SIX-05',
    'SFX-SIX-06',
  ];
  static const seven = <String>[
    'SFX-SEVEN-01',
    'SFX-SEVEN-02',
    'SFX-SEVEN-03',
    'SFX-SEVEN-04',
    'SFX-SEVEN-05',
    'SFX-SEVEN-06',
  ];

  static const uiTab = 'SFX-UI-TAB';
  static const uiOpen = 'SFX-UI-OPEN';
  static const uiClose = 'SFX-UI-CLOSE';
  static const uiToggleOn = 'SFX-UI-TOGGLE-ON';
  static const uiToggleOff = 'SFX-UI-TOGGLE-OFF';
  static const uiError = 'SFX-UI-ERROR';
  static const shopPurchase = 'SFX-SHOP-PURCHASE';
  static const shopBatch = 'SFX-SHOP-BATCH';
  static const shopUnavailable = 'SFX-SHOP-UNAVAILABLE';
  static const shopUnlock = 'SFX-SHOP-UNLOCK';
  static const shopMilestone = 'SFX-SHOP-MILESTONE';
  static const collectionEquip = 'SFX-COLLECTION-EQUIP';
  static const collectionHide = 'SFX-COLLECTION-HIDE';
  static const achievement = 'STG-ACHIEVEMENT';
  static const ascension = 'STG-ASCENSION';
  static const mark67 = 'STG-MARK-67';
  static const returnOffline = 'SFX-RETURN-OFFLINE';
  static const returnBonus = 'SFX-RETURN-BONUS';

  static String form(int number) =>
      'STG-FORM-${number.toString().padLeft(2, '0')}';
}

class AudioAssetRecord {
  const AudioAssetRecord({
    required this.id,
    required this.runtimePath,
    required this.group,
    required this.kind,
    required this.duration,
    required this.loop,
  });

  factory AudioAssetRecord.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Audio asset has invalid $key.');
      }
      return value;
    }

    if (json['status'] != 'approved') {
      throw FormatException('Audio asset ${json['id']} is not approved.');
    }
    final id = requiredString('id');
    final runtimePath = requiredString('runtimePath');
    final group = requiredString('group');
    final kind = requiredString('kind');
    if (!const {'music', 'cycle', 'ui', 'event'}.contains(group)) {
      throw FormatException('Audio asset $id has invalid group $group.');
    }
    if (!runtimePath.startsWith('assets/audio/') ||
        runtimePath.contains('\\') ||
        Uri.parse(runtimePath).pathSegments.contains('..')) {
      throw FormatException('Audio asset $id escapes assets/audio/.');
    }
    if ((group == 'music' && !runtimePath.endsWith('.ogg')) ||
        (group != 'music' && !runtimePath.endsWith('.wav'))) {
      throw FormatException('Audio asset $id has an invalid runtime format.');
    }
    final metrics = (json['reviewedMetrics'] as Map?)?.cast<String, dynamic>();
    final runtime = (metrics?['runtime'] as Map?)?.cast<String, dynamic>();
    final seconds = (runtime?['durationSeconds'] as num?)?.toDouble() ??
        ((runtime?['frames'] as num?)?.toDouble() ?? 0) /
            ((runtime?['sampleRate'] as num?)?.toDouble() ?? 48000);
    final duration = Duration(microseconds: (seconds * 1000000).round());
    final loop = json['loop'] == true;
    if (duration <= Duration.zero) {
      throw FormatException('Audio asset $id has no positive duration.');
    }
    if (loop != (group == 'music')) {
      throw FormatException('Audio asset $id has an invalid loop flag.');
    }
    return AudioAssetRecord(
      id: id,
      runtimePath: runtimePath,
      group: group,
      kind: kind,
      duration: duration,
      loop: loop,
    );
  }

  final String id;
  final String runtimePath;
  final String group;
  final String kind;
  final Duration duration;
  final bool loop;

  /// [AudioCache] is rooted at `assets/audio/`.
  String get cachePath => runtimePath.replaceFirst('assets/audio/', '');
}

class AudioAssetCatalog {
  AudioAssetCatalog(Iterable<AudioAssetRecord> records)
      : _records = _indexRecords(records);

  static Map<String, AudioAssetRecord> _indexRecords(
    Iterable<AudioAssetRecord> source,
  ) {
    final records = source.toList(growable: false);
    final indexed = <String, AudioAssetRecord>{};
    for (final record in records) {
      if (indexed.containsKey(record.id)) {
        throw FormatException('Duplicate audio ID: ${record.id}');
      }
      indexed[record.id] = record;
    }
    final ids = indexed.keys.toSet();
    final missing = requiredIds.difference(ids);
    final extra = ids.difference(requiredIds);
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw FormatException(
        'Audio ID set mismatch. Missing: ${missing.join(', ')}; '
        'extra: ${extra.join(', ')}',
      );
    }
    return indexed;
  }

  static const manifestPath = 'assets/audio/audio-manifest-v1.json';

  static final Set<String> requiredIds = <String>{
    AudioIds.gameBase,
    AudioIds.gameGroove,
    AudioIds.gameHype,
    AudioIds.menu,
    AudioIds.shop,
    ...AudioIds.gameMixes,
    ...AudioIds.six,
    ...AudioIds.seven,
    AudioIds.uiTab,
    AudioIds.uiOpen,
    AudioIds.uiClose,
    AudioIds.uiToggleOn,
    AudioIds.uiToggleOff,
    AudioIds.uiError,
    AudioIds.shopPurchase,
    AudioIds.shopBatch,
    AudioIds.shopUnavailable,
    AudioIds.shopUnlock,
    AudioIds.shopMilestone,
    AudioIds.collectionEquip,
    AudioIds.collectionHide,
    for (var i = 1; i <= 5; i++) AudioIds.form(i),
    AudioIds.achievement,
    AudioIds.ascension,
    AudioIds.mark67,
    AudioIds.returnOffline,
    AudioIds.returnBonus,
  };

  final Map<String, AudioAssetRecord> _records;

  static Future<AudioAssetCatalog> load([AssetBundle? bundle]) async {
    final source = bundle ?? rootBundle;
    final decoded = jsonDecode(await source.loadString(manifestPath))
        as Map<String, dynamic>;
    return fromJson(decoded);
  }

  static AudioAssetCatalog fromJson(Map<String, dynamic> decoded) {
    if (decoded['contract'] != 'audio-manifest-v1' ||
        decoded['status'] != 'approved') {
      throw const FormatException(
        'Runtime audio requires the approved audio-manifest-v1 contract.',
      );
    }
    final rawAssets = decoded['assets'];
    if (rawAssets is! List) {
      throw const FormatException('Audio manifest assets must be a list.');
    }
    final total = ((decoded['counts'] as Map?)?['total'] as num?)?.toInt();
    if (total != requiredIds.length || rawAssets.length != total) {
      throw const FormatException('Audio manifest count is not exactly 44.');
    }
    return AudioAssetCatalog(rawAssets.map((item) =>
        AudioAssetRecord.fromJson((item as Map).cast<String, dynamic>())));
  }

  AudioAssetRecord operator [](String id) {
    final record = _records[id];
    if (record == null) throw StateError('Unknown audio asset: $id');
    return record;
  }

  Iterable<AudioAssetRecord> get all => _records.values;
  Iterable<AudioAssetRecord> get soundEffects =>
      _records.values.where((record) => record.group != 'music');
  Iterable<AudioAssetRecord> get music =>
      _records.values.where((record) => record.group == 'music');
}
