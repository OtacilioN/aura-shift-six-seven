import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

const _artManifestPath = 'assets/manifests/art-approved-manifest-v1.json';

class ArtSize {
  const ArtSize(this.width, this.height);

  final int width;
  final int height;
}

class ArtPivot {
  const ArtPivot(this.x, this.y);

  final double x;
  final double y;
}

class ArtPoint {
  const ArtPoint(this.x, this.y);

  final double x;
  final double y;
}

/// Runtime-facing subset of one `art-manifest-v1` entry.
class ArtAssetRecord {
  const ArtAssetRecord({
    required this.id,
    required this.family,
    required this.variant,
    required this.runtimePath,
    required this.size,
    required this.sourceSize,
    required this.pivot,
    required this.zLayer,
    required this.slot,
    required this.logicalSize,
    required this.attachmentId,
    required this.attachmentStage,
    required this.endpoint,
    required this.visualCenter,
    required this.poseAttachments,
    required this.poseAnglesDegrees,
  });

  factory ArtAssetRecord.fromJson(Map<String, dynamic> json) {
    final id = json['manifestId'];
    final family = json['family'];
    final variant = json['variant'];
    final runtimePath = json['runtimePath'];
    final zLayer = json['zLayer'];
    if (id is! String ||
        family is! String ||
        variant is! String ||
        runtimePath is! String ||
        zLayer is! String) {
      throw const FormatException('Invalid art asset identity');
    }
    if (!runtimePath.startsWith('assets/art/') || runtimePath.contains('..')) {
      throw FormatException('Unsafe art runtime path: $runtimePath');
    }

    return ArtAssetRecord(
      id: id,
      family: family,
      variant: variant,
      runtimePath: runtimePath,
      size: _size(json['sizePx'], id),
      sourceSize: _size(json['sourceSizePx'], id),
      pivot: _pivot(json['pivot'], id),
      zLayer: zLayer,
      slot: json['slot'] is String ? json['slot'] as String : null,
      logicalSize: _optionalSize(json['logicalSizeStagePx'], id),
      attachmentId: json['attachmentId'] is String
          ? json['attachmentId'] as String
          : null,
      attachmentStage: _optionalPoint(json['attachmentStage'], id),
      endpoint: _optionalPoint(json['endpointPx'], id),
      visualCenter: _optionalPoint(json['visualCenterPx'], id),
      poseAttachments: _pointMap(json['poseAttachments'], id),
      poseAnglesDegrees: _numberMap(json['poseAnglesDegrees'], id),
    );
  }

  final String id;
  final String family;
  final String variant;
  final String runtimePath;
  final ArtSize size;
  final ArtSize sourceSize;
  final ArtPivot pivot;
  final String zLayer;
  final String? slot;
  final ArtSize? logicalSize;
  final String? attachmentId;
  final ArtPoint? attachmentStage;
  final ArtPoint? endpoint;
  final ArtPoint? visualCenter;
  final Map<String, ArtPoint> poseAttachments;
  final Map<String, double> poseAnglesDegrees;

  ArtPoint? poseAttachment(String pose) => poseAttachments[pose];

  double? poseAngleDegrees(String pose) => poseAnglesDegrees[pose];

  static ArtSize _size(Object? raw, String id) {
    if (raw is! List || raw.length != 2 || raw[0] is! num || raw[1] is! num) {
      throw FormatException('Invalid size for $id');
    }
    return ArtSize((raw[0] as num).toInt(), (raw[1] as num).toInt());
  }

  static ArtSize? _optionalSize(Object? raw, String id) =>
      raw == null ? null : _size(raw, id);

  static ArtPivot _pivot(Object? raw, String id) {
    if (raw is! List || raw.length != 2 || raw[0] is! num || raw[1] is! num) {
      throw FormatException('Invalid pivot for $id');
    }
    final x = (raw[0] as num).toDouble();
    final y = (raw[1] as num).toDouble();
    if (x < 0 || x > 1 || y < 0 || y > 1) {
      throw FormatException('Out-of-range pivot for $id');
    }
    return ArtPivot(x, y);
  }

  static ArtPoint? _optionalPoint(Object? raw, String id) {
    if (raw == null) return null;
    if (raw is! List || raw.length != 2 || raw[0] is! num || raw[1] is! num) {
      throw FormatException('Invalid point for $id');
    }
    return ArtPoint((raw[0] as num).toDouble(), (raw[1] as num).toDouble());
  }

