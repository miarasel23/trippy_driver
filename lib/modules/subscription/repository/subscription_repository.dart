import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_service.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/app_urls.dart';
import '../model/subscription_package_model.dart';

class SubscriptionRepository {
  Future<List<SubscriptionPackageModel>?> getSubscriptionPackages() async {
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

    final queryParameters = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "driver_subscription_list_for_driver",
      "driver_uuid": uuid,
      "country_code": "BD"
    };
    
    // Construct url with query params
    final uri = Uri.parse(AppUrls.listCarSubscriptionForDriver).replace(queryParameters: queryParameters);

    try {
      final response = await ApiService().get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse != null && decodedResponse['status'] == true) {
          final List<dynamic> data = decodedResponse['data'] ?? [];
          return data
              .map((json) => SubscriptionPackageModel.fromJson(json))
              .where((package) => package.subscriptionType != 'REGISTRATION_PACKAGE')
              .toList();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<bool> purchaseSubscriptionPlan(String subscriptionUuid, String transactionId) async {
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

    final queryParameters = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "purchase_driver_subscription_plan",
      "driver_uuid": uuid,
      "country_code": "BD",
      "subscription_uuid": subscriptionUuid,
      "transaction_id": transactionId,
    };
    
    final uri = Uri.parse(AppUrls.purchaseDriverSubscriptionPlan).replace(queryParameters: queryParameters);

    try {
      final response = await ApiService().post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse != null && decodedResponse['status'] == true) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
