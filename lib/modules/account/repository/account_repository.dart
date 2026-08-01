import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_service.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/app_urls.dart';
import '../model/account_response_model.dart';

class AccountRepository {
  Future<AccountResponseModel?> getAccountHistory({
    required int page,
    String filterType = 'today',
  }) async {
    final String? uuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();

    if (uuid == null || token == null) {
      return null;
    }

    String platform = "web";
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    }

    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';

    final Map<String, String> data = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "driver_transation_history",
      "driver_uuid": uuid,
      "filter_type": filterType,
      "page": page.toString(),
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.driverTransactionHistory),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['status'] == true) {
          return AccountResponseModel.fromJson(body);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