  static Map<String, ArtPoint> _pointMap(Object? raw, String id) {
    if (raw == null) return const <String, ArtPoint>{};
    if (raw is! Map) throw FormatException('Invalid pose attachments for $id');
    final result = <String, ArtPoint>{};
    for (final entry in raw.entries) {
      if (entry.key is! String) {
        throw FormatException('Invalid pose attachment key for $id');
      }
      final point = _optionalPoint(entry.value, id);
      if (point == null) {
        throw FormatException('Invalid pose attachment for $id');
      }
      result[entry.key as String] = point;
    }
    return Map.unmodifiable(result);
  }

  static Map<String, double> _numberMap(Object? raw, String id) {
    if (raw == null) return const <String, double>{};
    if (raw is! Map) throw FormatException('Invalid pose angles for $id');
    final result = <String, double>{};
    for (final entry in raw.entries) {
      if (entry.key is! String || entry.value is! num) {
        throw FormatException('Invalid pose angle for $id');
      }
      result[entry.key as String] = (entry.value as num).toDouble();
    }
    return Map.unmodifiable(result);
  }
}

/// Pure geometry shared by runtime layout tests and the Flame compositor.
abstract final class AuraRigGeometry {
  static ArtPoint handVisualCenter(ArtAssetRecord hand, String pose) {
    final attachment = hand.poseAttachment(pose);
    final angleDegrees = hand.poseAngleDegrees(pose);
    final visualCenter = hand.visualCenter;
    final logicalSize = hand.logicalSize;
    if (attachment == null ||
        angleDegrees == null ||
        visualCenter == null ||
        logicalSize == null) {
      throw FormatException('Incomplete hand geometry for ${hand.id}/$pose');
    }
    final angle = angleDegrees * math.pi / 180;
    final localX = visualCenter.x - hand.pivot.x * logicalSize.width;
    final localY = visualCenter.y - hand.pivot.y * logicalSize.height;
    return ArtPoint(
      attachment.x + localX * math.cos(angle) - localY * math.sin(angle),
      attachment.y + localX * math.sin(angle) + localY * math.cos(angle),
    );
  }
}

/// Typed lookup backed by the generated manifest, not by inferred filenames.
class ArtCatalog {
  ArtCatalog._(this._records);

  static Future<ArtCatalog> load(AssetBundle bundle) async {
    final source = await bundle.loadString(_artManifestPath);
    return ArtCatalog.fromJson(source);
  }

  /// Parses only runtime entries. Review-only sheets deliberately have no
  /// runtime path and must never make the playable catalog fail to load.
  static ArtCatalog fromJson(String source) {
    final decoded = jsonDecode(source);
    final schemaVersion =
        decoded is Map<String, dynamic> ? decoded['schemaVersion'] : null;
    if (decoded is! Map<String, dynamic> ||
        (schemaVersion != 'art-manifest-v1' &&
            schemaVersion != 'art-approved-manifest-v1') ||
        decoded['assets'] is! List) {
      throw const FormatException('Unsupported art manifest');
    }
    final approvedManifest = schemaVersion == 'art-approved-manifest-v1';
    if (approvedManifest && decoded['status'] != 'approved') {
      throw const FormatException('Art manifest is not approved');
    }

    final records = <String, ArtAssetRecord>{};
    for (final raw in decoded['assets'] as List<dynamic>) {
      if (raw is! Map) {
        throw const FormatException('Invalid art manifest entry');
      }
      final entry = Map<String, dynamic>.from(raw);
      final runtimeIncluded = entry['runtimeIncluded'];
      if (runtimeIncluded != null && runtimeIncluded is! bool) {
        throw const FormatException('Invalid runtimeIncluded flag');
      }
      if (runtimeIncluded == false) continue;
      if (approvedManifest && entry['status'] != 'approved') {
        throw FormatException(
            'Runtime art is not approved: ${entry['manifestId']}');
      }

      final record = ArtAssetRecord.fromJson(entry);
      if (records.containsKey(record.id)) {
        throw FormatException('Duplicate art manifest id: ${record.id}');
      }
      records[record.id] = record;
    }
    return ArtCatalog._(Map.unmodifiable(records));
  }

  final Map<String, ArtAssetRecord> _records;

  ArtAssetRecord? operator [](String id) => _records[id];

