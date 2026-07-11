import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_service.dart';
import '../../../store/user_data_store.dart';
import '../../../utils/app_urls.dart';
import '../model/rental_trip_model.dart';

class HomeRepository {
  Future<String?> updateRideStatus({
    required String status,
  }) async {
    final String? uuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();

    if (uuid == null || token == null) {
      return "User not authenticated";
    }

    String platform = "web";
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    }

    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';

    String apiStatus = status;
    if (status == 'RENT A CAR') apiStatus = 'RENT_A_CAR';
    if (status == 'RIDE SHARE') apiStatus = 'RIDE_SHARE';
    if (status == 'BOTH') apiStatus = 'BOTH';

    final Map<String, String> data = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "driver_current_ride_status_update",
      "driver_uuid": uuid,
      "current_ride_status": apiStatus,
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.currentRideStatus),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      } else {
        return "Failed to update status: ${response.statusCode}";
      }
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  Future<List<RentalTripModel>?> getRentalTrips() async {
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

    final Map<String, String> queryParams = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "rental_list_for_driver",
      "driver_uuid": uuid,
      "trip_status": "REQUESTED",
    };

    final uri = Uri.parse(AppUrls.rentalTripList).replace(queryParameters: queryParams);

    try {
      final response = await ApiService().get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['status'] == true && body['data'] != null) {
          final List<dynamic> data = body['data'];
          return data.map((e) => RentalTripModel.fromJson(e)).toList();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
