import 'dart:convert';
import 'dart:io';

import 'package:aura_shift_six_seven/game/art_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('approved runtime manifest is fully covered by scene and UI registries',
      () {
    final source = File('assets/manifests/art-approved-manifest-v1.json')
        .readAsStringSync();
    final catalog = ArtCatalog.fromJson(source);
    final runtimeIds = catalog.records.map((record) => record.id).toSet();
    final manifest = jsonDecode(source) as Map<String, dynamic>;
    final qaEntries = (manifest['assets'] as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .where((entry) => entry['family'] == 'qa')
        .toList();

    expect(runtimeIds, hasLength(219));
    expect(qaEntries, hasLength(3));
    expect(
        qaEntries.every((entry) => entry['runtimeIncluded'] == false), isTrue);
    for (final entry in qaEntries) {
      expect(catalog[entry['manifestId'] as String], isNull);
    }
    expect(AuraArtSelection.sceneRuntimeIds, hasLength(136));
    expect(AuraUiArt.mappedRuntimeIds, hasLength(83));
    expect(
      AuraArtSelection.sceneRuntimeIds.intersection(AuraUiArt.mappedRuntimeIds),
      isEmpty,
    );
    expect(AuraRuntimeArtCoverage.allConsumerIds, runtimeIds);
  });

  test('approved schema rejects an unapproved manifest or runtime entry', () {
    String manifest({required String status, required String assetStatus}) =>
        '''
      {
        "schemaVersion": "art-approved-manifest-v1",
        "status": "$status",
        "assets": [{
          "manifestId": "icon_info",
          "family": "icons",
          "variant": "base",
          "runtimePath": "assets/art/icons/icon_info.webp",
          "sizePx": [48, 48],
          "sourceSizePx": [96, 96],
          "pivot": [0.5, 0.5],
          "zLayer": "UI-FLUTTER",
          "runtimeIncluded": true,
          "status": "$assetStatus"
        }]
      }
    ''';

    expect(
      () => ArtCatalog.fromJson(
          manifest(status: 'candidate-reviewed', assetStatus: 'approved')),
      throwsFormatException,
    );
    expect(
      () => ArtCatalog.fromJson(
          manifest(status: 'approved', assetStatus: 'candidate-reviewed')),
      throwsFormatException,
    );
  });

  test('v3 manifest exposes distinct face anchors and safe hand centers', () {
    final catalog = ArtCatalog.fromJson(
      File('assets/manifests/art-manifest-v1.json').readAsStringSync(),
    );
    final eyes = catalog['chr_eye_neutral']!;
    final mouth = catalog['chr_mouth_neutral']!;
    expect(eyes.attachmentId, 'FACE_EYES');
    expect(mouth.attachmentId, 'FACE_MOUTH');
    expect(eyes.attachmentStage!.x, 512);
    expect(eyes.attachmentStage!.y, 330);
    expect(mouth.attachmentStage!.x, 512);
    expect(mouth.attachmentStage!.y, 402);
    expect(eyes.attachmentStage!.y, isNot(mouth.attachmentStage!.y));

    final left = catalog['chr_hand_l']!;
    final right = catalog['chr_hand_r']!;
    final leftSix = AuraRigGeometry.handVisualCenter(left, 'six');
    final leftSeven = AuraRigGeometry.handVisualCenter(left, 'seven');
    final rightSix = AuraRigGeometry.handVisualCenter(right, 'six');
    final rightSeven = AuraRigGeometry.handVisualCenter(right, 'seven');
    for (final center in [leftSix, leftSeven, rightSix, rightSeven]) {
      expect(center.x, inInclusiveRange(96, 928));
      expect(center.y, inInclusiveRange(96, 928));
    }
    expect(leftSix.y, lessThan(leftSeven.y));
    expect(rightSeven.y, lessThan(rightSix.y));
  });

  test('runtime catalog skips review-only sheets with no runtime path', () {
    final catalog = ArtCatalog.fromJson('''
      {
        "schemaVersion": "art-manifest-v1",
        "assets": [
          {
            "manifestId": "chr_body_base",
            "family": "character",
            "variant": "base",
            "runtimePath": "assets/art/character/chr_body_base.webp",
            "sizePx": [1024, 1024],
            "sourceSizePx": [1024, 1024],
            "pivot": [0.5, 0.86],
            "zLayer": "SLOT-BODY",
            "runtimeIncluded": true
          },
          {
            "manifestId": "chr_concept_sheet",
            "family": "qa",
            "variant": "review",
            "runtimePath": null,
            "runtimeIncluded": false
          }
        ]
      }
    ''');

    expect(catalog['chr_body_base'], isNotNull);
    expect(catalog['chr_concept_sheet'], isNull);
  });

  group('AuraArtSelection', () {
    test('selects the highest known unlocked form', () {
      expect(
        AuraArtSelection.activeFormId(
          const {'FORM-02', 'UNKNOWN-FORM', 'FORM-05', 'FORM-01'},
        ),
        'FORM-05',
      );
      expect(AuraArtSelection.activeFormId(const {'UNKNOWN-FORM'}), isNull);
    });

    test('maps normal and reduced backgrounds without inferred form 01 planes',
        () {
      expect(
        AuraArtSelection.backgroundIds(null, reduceMotion: true),
        const ['bg_base_reduced'],
      );
      expect(
        AuraArtSelection.backgroundIds('FORM-01', reduceMotion: false),
        const [
          'bg_form_01_grade',
          'bg_base_far',
          'bg_base_mid',
          'bg_base_near',
        ],
      );
      expect(
        AuraArtSelection.backgroundIds('FORM-03', reduceMotion: true),
        const ['bg_form_03_reduced'],
      );
    });

    test('maps content IDs to their manifest skin prefixes', () {
      expect(AuraArtSelection.skinPrefix('ITEM-A-01'), 'skin_item_a_01');
      expect(
        AuraArtSelection.skinPrefix('ITEM-CONV-03'),
        'skin_item_conv_03',
      );
      expect(AuraArtSelection.skinPrefix('TECH-01'), isNull);
      expect(AuraArtSelection.skinPrefix('ITEM-A-06'), isNull);
    });

    test('keeps back and front form overlays in canonical z groups', () {
      expect(
        AuraArtSelection.formBackIds('FORM-03', reduceMotion: false),
        const ['form_03_ambient'],
      );
      expect(
        AuraArtSelection.formFrontIds('FORM-03', reduceMotion: false),
        const ['form_03_weather_symbols'],
      );
      expect(
        AuraArtSelection.formBackIds('FORM-05', reduceMotion: true),
        const ['form_05_reduced'],
      );
      expect(
        AuraArtSelection.formFrontIds('FORM-05', reduceMotion: true),
        isEmpty,
      );
    });

    test('unlocks skin layers at level milestones and flattens reduced motion',
        () {
      expect(
        AuraArtSelection.skinLayerIds(
          'ITEM-B-04',
          level: 0,
          reduceMotion: false,
        ),
        const ['skin_item_b_04_base'],
      );
      expect(
        AuraArtSelection.skinLayerIds(
          'ITEM-B-04',
          level: 10,
          reduceMotion: false,
        ),
        const ['skin_item_b_04_base', 'skin_item_b_04_accent'],
      );
      expect(
        AuraArtSelection.skinLayerIds(
          'ITEM-B-04',
          level: 25,
          reduceMotion: false,
        ),
        const [
          'skin_item_b_04_base',
          'skin_item_b_04_accent',
          'skin_item_b_04_glow',
        ],
      );
      expect(
        AuraArtSelection.skinLayerIds(
          'ITEM-B-04',
          level: 25,
          reduceMotion: true,
        ),
        const ['skin_item_b_04_reduced'],
      );
    });

    test('exposes every appearance layer and separates back-facing slots', () {
      expect(AuraArtSelection.appearanceRuntimeIds, hasLength(72));
      expect(
        AuraArtSelection.appearanceRuntimeIds,
        containsAll(const [
          'skin_item_a_01_base',
          'skin_item_b_05_glow',
          'skin_item_c_03_reduced',
          'skin_item_conv_03_accent',
        ]),
      );
      expect(AuraArtSelection.isBackAppearanceSlot('BODY_BACK'), isTrue);
      expect(AuraArtSelection.isBackAppearanceSlot('GROUND_PROP'), isTrue);
      expect(AuraArtSelection.isBackAppearanceSlot('SCENE_FRAME'), isTrue);
      expect(AuraArtSelection.isBackAppearanceSlot('AURA_BACK'), isTrue);
      expect(AuraArtSelection.isBackAppearanceSlot('CHEST'), isFalse);
      expect(AuraArtSelection.isBackAppearanceSlot('FACE_SIDE'), isFalse);
      expect(AuraArtSelection.isBackAppearanceSlot(null), isFalse);
      expect(
        AuraArtSelection.isHandOverlayAppearanceSlot('HAND_PROP'),
        isTrue,
      );
      expect(
        AuraArtSelection.isHandOverlayAppearanceSlot('HANDS_WEAR'),
        isTrue,
      );
      expect(
        AuraArtSelection.isHandOverlayAppearanceSlot('FACE_WEAR'),
        isFalse,
      );
    });

    test('keeps expression assets paired for each active form', () {
      expect(
        AuraArtSelection.expression('FORM-03', isSeven: false),
        'surprise',
      );
      expect(
        AuraArtSelection.expression('FORM-05', isSeven: true),
        'celebration',
      );
      expect(AuraArtSelection.expression(null, isSeven: false), 'neutral');
      expect(
        AuraArtSelection.expression(null, isSeven: true),
        'satisfaction',
      );
    });
  });

  group('AuraUiArt', () {
    test('maps semantic navigation and event roles', () {
      expect(AuraUiArt.icon(AuraUiIcon.navPlay), 'icon_nav_play');
      expect(
        AuraUiArt.event(AuraEventArtwork.achievement),
        'evt_achievement',
      );
    });

    test('maps persistent content IDs to collection thumbnails and badges', () {
      expect(AuraUiArt.formThumbnail('FORM-05'), 'form_05_thumb');
      expect(AuraUiArt.formThumbnail('FORM-06'), isNull);
      expect(
        AuraUiArt.appearanceThumbnail('ITEM-CONV-03'),
        'skin_item_conv_03_thumb',
      );
      expect(
        AuraUiArt.achievementBadge('ACH-S-07'),
        'badge_ach_s_07',
      );
      expect(AuraUiArt.achievementBadge('ACH-S-08'), isNull);
      expect(AuraUiArt.achievementBadge('UNKNOWN'), isNull);
    });

    test('maps all four Aura Tree branch treatments', () {
      expect(AuraUiArt.branch('A')!.thumbnailId, 'branch_a_thumb');
      expect(AuraUiArt.branch('Spectrum')!.nodeId, 'branch_conv_node');
      expect(AuraUiArt.branch('UNKNOWN'), isNull);
    });
  });
}
