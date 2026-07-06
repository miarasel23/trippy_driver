import 'dart:async';
import 'dart:convert';
import 'dart:io';


import 'package:http/http.dart';
import 'package:path/path.dart';

import '../../../store/user_data_store.dart';
import '../../../utils/app_urls.dart';
import '../../../utils/custom_map_body_builder.dart';
import '../../splash/repository/splash_repository.dart';
import '../../splash/model/current_user_model.dart';
import '../../../store/app_globals.dart';

class EditProfileRepository {
  final SplashRepository repository;

  EditProfileRepository({required this.repository});
  Future<String?> uploadProfilePicture({
    required File imageFile,
    required String languageCode,
  }) async {
    await UserDataStore.getUuid();
    await UserDataStore.getAccessToken();
    try {
      var request = MultipartRequest(
        'POST',
        Uri.parse(AppUrls.driverProfilePictureUpdate),
      );

      request.fields.addAll(
        CustomMapBodyBuilder.build(
          actionWhen: 'driver_profile_picture_upload',
          languageCode: languageCode,
          data: {'driver_uuid': UserDataStore.uuid},
        ).map((key, value) => MapEntry(key, value.toString())),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${UserDataStore.accessToken}',
      });

      final ext = extension(imageFile.path).toLowerCase();

      MediaType mediaType;
      if (ext == '.png') {
        mediaType = MediaType('image', 'png');
      } else if (ext == '.jpg' || ext == '.jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else {
        return "Unsupported file format";
      }

      request.files.add(
        await MultipartFile.fromPath(
          'avatar',
          imageFile.path,
          contentType: mediaType,
        ),
      );
    String platform = "web";
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    }
    final response = await request.send();
    print('response.statusCode: ${response.statusCode}');
    if (response.statusCode == 200) {
     final uri = Uri.parse(AppUrls.getCurrentDriverUser).replace(
          queryParameters: {
            "platform": platform,
            "language_code": languageCode,
            "action_when": "profile_info",
          },
        );

        final responseCurrentData = await get(
          uri,
          headers: {
            'Authorization': 'Bearer ${UserDataStore.accessToken}',
          },
        );

        if (responseCurrentData.statusCode == 200) {
          final jsonData = jsonDecode(responseCurrentData.body);
          CurrentUserModel currentUserModel = CurrentUserModel.fromJson(jsonData);
          await UserDataStore.saveUserData(currentUserModel);
          return null;
        } else {
          return "Failed to sync user info: ${responseCurrentData.statusCode}";
        }    
      }
    } on SocketException {
      return "No Internet connection";
    } on TimeoutException {
      return "Request timeout";
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

  Future<String?> editingInfo({
    required String languageCode,
    required String phone_number,
    required String fullName,
    required String email,
    String? nidNumber,
    bool? isNotificationEnabled,
    String? deviceTokenForNotification,
    String? isActive,
  }) async {
    await UserDataStore.getUuid();
    await UserDataStore.getAccessToken();
    String platform = "web";
        if (Platform.isAndroid) {
          platform = "android";
        } else if (Platform.isIOS) {
          platform = "ios";
        }
    final Map<String, dynamic> data = CustomMapBodyBuilder.build(
      actionWhen: "driver_profile_edit",
      languageCode: languageCode,
      data: {
        "phone_number": phone_number,
        "country_code": "BD",
        "platform": platform,
        "uuid": UserDataStore.uuid,
        "full_name": fullName,
        "email": email,
        "nid_number": nidNumber,
        "is_notification_enabled": UserDataStore.userData?.data?.user?.isNotificationEnabled ?? false,
        "device_token_for_notification": deviceTokenForNotification,
        "is_active": isActive ?? UserDataStore.userData?.data?.user?.isActive ?? "ACTIVE",
      },
    );
    try {
      var request = MultipartRequest(
        'POST',
        Uri.parse(AppUrls.driverProfileUpdate),
      );
      request.fields.addAll(
        Map.fromEntries(
          data.entries
              .where((entry) => entry.value != null)
              .map((entry) => MapEntry(entry.key, entry.value.toString())),
        ),
      );
      request.headers.addAll({
        'Authorization': 'Bearer ${UserDataStore.accessToken}',
      });
      final streamedResponse = await request.send();
      final response = await Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
       

        final uri = Uri.parse(AppUrls.getCurrentDriverUser).replace(
          queryParameters: {
            "platform": platform,
            "language_code": languageCode,
            "action_when": "profile_info",
          },
        );

        final responseCurrentData = await get(
          uri,
          headers: {
            'Authorization': 'Bearer ${UserDataStore.accessToken}',
          },
        );

        if (responseCurrentData.statusCode == 200) {
          final jsonData = jsonDecode(responseCurrentData.body);
          CurrentUserModel currentUserModel = CurrentUserModel.fromJson(jsonData);
          await UserDataStore.saveUserData(currentUserModel);
          return null;
        } else {
          return "Failed to sync user info: ${responseCurrentData.statusCode}";
        }
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
