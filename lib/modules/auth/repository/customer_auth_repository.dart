import 'dart:io';
import 'package:get/get.dart';

import '../../../utils/app_urls.dart';

class AuthRepository {
  final GetConnect _connect = GetConnect();

  Future<Map<String, dynamic>?> sendOtp({
    required String phoneNumber,
    required String languageCode,
  }) async {
    try {
      String platform = "web";
      if (Platform.isAndroid) {
        platform = "android";
      } else if (Platform.isIOS) {
        platform = "ios";
      }

      final body = {
        "platform": platform,
        "language_code": languageCode,
        "action_when": "admin_login",
        "phone_number": phoneNumber,
        "country_code": "BD",
      };

      final response = await _connect.post(AppUrls.sendOtpCustomer, body);

      if (response.statusCode == 200) {
        final json = response.body;

        if (json['status'] == true) {
          return json['result'];
        } else {
          throw Exception(json['message'] ?? "OTP failed");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }
}