  Iterable<ArtAssetRecord> get records => _records.values;
}

/// Pure mapping rules between persistent game IDs and manifest IDs.
abstract final class AuraArtSelection {
  static final _appearanceContentIds = <String>[
    for (final branch in ['A', 'B', 'C'])
      for (var depth = 1; depth <= 5; depth++) 'ITEM-$branch-0$depth',
    for (var depth = 1; depth <= 3; depth++) 'ITEM-CONV-0$depth',
  ];

  static const _backAppearanceSlots = <String>{
    'BODY_BACK',
    'GROUND_BACK',
    'GROUND_PROP',
    'HEAD_BACK',
    'SCENE_FRAME',
    'AURA_BACK',
  };

  static const formIds = <String>[
    'FORM-01',
    'FORM-02',
    'FORM-03',
    'FORM-04',
    'FORM-05',
  ];

  static String? activeFormId(Iterable<String> unlocked) {
    final values = unlocked.toSet();
    for (final formId in formIds.reversed) {
      if (values.contains(formId)) return formId;
    }
    return null;
  }

  static List<String> backgroundIds(
    String? formId, {
    required bool reduceMotion,
  }) {
    final form = _formNumber(formId);
    if (reduceMotion) {
      return <String>[
        form == null ? 'bg_base_reduced' : 'bg_form_${form}_reduced',
      ];
    }

    if (form == null) {
      return const <String>[
        'bg_base_grade',
        'bg_base_far',
        'bg_base_mid',
        'bg_base_near',
      ];
    }
    if (form == '01') {
      return const <String>[
        'bg_form_01_grade',
        'bg_base_far',
        'bg_base_mid',
        'bg_base_near',
      ];
    }
    return <String>[
      'bg_form_${form}_grade',
      'bg_form_${form}_far',
      'bg_form_${form}_mid',
      'bg_form_${form}_near',
    ];
  }

  static List<String> formBackIds(
    String? formId, {
    required bool reduceMotion,
  }) {
    final form = _formNumber(formId);
    if (form == null) return const <String>[];
    if (reduceMotion) return <String>['form_${form}_reduced'];

    return switch (form) {
      '01' => const <String>['form_01_glow', 'form_01_outline'],
      '02' => const <String>['form_02_afterimage'],
      '03' => const <String>['form_03_ambient'],
      '04' => const <String>['form_04_skyline'],
      '05' => const <String>[
          'form_05_ground_link',
          'form_05_horizon_link',
          'form_05_halo',
        ],
      _ => const <String>[],
    };
  }

  static List<String> formFrontIds(
    String? formId, {
    required bool reduceMotion,
  }) {
    if (reduceMotion) return const <String>[];
    return switch (_formNumber(formId)) {
      '02' => const <String>['form_02_trail'],
      '03' => const <String>['form_03_weather_symbols'],
      '04' => const <String>['form_04_pulse'],
      _ => const <String>[],
    };
  }

  static String? skinPrefix(String? contentId) {
    if (contentId == null ||
        !RegExp(r'^ITEM-(?:[ABC]-0[1-5]|CONV-0[1-3])$').hasMatch(contentId)) {
      return null;
    }
    return 'skin_${contentId.toLowerCase().replaceAll('-', '_')}';
  }

  static List<String> skinLayerIds(
    String? contentId, {
    required int level,
    required bool reduceMotion,
  }) {
    final prefix = skinPrefix(contentId);
    if (prefix == null) return const <String>[];
    if (reduceMotion && level >= 10) return <String>['${prefix}_reduced'];

    return <String>[
      '${prefix}_base',
      if (level >= 10) '${prefix}_accent',
      if (!reduceMotion && level >= 25) '${prefix}_glow',
    ];
  }

  /// All appearance layers that can be selected at runtime. Keeping this list
  /// separate from [sceneRuntimeIds] lets the playable scene lazily decode only
  /// the currently equipped skin instead of every approved art asset.
  static Set<String> get appearanceRuntimeIds {
    final ids = <String>{};
    for (final contentId in _appearanceContentIds) {
      ids
        ..addAll(skinLayerIds(contentId, level: 25, reduceMotion: false))
        ..addAll(skinLayerIds(contentId, level: 25, reduceMotion: true));
    }
    return Set.unmodifiable(ids);
  }

