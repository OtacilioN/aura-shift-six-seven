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
    expect(runtimeIds, hasLength(203));
    expect(AuraArtSelection.sceneRuntimeIds, hasLength(120));
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
