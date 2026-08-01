import 'dart:async';
import 'dart:convert';

import 'package:aura_shift_six_seven/achievements/achievement_progress_repository.dart';
import 'package:aura_shift_six_seven/achievements/achievement_sync_service.dart';
import 'package:aura_shift_six_seven/achievements/play_games_achievements_service.dart';
import 'package:aura_shift_six_seven/audio/audio_backend.dart';
import 'package:aura_shift_six_seven/audio/audio_catalog.dart';
import 'package:aura_shift_six_seven/audio/aura_audio_controller.dart';
import 'package:aura_shift_six_seven/cloud_save/cloud_game_save_repository.dart';
import 'package:aura_shift_six_seven/cloud_save/cloud_save_coordinator.dart';
import 'package:aura_shift_six_seven/cloud_save/local_game_save_repository.dart';
import 'package:aura_shift_six_seven/core/game_controller.dart';
import 'package:aura_shift_six_seven/core/return_reminder_notifications.dart';
import 'package:aura_shift_six_seven/core/rewarded_ads.dart';
import 'package:aura_shift_six_seven/core/store_review.dart';
import 'package:aura_shift_six_seven/main.dart';
import 'package:aura_shift_six_seven/play_games/play_games_coordinator.dart';
import 'package:aura_shift_six_seven/play_games/play_games_service.dart';
import 'package:aura_shift_six_seven/play_games/play_games_store.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_save_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AndroidFlutterLocalNotificationsPlugin.registerWith();

  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const timezoneChannel = MethodChannel('flutter_timezone');
  late AudioAssetCatalog audioCatalog;
  late Strings strings;

  setUpAll(() async {
    final loaded = await Future.wait<Object>([
      AudioAssetCatalog.load(),
      Strings.load('pt-BR'),
    ]);
    audioCatalog = loaded[0] as AudioAssetCatalog;
    strings = loaded[1] as Strings;
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, (call) async => 'UTC');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, (call) async {
      if (call.method == 'initialize') return true;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, null);
  });

  const lifecyclePaths = <String, List<AppLifecycleState>>{
    'paused': [AppLifecycleState.paused],
    'inactive → paused → detached': [
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ],
  };

  for (final path in lifecyclePaths.entries) {
    testWidgets(
      'shows return reward after >10 minutes via ${path.key} → resumed',
      (tester) async {
        final harness = await _HomeHarness.create(
          audioCatalog: audioCatalog,
          strings: strings,
        );
        addTearDown(harness.dispose);

        await tester.pumpWidget(harness.app);
        await tester.pump();

        for (final state in path.value) {
          tester.binding.handleAppLifecycleStateChanged(state);
          await tester.pump();
        }

        final movementsBeforePausedTap = harness.controller.manualMovements;
        await tester.tap(
          find.byWidgetPredicate((widget) => widget is GameWidget),
        );
        await tester.pump();
        expect(
          harness.controller.manualMovements,
          movementsBeforePausedTap,
          reason: 'A paused scene must not credit invisible Aura input.',
        );

        final pausedState = harness.controller.captureSaveState();
        expect(
          pausedState['offlineAt'],
          isA<int>(),
          reason: '${path.key} must freeze offline progress before resume.',
        );
        expect(pausedState['offlineRate'], isNotNull);

        final oldOfflineAt = DateTime.now()
            .subtract(const Duration(minutes: 10, seconds: 1))
            .millisecondsSinceEpoch;
        final agedState = <String, dynamic>{
          ...pausedState,
          'offlineAt': oldOfflineAt,
        };
        expect(
          await harness.controller.replaceAuthoritativeState(agedState),
          isTrue,
        );

        final blockedResume = Completer<CloudRemoteResult>();
        harness.cloud.blockedOpen = blockedResume;
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Reconciliation may depend on the network or Play Games. The local
        // reward and its modal must not wait for that external operation.
        expect(harness.controller.returnRewardAvailable, isTrue);
        expect(
          find.text(strings('return_title')),
          findsOneWidget,
          reason:
              'The pending reward must surface without closing and reopening '
              'the app.',
        );
        expect(
          find.byKey(const ValueKey('return-reward-sheet')),
          findsOneWidget,
        );

        blockedResume.complete(const CloudRemoteMissing());
        harness.cloud.blockedOpen = null;
        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        harness.dispose();
      },
    );
  }
}

class _HomeHarness {
  _HomeHarness({
    required this.controller,
    required this.audio,
    required this.ads,
    required this.playGames,
    required this.achievements,
    required this.cloud,
    required this.cloudSave,
    required this.app,
  });

  final GameController controller;
  final AuraAudioController audio;
  final _UnavailableRewardedAds ads;
  final PlayGamesCoordinator playGames;
  final AchievementSyncService achievements;
  final FakeCloudGameSaveRepository cloud;
  final CloudSaveCoordinator cloudSave;
  final Widget app;
  bool _disposed = false;

