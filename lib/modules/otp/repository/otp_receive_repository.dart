import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import '../../../store/user_data_store.dart';
import '../../../utils/app_urls.dart';
import '../../splash/model/current_user_model.dart';
import '../model/otp_receive_model.dart';

import '../../../store/app_globals.dart';

class OtpReceiveRepository {
  OtpReceiveRepository();

  Future<String?> receivingOtp({
    required String otp,
    required String languageCode,
    required String number,
  }) async {
    final Map<String, dynamic> data = {
      "platform": AppGlobals.platform,
      "language_code": languageCode,
      "action_when": "driver_login",
      "phone_number": number,
      "country_code": AppGlobals.countryCode,
      "otp": otp,
    };

    try {
      final response = await post(
        Uri.parse(AppUrls.verifyOtpCustomer),
        body: data,
      );

      // Parse JSON response body
      try {
        final dynamic jsonData = jsonDecode(response.body);
        if (jsonData is Map<String, dynamic>) {
          // If backend returns status == false (e.g. Invalid OTP)
          if (jsonData['status'] == false) {
            return jsonData['message']?.toString() ??
                jsonData['detail']?.toString() ??
                "Invalid OTP.";
          }

          // If backend returns status == true
          if (jsonData['status'] == true) {
            if (jsonData['data'] != null && jsonData['data'] is Map<String, dynamic>) {
              OtpReceiveModel otpReceiveModel = OtpReceiveModel.fromJson(jsonData);
              if (otpReceiveModel.data?.accessToken != null) {
                await UserDataStore.saveAccessToken(
                  otpReceiveModel.data!.accessToken!,
                );
              }
              if (otpReceiveModel.data?.user?.uuid != null) {
                await UserDataStore.saveUuid(otpReceiveModel.data!.user!.uuid!);
              }

              // Save full user data to UserDataStore
              CurrentUserModel currentUserModel = CurrentUserModel.fromJson(jsonData);
              await UserDataStore.saveUserData(currentUserModel);
            }
            return null;
          }

          // If non-200 and has message or detail
          if (jsonData['message'] != null || jsonData['detail'] != null) {
            return (jsonData['message'] ?? jsonData['detail']).toString();
          }
        }
      } catch (_) {
        // Fall through to status code check
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
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
