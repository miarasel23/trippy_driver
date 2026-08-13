import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/app_urls.dart';
import '../../../utils/custom_map_body_builder.dart';
import '../../../store/user_data_store.dart';
import '../../../core/utils/ui_utils.dart';
import '../../splash/model/current_user_model.dart';

/// Handles all API logic for the Profile screen.
class ProfileHelper {
  /// Updates the notification enabled status for the current driver.
  static Future<void> updateNotification({
    required BuildContext context,
    required bool value,
    required String languageCode,
    required VoidCallback onSuccess,
    required VoidCallback onFinally,
  }) async {
    final Map<String, dynamic> data = CustomMapBodyBuilder.build(
      actionWhen: 'driver_profile_edit',
      languageCode: languageCode,
      data: {
        'uuid': UserDataStore.uuid,
        'is_notification_enabled': value ? '1' : '0',
        'device_token_for_notification':
            UserDataStore.userData?.data?.user?.deviceTokenForNotification ?? '',
        'is_active': UserDataStore.userData?.data?.user?.isActive ?? 'ACTIVE',
      },
    );

    try {
      final response = await http.post(
        Uri.parse(AppUrls.driverProfileUpdate),
        body: data,
        headers: {'Authorization': 'Bearer ${UserDataStore.accessToken}'},
      );

      if (response.statusCode == 200) {
        await _refreshCurrentUser(languageCode);
        onSuccess();
      } else {
        throw Exception('Failed to update notification: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        UiUtils.showApiErrorPopup(context, e.toString());
      }
    } finally {
      onFinally();
    }
  }

  /// Updates the driver's profile (name, email, nid).
  static Future<bool> updateProfile({
    required BuildContext context,
    required String languageCode,
    required String phone,
    required String fullName,
    required String email,
    required String nidNumber,
  }) async {
    final Map<String, dynamic> data = CustomMapBodyBuilder.build(
      actionWhen: 'driver_profile_edit',
      languageCode: languageCode,
      data: {
        'phone_number': phone,
        'country_code': 'BD',
        'uuid': UserDataStore.uuid,
        'full_name': fullName,
        'email': email,
        'nid_number': nidNumber.trim(),
        'is_notification_enabled':
            (UserDataStore.userData?.data?.user?.isNotificationEnabled ?? false)
                ? '1'
                : '0',
        'device_token_for_notification':
            UserDataStore.userData?.data?.user?.deviceTokenForNotification ?? '',
        'is_active': UserDataStore.userData?.data?.user?.isActive ?? 'ACTIVE',
      },
    );

    try {
      final response = await http.post(
        Uri.parse(AppUrls.driverProfileUpdate),
        body: data,
        headers: {'Authorization': 'Bearer ${UserDataStore.accessToken}'},
      );

      if (response.statusCode == 200) {
        await _refreshCurrentUser(languageCode);
        return true;
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      if (context.mounted) {
        UiUtils.showApiErrorPopup(context, e.toString());
      }
      return false;
    }
  }

  /// Fetches the latest user data from the server and saves it locally.
  static Future<void> _refreshCurrentUser(String languageCode) async {
    final getResponse = await http.get(
      Uri.parse(AppUrls.getCurrentDriverUser).replace(
        queryParameters: {
          'platform': CustomMapBodyBuilder.getPlatform(),
          'language_code': languageCode,
          'action_when': 'admin_login',
        },
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${UserDataStore.accessToken}',
      },
    );

    if (getResponse.statusCode == 200) {
      final jsonData = jsonDecode(getResponse.body);
      final model = CurrentUserModel.fromJson(jsonData);
      await UserDataStore.saveUserData(model);
    } else {
      throw Exception('Failed to fetch user: ${getResponse.body}');
    }
  }

  /// Logs out the current user and clears all local data.
  static Future<void> logout({required BuildContext context, required String nextRoute}) async {
    await UserDataStore.clearAllData();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, nextRoute, (route) => false);
    }
  }
}