  static Future<_HomeHarness> create({
    required AudioAssetCatalog audioCatalog,
    required Strings strings,
  }) async {
    SharedPreferences.setMockInitialValues({
      'save-v1': jsonEncode({
        'available': '0',
        'total': '0',
        'journey': '0',
        'remainder': '0',
        'multiplier': '100',
        'levels': <String, int>{'ITEM-A-01': 1},
        'returnReminderPrompted': true,
      }),
    });
    final preferences = await SharedPreferences.getInstance();
    final controller =
        await GameController.loadForTesting(deferOfflineProgress: true);
    final audio = await AuraAudioController.createForTesting(
      catalog: audioCatalog,
      backend: _SilentAudioBackend(),
      store: _MemoryAudioSettingsStore(),
    );
    final ads = _UnavailableRewardedAds();
    final playGames = PlayGamesCoordinator(
      controller: controller,
      service: const UnsupportedPlayGamesService(),
      store: _MemoryPlayGamesStore(),
    );
    final achievements = AchievementSyncService(
      controller: controller,
      service: const UnsupportedPlayGamesAchievementsService(),
      repository: SharedPreferencesAchievementProgressRepository(preferences),
      syncInterval: const Duration(days: 1),
    );
    final cloud = FakeCloudGameSaveRepository();
    final cloudSave = CloudSaveCoordinator(
      controller: controller,
      localRepository: LocalGameSaveRepository(
        controller: controller,
        preferences: preferences,
      ),
      cloudRepository: cloud,
      playGamesService: const UnsupportedPlayGamesService(),
      syncInterval: const Duration(days: 1),
    );
    await cloudSave.initialize();
    final returnReminders = await ReturnReminderNotifications.create();
    final app = AuraApp(
      controller: controller,
      strings: strings,
      audio: audio,
      rewardedAds: ads,
      returnReminders: returnReminders,
      storeReview: StoreReview(),
      playGames: playGames,
      achievements: achievements,
      cloudSave: cloudSave,
    );
    return _HomeHarness(
      controller: controller,
      audio: audio,
      ads: ads,
      playGames: playGames,
      achievements: achievements,
      cloud: cloud,
      cloudSave: cloudSave,
      app: app,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cloudSave.dispose();
    achievements.dispose();
    playGames.dispose();
    ads.dispose();
    audio.dispose();
    controller.dispose();
  }
}

class _UnavailableRewardedAds extends RewardedAds {
  @override
  RewardedAdAvailability availabilityFor(RewardedPlacement placement) =>
      RewardedAdAvailability.unavailable;

  @override
  Future<void> initialize() async {}

  @override
  RewardedAdDiagnostic? lastDiagnosticFor(RewardedPlacement placement) => null;

  @override
  bool get privacyOptionsRequired => false;

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<bool> show(
    RewardedPlacement placement, {
    VoidCallback? onAdShowed,
    VoidCallback? onAdClosed,
  }) async =>
      false;

  @override
  Future<bool> showPrivacyOptions() async => false;
}

class _MemoryPlayGamesStore implements PlayGamesStore {
  Map<String, dynamic> state = <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> read() async => Map<String, dynamic>.from(state);

  @override
  Future<void> write(Map<String, dynamic> value) async {
    state = Map<String, dynamic>.from(value);
  }
}

class _MemoryAudioSettingsStore implements AudioSettingsStore {
  final Map<String, Object> values = <String, Object>{};

  @override
  bool? readBool(String key) => values[key] as bool?;

  @override
  double? readDouble(String key) => values[key] as double?;

  @override
  Future<void> writeBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> writeDouble(String key, double value) async =>
      values[key] = value;
}

class _SilentAudioBackend implements AudioBackend {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize({Iterable<String> preloadPaths = const []}) async {}

  @override
  Future<void> pauseMusic() async {}

  @override
  Future<MusicPlaybackHandle> playMusic(
    String cachePath, {
    required double volume,
    required Duration transition,
    required bool loop,
    bool preservePosition = false,
  }) async =>
      const _SilentMusicHandle();

  @override
  Future<void> playMusicLayers(
    Map<String, double> cachePathGains, {
    required double volume,
    required Duration transition,
  }) async {}

  @override
  Future<AudioPlaybackHandle> playSound(
    String cachePath, {
    required double volume,
    required Duration duration,
  }) async =>
      const _SilentAudioHandle();

  @override
  Future<void> resumeMusic() async {}

  @override
  Future<void> setMusicVolume(double volume) async {}

  @override
  Future<void> stopSounds() async {}
}

class _SilentMusicHandle implements MusicPlaybackHandle {
  const _SilentMusicHandle();

  @override
  Future<void> get completed => Completer<void>().future;

  @override
  Stream<Duration> get position => const Stream<Duration>.empty();
}

class _SilentAudioHandle implements AudioPlaybackHandle {
  const _SilentAudioHandle();

  @override
  Future<void> get completed => Future<void>.value();

  @override
  Future<void> stop() async {}
}
