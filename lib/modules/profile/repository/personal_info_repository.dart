import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_service.dart';
import '../../splash/model/current_user_model.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/app_urls.dart';

class PersonalInfoRepository {
  Future<List<dynamic>?> getDriverDocumentList() async {
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

    final Map<String, String> bodyParams = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "driver_document_list",
      "driver_uuid": uuid,
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.driverDocumentList),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: bodyParams,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse != null && decodedResponse['status'] == true) {
          return decodedResponse['data'] as List<dynamic>? ?? [];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProfileName({required String fullName}) async {
    final String? uuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();

    if (uuid == null || token == null) {
      return false;
    }

    String platform = "web";
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    }

    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';
    final userActiveStatus = UserDataStore.userData?.data?.user?.isActive ?? 'ACTIVE';

    final Map<String, String> body = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "driver_profile_edit",
      "uuid": uuid,
      "is_active": userActiveStatus,
      "full_name": fullName,
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.driverProfileUpdate),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final getUri = Uri.parse(AppUrls.getCurrentDriverUser).replace(
          queryParameters: {
            "platform": platform,
            "language_code": languageCode,
            "action_when": "admin_login",
          },
        );

        final getResponse = await ApiService().get(
          getUri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          showSnackBarOnError: false,
        );

        if (getResponse.statusCode == 200) {
          final jsonData = jsonDecode(getResponse.body);
          final currentUser = CurrentUserModel.fromJson(jsonData);
          await UserDataStore.saveUserData(currentUser);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