  /// Appearance slots authored behind the procedural mascot. Other wearables
  /// are inserted over the body but under the palms, except explicit hand
  /// overlays which are composed after the palms.
  static bool isBackAppearanceSlot(String? slot) =>
      slot != null && _backAppearanceSlots.contains(slot);

  static bool isHandOverlayAppearanceSlot(String? slot) =>
      slot == 'HAND_PROP' || slot == 'HANDS_WEAR';

  static String expression(String? formId, {required bool isSeven}) {
    return switch (formId) {
      'FORM-01' => 'satisfaction',
      'FORM-02' => 'focus',
      'FORM-03' => 'surprise',
      'FORM-04' => 'focus',
      'FORM-05' => 'celebration',
      _ => isSeven ? 'satisfaction' : 'neutral',
    };
  }

  static String? _formNumber(String? formId) {
    final index = formIds.indexOf(formId ?? '');
    return index < 0 ? null : '${index + 1}'.padLeft(2, '0');
  }

  /// Every manifest ID consumed by the Flame scene, including all dynamic
  /// form, expression, appearance milestone, and reduced-motion variants.
  static Set<String> get sceneRuntimeIds {
    final ids = <String>{
      'chr_shadow',
      'chr_body_base',
      'chr_arm_l',
      'chr_arm_r',
      'chr_hand_l',
      'chr_hand_r',
      for (final expression in const [
        'neutral',
        'satisfaction',
        'focus',
        'surprise',
        'celebration',
      ]) ...[
        'chr_eye_$expression',
        'chr_mouth_$expression',
      ],
      'vfx_contact',
      'vfx_orb',
      'vfx_ribbon',
      'vfx_spark',
      'vfx_trail',
    };
    for (final formId in <String?>[null, ...formIds]) {
      ids
        ..addAll(backgroundIds(formId, reduceMotion: false))
        ..addAll(backgroundIds(formId, reduceMotion: true))
        ..addAll(formBackIds(formId, reduceMotion: false))
        ..addAll(formBackIds(formId, reduceMotion: true))
        ..addAll(formFrontIds(formId, reduceMotion: false));
    }
    ids.addAll(appearanceRuntimeIds);
    return Set.unmodifiable(ids);
  }
}

/// Semantic UI roles backed by generated manifest IDs.
///
/// Widgets should request art by role/content ID through this class instead of
/// reconstructing filenames. The manifest remains the source of the concrete
/// runtime path.
enum AuraUiIcon {
  achievement,
  appearance,
  ascension,
  auraAvailable,
  auraItem,
  auraTotal,
  backup,
  cyclePower,
  info,
  itemEffect,
  lock,
  navCollection,
  navPlay,
  navSettings,
  navShop,
  passiveRate,
  phaseSeven,
  phaseSix,
  rewardedAd,
  seal,
  technique,
  transformation,
}

enum AuraEventArtwork {
  aura67,
  achievement,
  ascension,
  milestone,
  purchase,
  transformation,
}

class AuraBranchArtwork {
  const AuraBranchArtwork({
    required this.backplateId,
    required this.edgeId,
    required this.nodeId,
    this.thumbnailId,
  });

  final String backplateId;
  final String edgeId;
  final String nodeId;
  final String? thumbnailId;
}

abstract final class AuraUiArt {
  static const _icons = <AuraUiIcon, String>{
    AuraUiIcon.achievement: 'icon_achievement',
    AuraUiIcon.appearance: 'icon_appearance',
    AuraUiIcon.ascension: 'icon_ascension',
    AuraUiIcon.auraAvailable: 'icon_aura_available',
    AuraUiIcon.auraItem: 'icon_aura_item',
    AuraUiIcon.auraTotal: 'icon_aura_total',
    AuraUiIcon.backup: 'icon_backup',
    AuraUiIcon.cyclePower: 'icon_cycle_power',
    AuraUiIcon.info: 'icon_info',
    AuraUiIcon.itemEffect: 'icon_item_effect',
    AuraUiIcon.lock: 'icon_lock',
    AuraUiIcon.navCollection: 'icon_nav_collection',
    AuraUiIcon.navPlay: 'icon_nav_play',
    AuraUiIcon.navSettings: 'icon_nav_settings',
    AuraUiIcon.navShop: 'icon_nav_shop',
    AuraUiIcon.passiveRate: 'icon_passive_rate',
    AuraUiIcon.phaseSeven: 'icon_phase_seven',
    AuraUiIcon.phaseSix: 'icon_phase_six',
    AuraUiIcon.rewardedAd: 'icon_rewarded_ad',
    AuraUiIcon.seal: 'icon_seal',
    AuraUiIcon.technique: 'icon_technique',
    AuraUiIcon.transformation: 'icon_transformation',
  };

