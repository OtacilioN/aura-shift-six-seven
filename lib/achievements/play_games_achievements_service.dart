import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../play_games/play_games_models.dart';
import 'achievement_models.dart';
import 'play_games_achievement_ids.dart';

abstract interface class PlayGamesAchievementsService {
  Future<AchievementsInitializationResult> initialize();
  Future<AchievementsInitializationResult> signIn();
  Future<bool> isAuthenticated();
  Future<String?> loadPlayerId();
  Future<PlayGamesOperationResult> unlock(AuraAchievement achievement);
  Future<PlayGamesOperationResult> reveal(AuraAchievement achievement);
  Future<PlayGamesOperationResult> setSteps({
    required AuraAchievement achievement,
    required int steps,
  });
  Future<List<RemoteAchievementState>> load({bool forceReload = false});
  Future<PlayGamesOperationResult> showNativeAchievements();
}

PlayGamesAchievementsService createPlayGamesAchievementsService() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const UnsupportedPlayGamesAchievementsService();
  }
  return MethodChannelPlayGamesAchievementsService();
}

class UnsupportedPlayGamesAchievementsService
    implements PlayGamesAchievementsService {
  const UnsupportedPlayGamesAchievementsService();

  static const _unsupported = PlayGamesOperationResult(
    PlayGamesAvailability.unsupportedPlatform,
  );
  static const _initialization = AchievementsInitializationResult(
    PlayGamesAvailability.unsupportedPlatform,
  );

  @override
  Future<AchievementsInitializationResult> initialize() async =>
      _initialization;
  @override
  Future<AchievementsInitializationResult> signIn() async => _initialization;
  @override
  Future<bool> isAuthenticated() async => false;
  @override
  Future<String?> loadPlayerId() async => null;
  @override
  Future<List<RemoteAchievementState>> load({
    bool forceReload = false,
  }) async =>
      const [];
  @override
  Future<PlayGamesOperationResult> reveal(AuraAchievement achievement) async =>
      _unsupported;
  @override
  Future<PlayGamesOperationResult> setSteps({
    required AuraAchievement achievement,
    required int steps,
  }) async =>
      _unsupported;
  @override
  Future<PlayGamesOperationResult> showNativeAchievements() async =>
      _unsupported;
  @override
  Future<PlayGamesOperationResult> unlock(AuraAchievement achievement) async =>
      _unsupported;
}

class MethodChannelPlayGamesAchievementsService
    implements PlayGamesAchievementsService {
  MethodChannelPlayGamesAchievementsService({
    MethodChannel channel = const MethodChannel(
      'com.otaciliomaia.aurashiftsixseven/play_games',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<AchievementsInitializationResult> initialize() =>
      _initialization('initialize');

  @override
  Future<AchievementsInitializationResult> signIn() =>
      _initialization('signIn');

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await _channel.invokeMethod<bool>('isAuthenticated') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<String?> loadPlayerId() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'loadCurrentPlayer',
      );
      final value = map?['playerId']?.toString();
      return value == null || value.isEmpty ? null : value;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<PlayGamesOperationResult> unlock(AuraAchievement achievement) =>
      _withId(achievement, 'achievementUnlock');

  @override
  Future<PlayGamesOperationResult> reveal(AuraAchievement achievement) =>
      _withId(achievement, 'achievementReveal');

  @override
  Future<PlayGamesOperationResult> setSteps({
    required AuraAchievement achievement,
    required int steps,
  }) {
    if (steps < 0 || steps > 10000) {
      return Future.value(const PlayGamesOperationResult(
        PlayGamesAvailability.notConfigured,
        message: 'Achievement steps are outside the supported range.',
      ));
    }
    return _withId(
      achievement,
      'achievementSetSteps',
      extra: {'steps': steps},
    );
  }

  @override
  Future<List<RemoteAchievementState>> load({
    bool forceReload = false,
  }) async {
    if (!PlayGamesAchievementIds.anyConfigured) return const [];
    try {
      final raw = await _channel.invokeListMethod<Object?>(
            'achievementLoad',
            {'forceReload': forceReload},
          ) ??
          const [];
      return List.unmodifiable([
        for (final item in raw)
          if (item is Map)
            RemoteAchievementState.fromMap(item.cast<Object?, Object?>()),
      ]);
    } on PlatformException {
      rethrow;
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  Future<PlayGamesOperationResult> showNativeAchievements() {
    if (!PlayGamesAchievementIds.anyConfigured) {
      return Future.value(const PlayGamesOperationResult(
        PlayGamesAvailability.notConfigured,
      ));
    }
    return _operation('showNativeAchievements');
  }

  Future<PlayGamesOperationResult> _withId(
    AuraAchievement achievement,
    String method, {
    Map<String, Object?> extra = const {},
  }) {
    final id = PlayGamesAchievementIds.idFor(achievement);
    if (id.isEmpty) {
      assert(() {
        debugPrint(
          '[achievements] Missing Play Console ID for ${achievement.name}.',
        );
        return true;
      }());
      return Future.value(const PlayGamesOperationResult(
        PlayGamesAvailability.notConfigured,
      ));
    }
    return _operation(method, {'achievementId': id, ...extra});
  }

  Future<AchievementsInitializationResult> _initialization(
      String method) async {
    final result = await _operation(method);
    return AchievementsInitializationResult(
      result.availability,
      message: result.message,
    );
  }

  Future<PlayGamesOperationResult> _operation(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
      return const PlayGamesOperationResult.available();
    } on PlatformException catch (error) {
      return PlayGamesOperationResult(
        _availabilityForCode(error.code),
        message: error.message,
      );
    } on MissingPluginException {
      return const PlayGamesOperationResult(
        PlayGamesAvailability.unsupportedPlatform,
      );
    }
  }

  static PlayGamesAvailability _availabilityForCode(String code) =>
      switch (code) {
        'not_configured' => PlayGamesAvailability.notConfigured,
        'unauthenticated' => PlayGamesAvailability.unauthenticated,
        'offline' => PlayGamesAvailability.offline,
        'unsupported' => PlayGamesAvailability.unsupportedPlatform,
        _ => PlayGamesAvailability.temporarilyUnavailable,
      };
}
