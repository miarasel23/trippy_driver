import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../utils/app_urls.dart';
import '../model/trip_price_details_model.dart';

import '../../../../store/user_data_store.dart';

class TripPriceDetailsRepository {
  Future<TripPriceDetailsResponse> getTripPriceDetails(TripPriceDetailsRequest request) async {
    try {
      final token = await UserDataStore.getAccessToken();
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.post(
        Uri.parse(AppUrls.tripPriceDetailsCustomer),
        headers: headers,
        body: request.toJson(),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == false) {
          throw Exception(decoded['message'] ?? "Unknown server error");
        }
        return TripPriceDetailsResponse.fromJson(decoded);
      } else {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded['message'] != null) {
            throw Exception(decoded['message']);
          }
        } catch (_) {}
        throw Exception("Failed to load trip price details: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }
}
