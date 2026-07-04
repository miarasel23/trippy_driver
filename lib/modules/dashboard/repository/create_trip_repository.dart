import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/app_urls.dart';
import '../../../../utils/custom_map_body_builder.dart';
import '../model/create_rental_trip_model.dart';
import '../model/trip_status.dart';

class CreateTripRepository {
  Future<Map<String, dynamic>> createRentalTrip(CreateRentalTripRequest request) async {
    try {
      final url = Uri.parse(AppUrls.createRentalTrip);
      
      final Map<String, String> formFields = request.toJson().map((key, value) => MapEntry(key, value.toString()));

      debugPrint("Creating rental trip with form payload: $formFields");

      final token = await UserDataStore.getAccessToken();
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      print("header: $headers");
      print("formFields: $formFields");

      final response = await ApiService().post(
        url,
        headers: headers,
        body: formFields,
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 400) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == false) {
          throw Exception(decoded['message'] ?? "Unknown server error");
        }
        return decoded;
      } else {
        String? errorMessage;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded['message'] != null) {
            errorMessage = decoded['message'];
          }
        } catch (_) {}
        
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error creating rental trip: $e");
      rethrow;
    }
  }

  Future<RentalBidListResponse> fetchBids({
    required String customerUuid,
    required String langCode,
    String? platform,
    String tripStatus = TripStatus.requested,
  }) async {
    int retryCount = 0;
    const int maxRetries = 5;
    
    while (true) {
      try {
        final queryParams = CustomMapBodyBuilder.build(
          actionWhen: 'rental_bid_trip_list_for_customer',
          languageCode: langCode,
          data: {
            'customer_uuid': customerUuid,
            'trip_status': tripStatus,
          },
        ).map((key, value) => MapEntry(key, value.toString()));
        final uri = Uri.parse(AppUrls.rentalBidTripListForCustomer).replace(queryParameters: queryParams);
        final token = await UserDataStore.getAccessToken();
        final headers = {
          'Accept': 'application/json',
          'Connection': 'close',
        };
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        
        final response = await ApiService().get(
          uri,
          headers: headers,
          showSnackBarOnError: false,
        );
        
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['status'] == false) {
            throw Exception(decoded['message'] ?? "Unknown server error");
          }
          return RentalBidListResponse.fromJson(decoded);
        } else {
          throw Exception("Server error: ${response.statusCode}");
        }
      } catch (e) {
        retryCount++;
        final isNetworkError = e is http.ClientException || 
                             e.toString().contains('ClientException') || 
                             e.toString().contains('SocketException') || 
                             e.toString().contains('HttpException') ||
                             e.toString().contains('Connection closed');
        
        if (isNetworkError && retryCount < maxRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> acceptTrip({
    required String customerUuid,
    required String bidUuid,
    required String langCode,
  }) async {
    try {
      final url = Uri.parse(AppUrls.acceptTripForCustomer);
      
      final Map<String, dynamic> bodyData = CustomMapBodyBuilder.build(
        actionWhen: 'accept_trip_for_customer',
        languageCode: langCode,
        data: {
          'customer_uuid': customerUuid,
          'bid_uuid': bidUuid,
        },
      );
      
      final Map<String, String> formFields = bodyData.map((key, value) => MapEntry(key, value.toString()));

      final token = await UserDataStore.getAccessToken();
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await ApiService().post(
        url,
        headers: headers,
        body: formFields,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 400) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == false) {
          throw Exception(decoded['message'] ?? "Unknown server error");
        }
        return decoded;
      } else {
        String? errorMessage;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded['message'] != null) {
            errorMessage = decoded['message'];
          }
        } catch (_) {}
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error accepting trip: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelTrip({
    required String tripUuid,
    required String comment,
    required String langCode,
  }) async {
    try {
      final url = Uri.parse(AppUrls.cancelTripDriverOrCustomerAdmin);
      
      final Map<String, dynamic> bodyData = CustomMapBodyBuilder.build(
        actionWhen: 'cancel_trip_driver_or_customer_admin',
        languageCode: langCode,
        data: {
          'trip_uuid': tripUuid,
          'comment': comment,
        },
      );
      
      final Map<String, String> formFields = bodyData.map((key, value) => MapEntry(key, value.toString()));

      final token = await UserDataStore.getAccessToken();
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await ApiService().post(
        url,
        headers: headers,
        body: formFields,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 400) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == false) {
          throw Exception(decoded['message'] ?? "Unknown server error");
        }
        return decoded;
      } else {
        String? errorMessage;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded['message'] != null) {
            errorMessage = decoded['message'];
          }
        } catch (_) {}
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error cancelling trip: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> giveReview({
    required String tripUuid,
    required String customerUuid,
    required String driverUuid,
    required double rating,
    required String comments,
    required String langCode,
  }) async {
    try {
      final url = Uri.parse(AppUrls.rentalTripGiveReview);
      
      final Map<String, String> formFields = {
        'platform': CustomMapBodyBuilder.getPlatform(),
        'language_code': langCode,
        'action_when': 'give_review',
        'trip_uuid': tripUuid,
        'customer_uuid': customerUuid,
        'driver_uuid': driverUuid,
        'rating': rating.toString(),
        'comments': comments,
        'given_by': 'CUSTOMER',
      };

      final token = await UserDataStore.getAccessToken();
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await ApiService().post(
        url,
        headers: headers,
        body: formFields,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 400) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == false) {
          throw Exception(decoded['message'] ?? "Unknown server error");
        }
        return decoded;
      } else {
        String? errorMessage;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded['message'] != null) {
            errorMessage = decoded['message'];
          }
        } catch (_) {}
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error submitting review: $e");
      rethrow;
    }
  }
}
