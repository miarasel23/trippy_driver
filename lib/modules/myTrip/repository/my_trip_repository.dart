import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';
import '../../../../utils/app_urls.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/custom_map_body_builder.dart';
import '../../dashboard/model/create_rental_trip_model.dart';

class MyTripRepository {
  final ApiService _apiService = ApiService();

  Future<RentalBidListResponse> fetchTrips(String tripStatus, String languageCode) async {
    int retryCount = 0;
    const int maxRetries = 5;
    
    while (true) {
      try {
        String? customerUuid = await UserDataStore.getUuid();
        if (customerUuid == null || customerUuid.isEmpty) {
          customerUuid = UserDataStore.userData?.data?.user?.uuid ?? "";
        }
        
        final platform = CustomMapBodyBuilder.getPlatform();
        
        final uri = Uri.parse("${AppUrls.rentalBidTripListForCustomer}?platform=$platform&language_code=$languageCode&action_when=rental_bid_trip_list_for_customer&customer_uuid=$customerUuid&trip_status=$tripStatus");

        String? token = UserDataStore.accessToken;
        if (token == null || token.isEmpty) {
          token = await UserDataStore.getAccessToken();
        }

        final response = await _apiService.get(uri, headers: {
          "Authorization": "Bearer ${token ?? ""}",
          "Connection": "close"
        }, showSnackBarOnError: false);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonResponse = jsonDecode(response.body);
          return RentalBidListResponse.fromJson(jsonResponse);
        } else {
          throw Exception('Failed to load trips: ${response.statusCode}');
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
}
