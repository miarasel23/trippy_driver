import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';

import '../../../utils/app_urls.dart';

class SendOtpRepository {
  SendOtpRepository();

  Future<String?> sendingOtp({
    required String number,
    required String languageCode,
  }) async {
    String platform = "web";
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    }

    final Map<String, dynamic> data = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "customer_login",
      "phone_number": number,
      "country_code": "BD",
    };

    try {
      final response = await post(
        Uri.parse(AppUrls.sendOtpCustomer),
        body: data,
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        return "Server error: ${response.statusCode}";
      }
    } on SocketException {
      return "No Internet connection";
    } on TimeoutException {
      return "Request timeout";
    } catch (e) {
      return "Unexpected error: $e";
    }
  }
}
