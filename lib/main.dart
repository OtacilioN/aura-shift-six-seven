import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio/aura_audio_controller.dart';
import 'achievements/achievement_progress_repository.dart';
import 'achievements/achievement_sync_service.dart';
import 'achievements/play_games_achievements_service.dart';
import 'cloud_save/cloud_game_save_repository.dart';
import 'cloud_save/cloud_save_coordinator.dart';
import 'cloud_save/local_game_save_repository.dart';
import 'core/game_controller.dart';
import 'core/rewarded_ads.dart';
import 'core/return_reminder_notifications.dart';
import 'core/store_review.dart';
import 'play_games/play_games_coordinator.dart';
import 'play_games/play_games_service.dart';
import 'play_games/play_games_store.dart';
import 'ui/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await GameController.load(deferOfflineProgress: true);
  final audio = await AuraAudioController.create();
  final strings = await Strings.load(controller.locale);
  final rewardedAds = GoogleRewardedAds();
  final returnReminders = await ReturnReminderNotifications.create();
  final storeReview = StoreReview();
  final playGamesService = createPlayGamesService();
  final playGames = PlayGamesCoordinator(
    controller: controller,
    service: playGamesService,
    store: await SharedPreferencesPlayGamesStore.create(),
  );
  final cloudSave = CloudSaveCoordinator(
    controller: controller,
    localRepository: LocalGameSaveRepository(
      controller: controller,
      preferences: await SharedPreferences.getInstance(),
    ),
    cloudRepository: createCloudGameSaveRepository(),
    playGamesService: playGamesService,
  );
  await cloudSave.initialize();
  final achievements = AchievementSyncService(
    controller: controller,
    service: createPlayGamesAchievementsService(),
    repository: await SharedPreferencesAchievementProgressRepository.create(),
  );
  unawaited(achievements.initialize());
  unawaited(playGames.initialize());
  runApp(AuraApp(
    controller: controller,
    strings: strings,
    audio: audio,
    rewardedAds: rewardedAds,
    returnReminders: returnReminders,
    storeReview: storeReview,
    playGames: playGames,
    achievements: achievements,
    cloudSave: cloudSave,
  ));
}

class Strings extends ChangeNotifier {
  Strings._(this.locale, this._values);
  String locale;
  Map<String, String> _values;
  static const supported = <String, String>{
    'en-US': 'English (United States)',
    'pt-BR': 'Português (Brasil)',
    'es-419': 'Español (Latinoamérica)',
    'fr-FR': 'Français (France)',
    'de-DE': 'Deutsch (Deutschland)',
    'id': 'Bahasa Indonesia',
    'ja-JP': '日本語',
    'ar': 'العربية',
  };
  static Future<Strings> load(String locale) async {
    final safe = supported.containsKey(locale) ? locale : 'en-US';
    final decoded =
        jsonDecode(await rootBundle.loadString('assets/l10n/$safe.json'))
            as Map<String, dynamic>;
    return Strings._(
        safe, decoded.map((key, value) => MapEntry(key, '$value')));
  }

  String call(String key, [Map<String, String> values = const {}]) {
    var result = _values[key] ?? key;
    values
        .forEach((name, value) => result = result.replaceAll('{$name}', value));
    return result;
  }

  Future<void> change(String next) async {
    final loaded = await load(next);
    locale = loaded.locale;
    _values = loaded._values;
    notifyListeners();
  }
}

class AuraApp extends StatelessWidget {
  const AuraApp({
    super.key,
    required this.controller,
    required this.strings,
    required this.audio,
    required this.rewardedAds,
    required this.returnReminders,
    required this.storeReview,
    required this.playGames,
    required this.achievements,
    required this.cloudSave,
  });
  final GameController controller;
  final Strings strings;
  final AuraAudioController audio;
  final RewardedAds rewardedAds;
  final ReturnReminderNotifications returnReminders;
  final StoreReview storeReview;
  final PlayGamesCoordinator playGames;
  final AchievementSyncService achievements;
  final CloudSaveCoordinator cloudSave;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([controller, strings]),
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: strings('app_title'),
          theme: auraTheme(controller.highContrast, strings.locale),
          builder: (context, child) => Directionality(
            textDirection:
                strings.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: Home(
            controller: controller,
            strings: strings,
            audio: audio,
            rewardedAds: rewardedAds,
            returnReminders: returnReminders,
            storeReview: storeReview,
            playGames: playGames,
            achievements: achievements,
            cloudSave: cloudSave,
          ),
        ),
      );
}

ThemeData auraTheme(bool highContrast, String locale) {
  const canvas = Color(0xFF090B1A);
  const surface = Color(0xFF161B3A);
  const text = Color(0xFFF7F5FF);
  const cyan = Color(0xFF43E6FF);
  const violet = Color(0xFF8B7CFF);
  final bodyFamily = locale == 'ar'
      ? 'NotoSansArabic'
      : locale == 'ja-JP'
          ? 'NotoSansJP'
          : 'NotoSans';
  final displayFamily = locale == 'ar' ? 'NotoKufiArabic' : 'MPlusRounded';
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: canvas,
    useMaterial3: true,
    fontFamily: bodyFamily,
    colorScheme: const ColorScheme.dark(
        primary: cyan,
        onPrimary: canvas,
        surface: surface,
        onSurface: text,
        secondary: violet),
    textTheme: TextTheme(
        displaySmall: TextStyle(
            fontFamily: displayFamily,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: text),
        titleLarge: TextStyle(
            fontFamily: displayFamily,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: text),
        titleMedium: TextStyle(
            fontFamily: displayFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: text),
        bodyLarge: const TextStyle(fontSize: 16, color: text),
        bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFFC9C7D8))),
    cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color:
                    highContrast ? text : Colors.white.withValues(alpha: 0.07),
                width: highContrast ? 2 : 1))),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0E1230),
        elevation: 0,
        height: 74,
        indicatorColor: cyan.withValues(alpha: 0.16),
        indicatorShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? cyan
                : Colors.white.withValues(alpha: 0.55))),
        surfaceTintColor: Colors.transparent),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: cyan,
            foregroundColor: canvas,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: TextStyle(
              fontFamily: bodyFamily,
              fontWeight: FontWeight.w800,
            ))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: text,
            side: BorderSide(color: cyan.withValues(alpha: 0.4)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: TextStyle(
              fontFamily: bodyFamily,
              fontWeight: FontWeight.w700,
            ))),
    switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? cyan : Colors.white70),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? cyan.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.12)),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.white.withValues(alpha: 0.12))),
    sliderTheme: const SliderThemeData(
        activeTrackColor: cyan,
        inactiveTrackColor: Color(0x334C5276),
        thumbColor: cyan,
        overlayColor: Color(0x3343E6FF)),
    dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08), thickness: 1),
  );
}
