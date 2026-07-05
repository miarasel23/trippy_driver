import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/network/api_service.dart';
import 'package:trippy_customer/store/user_data_store.dart';
import 'package:trippy_customer/utils/app_urls.dart';

import '../model/current_user_model.dart';

class SplashRepository {
  SplashRepository();

  Future<String?> receivingUserData({
    required String plaform,
    required String languageCode,
    required String actionWhen,
    required String token
  }) async {
    try {
      final response = await ApiService().get(
        Uri.parse(AppUrls.getCurrentDriverUser).replace(
          queryParameters: {
            "platform": plaform,
            "language_code": languageCode,
            "action_when": actionWhen,
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        }
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        CurrentUserModel currentUserModel = CurrentUserModel.fromJson(jsonData);
        await UserDataStore.saveUserData(currentUserModel);
        return null;
      } else {
        return "Server error: ${response.statusCode}";
      }
    } on SocketException {
      return "No Internet connection";
    } on TimeoutException {
      return "Request timeout";
    } catch (e) {
      return "Unexpected error: $e";
    }
  }
}
