import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modules/splash/model/current_user_model.dart';

class UserDataStore {
  static const String _accessTokenKey = 'access-token';
  static const String _userDataKey = 'user-data';
  static const String _uuid = 'uuid';
  static const String _lastRouteKey = 'last-route';

  static String? accessToken;
  static String? uuid;
  static CurrentUserModel? userData;

  static Future<void> saveAccessToken(String token) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(_accessTokenKey, token);
    accessToken = token;
  }

  static Future<void> saveUuid(String value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(_uuid, value);
    uuid = value;
  }

  static Future<void> saveUserData(CurrentUserModel currentUserModel) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
      _userDataKey,
      jsonEncode(currentUserModel.toJson()),
    );
    userData = currentUserModel;
  }

  static Future<CurrentUserModel?> getUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? currentUserString = sharedPreferences.getString(_userDataKey);
    if (currentUserString == null) {
      return null;
    }
    CurrentUserModel currentUserModel = CurrentUserModel.fromJson(
      jsonDecode(currentUserString),
    );
    userData = currentUserModel;

    return currentUserModel;
  }

  static Future<String?> getAccessToken() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString(_accessTokenKey);
    accessToken = token;
    return token;
  }

  static Future<String?> getUuid() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? user_uuid = sharedPreferences.getString(_uuid);
    uuid = user_uuid;
    return user_uuid;
  }

  static Future<void> saveLastRoute(String routeName) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(_lastRouteKey, routeName);
  }

  static Future<String?> getLastRoute() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(_lastRouteKey);
  }

  static Future<void> clearAllData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    accessToken = null;
    uuid = null;
    userData = null;
  }
}
