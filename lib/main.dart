import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/aura_audio_controller.dart';
import 'core/game_controller.dart';
import 'core/rewarded_ads.dart';
import 'ui/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await GameController.load();
  final audio = await AuraAudioController.create();
  final strings = await Strings.load(controller.locale);
  final rewardedAds = GoogleRewardedAds();
  runApp(AuraApp(
    controller: controller,
    strings: strings,
    audio: audio,
    rewardedAds: rewardedAds,
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
  });
  final GameController controller;
  final Strings strings;
  final AuraAudioController audio;
  final RewardedAds rewardedAds;
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