  static const _events = <AuraEventArtwork, String>{
    AuraEventArtwork.aura67: 'evt_67',
    AuraEventArtwork.achievement: 'evt_achievement',
    AuraEventArtwork.ascension: 'evt_ascension',
    AuraEventArtwork.milestone: 'evt_milestone',
    AuraEventArtwork.purchase: 'evt_purchase',
    AuraEventArtwork.transformation: 'evt_transform',
  };

  static const _branches = <String, AuraBranchArtwork>{
    'A': AuraBranchArtwork(
      backplateId: 'branch_a_backplate',
      edgeId: 'branch_a_edge',
      nodeId: 'branch_a_node',
      thumbnailId: 'branch_a_thumb',
    ),
    'B': AuraBranchArtwork(
      backplateId: 'branch_b_backplate',
      edgeId: 'branch_b_edge',
      nodeId: 'branch_b_node',
      thumbnailId: 'branch_b_thumb',
    ),
    'C': AuraBranchArtwork(
      backplateId: 'branch_c_backplate',
      edgeId: 'branch_c_edge',
      nodeId: 'branch_c_node',
      thumbnailId: 'branch_c_thumb',
    ),
    'Spectrum': AuraBranchArtwork(
      backplateId: 'branch_conv_backplate',
      edgeId: 'branch_conv_edge',
      nodeId: 'branch_conv_node',
    ),
  };

  static const sealLayerIds = <String>[
    'seal_67_cardinal',
    'seal_67_ring',
    'seal_67_core',
  ];

  static const sealLockedThumbnailId = 'seal_67_thumb_mask';

  static String icon(AuraUiIcon role) => _icons[role]!;

  static String event(AuraEventArtwork role) => _events[role]!;

  static AuraBranchArtwork? branch(String branchId) => _branches[branchId];

  static String? appearanceThumbnail(String contentId) {
    final prefix = AuraArtSelection.skinPrefix(contentId);
    return prefix == null ? null : '${prefix}_thumb';
  }

  static String? formThumbnail(String formId) {
    final index = AuraArtSelection.formIds.indexOf(formId);
    if (index < 0) return null;
    final number = '${index + 1}'.padLeft(2, '0');
    return 'form_${number}_thumb';
  }

  static String? achievementBadge(String achievementId) {
    final match = RegExp(r'^ACH-([VS])-0([1-9])$').firstMatch(achievementId);
    if (match == null) return null;
    final type = match.group(1)!;
    final index = int.parse(match.group(2)!);
    if (index > (type == 'V' ? 6 : 7)) return null;
    return 'badge_ach_${type.toLowerCase()}_0$index';
  }

  /// Static UI coverage registry used by verification to prevent approved art
  /// from being bundled without a real screen or event consumer.
  static Set<String> get mappedRuntimeIds {
    final ids = <String>{
      ..._icons.values,
      ..._events.values,
      ...sealLayerIds,
      sealLockedThumbnailId,
      for (final branch in _branches.values) ...[
        branch.backplateId,
        branch.edgeId,
        branch.nodeId,
        if (branch.thumbnailId != null) branch.thumbnailId!,
      ],
      for (final formId in AuraArtSelection.formIds) formThumbnail(formId)!,
      for (final type in const ['V', 'S'])
        for (var index = 1; index <= (type == 'V' ? 6 : 7); index++)
          achievementBadge('ACH-$type-0$index')!,
    };
    for (final branch in const ['A', 'B', 'C']) {
      for (var depth = 1; depth <= 5; depth++) {
        ids.add(appearanceThumbnail('ITEM-$branch-0$depth')!);
      }
    }
    for (var depth = 1; depth <= 3; depth++) {
      ids.add(appearanceThumbnail('ITEM-CONV-0$depth')!);
    }
    return Set.unmodifiable(ids);
  }
}

abstract final class AuraRuntimeArtCoverage {
  static Set<String> get allConsumerIds => Set.unmodifiable({
        ...AuraArtSelection.sceneRuntimeIds,
        ...AuraUiArt.mappedRuntimeIds,
      });
}
