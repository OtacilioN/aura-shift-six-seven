import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PlayGamesStore {
  Future<Map<String, dynamic>> read();
  Future<void> write(Map<String, dynamic> state);
}

class SharedPreferencesPlayGamesStore implements PlayGamesStore {
  SharedPreferencesPlayGamesStore(this._preferences);

  static const storageKey = 'play-games-v1';
  final SharedPreferences _preferences;

  static Future<SharedPreferencesPlayGamesStore> create() async =>
      SharedPreferencesPlayGamesStore(
        await SharedPreferences.getInstance(),
      );

  @override
  Future<Map<String, dynamic>> read() async {
    final value = _preferences.getString(storageKey);
    if (value == null) return <String, dynamic>{};
    try {
      return (jsonDecode(value) as Map).cast<String, dynamic>();
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Future<void> write(Map<String, dynamic> state) =>
      _preferences.setString(storageKey, jsonEncode(state));
}
