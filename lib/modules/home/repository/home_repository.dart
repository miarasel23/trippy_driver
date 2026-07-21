import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

  Future<String?> submitBid({
    required String tripUuid,
    required double bidAmount,
  }) async {
    final String? uuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();

    if (uuid == null || token == null) return "Missing driver auth";

    String platform = Platform.isAndroid ? "android" : (Platform.isIOS ? "ios" : "web");
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';

    final Map<String, String> body = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "create_trip_bid",
      "request_type": "create_trip_bid",
      "trip_uuid": tripUuid,
      "driver_uuid": uuid,
      "bid_amount": bidAmount.toString(),
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.createTripBid),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: body,
      );

      final respBody = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (respBody['status'] == true) {
          return null; 
        }
      }
      return respBody['message'] ?? "Failed to submit bid";
    } catch (e) {
      return "Network error: $e";
    }
  }

  Future<String?> updateTripRideStatus({
    required String tripUuid,
    required String status,
  }) async {
    final String? uuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();

    if (uuid == null || token == null) return "Missing driver auth";

    String platform = Platform.isAndroid ? "android" : (Platform.isIOS ? "ios" : "web");
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';

    final Map<String, String> body = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "trip_or_ride_status_update",
      "trip_uuid": tripUuid,
      "driver_uuid": uuid,
      "status": status,
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.tripRideStatusUpdate),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: body,
      );

      final respBody = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (respBody['status'] == true) {
          return null; 
        }
      }
      return respBody['message'] ?? "Failed to update trip status";
    } catch (e) {
      return "Network error: $e";
    }
  }

  Future<List<RentalTripModel>?> getBidTripList() async {
    final String? uuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();

    if (uuid == null || token == null) return null;

    String platform = Platform.isAndroid ? "android" : (Platform.isIOS ? "ios" : "web");
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';

    final Map<String, String> params = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "rental_bid_trip_list_for_driver",
      "driver_uuid": uuid,
      "trip_status": "REQUESTED", // Changed from ALL - API only recognises specific statuses
    };

    final uri = Uri.parse(AppUrls.rentalBidTripList).replace(queryParameters: params);
    debugPrint('[getBidTripList] Calling: $uri');

    try {
      final response = await ApiService().get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      List<RentalTripModel> allTrips = [];

      debugPrint('[getBidTripList] Status: \${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        debugPrint('[getBidTripList] Body status: \${body[\'status\']}, data count: \${(body[\'data\'] as List?)?.length ?? 0}');
        if (body['status'] == true && body['data'] != null) {
          final List<dynamic> data = body['data'];
          allTrips.addAll(data.map((e) => RentalTripModel.fromJson(e)).toList());
        }
      }
      debugPrint('[getBidTripList] Returning \${allTrips.length} trips');
      for (var t in allTrips) {
        debugPrint('  -> trip uuid=\${t.uuid} service=\${t.serviceName} myBid=\${t.myBid?.status}');
      }
      return allTrips;
    } catch (e) {
      debugPrint('[getBidTripList] ERROR: $e');
      return null;
    }
  }



  Future<List<RentalTripModel>?> getActiveBidTrips() async {
    final String? uuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();

    if (uuid == null || token == null) return null;

    String platform = Platform.isAndroid ? "android" : (Platform.isIOS ? "ios" : "web");
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';

    final Map<String, String> params = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "accept_or_cancel_or_complete_trip_for_driver",
      "driver_uuid": uuid,
      "status": "ALL",
    };

    final uri = Uri.parse(AppUrls.getActiveBidTrips);

    try {
      final response = await ApiService().post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: params,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['status'] == true && body['data'] != null) {
          final List<dynamic> data = body['data'];
          final trips = <RentalTripModel>[];
          for (var item in data) {
            if (item is! Map) continue;
            
            final Map<String, dynamic> flatJson = Map<String, dynamic>.from(item);

            // Find my bid (driver's bid)
            final drivers = flatJson['drivers'] as List? ?? [];
            Map<String, dynamic>? myBidJson;
            for (var d in drivers) {
              if (d is Map && d['driver_uuid']?.toString().toLowerCase() == uuid.toLowerCase()) {
                myBidJson = {
                  'uuid': d['rent_bid_uuid'],
                  'amount': d['bid_amount'],
                  'status': d['bid_status'],
                  'created_at': flatJson['created_at'],
                };
                break;
              }
            }
            if (myBidJson != null) {
              flatJson['my_bid'] = myBidJson;
            }

            try {
              final trip = RentalTripModel.fromJson(flatJson);
              if (trip.myBid != null) {
                trips.add(trip);
              }
            } catch (e) {
              // Ignore parsing errors for individual trips
            }
          }
          return trips;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> searchLocation(String address) async {
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();
    if (token == null) return null;

    String platform = Platform.isAndroid ? "android" : (Platform.isIOS ? "ios" : "web");
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';

    final Map<String, String> data = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "search_locations",
      "search_location": address,
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.searchLocation),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: data,
      );
      // print removed

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['status'] == true && body['data'] != null && (body['data'] as List).isNotEmpty) {
          return body['data'][0]['uuid'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> trackDriverLocation(String geolocationUuid) async {
    final String? uuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();
    if (uuid == null || token == null) return;

    String platform = Platform.isAndroid ? "android" : (Platform.isIOS ? "ios" : "web");
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';

    final Map<String, String> data = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "track_location_insert",
      "geolocation_uuid": geolocationUuid,
      "driver_uuid": uuid,
    };

    try {
      await ApiService().post(
        Uri.parse(AppUrls.createDriverTrack),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: data,
      );
    } catch (e) {
      // Background process, swallow error
    }
  }

  Future<String?> cancelTrip({
    required String driverUuid,
    required String tripUuid,
    required String comment,
  }) async {
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();
    if (token == null) return "User not authenticated";

    String platform = Platform.isAndroid ? "android" : (Platform.isIOS ? "ios" : "web");
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';

    final Map<String, String> data = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "cancel_trip_driver_or_customer_admin",
      "driver_uuid": driverUuid,
      "trip_uuid": tripUuid,
      "comment": comment,
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.cancelTrip),
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
        return "Failed to cancel trip: ${response.statusCode}";
      }
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

}
