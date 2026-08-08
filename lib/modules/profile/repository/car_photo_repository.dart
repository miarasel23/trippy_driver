import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_service.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/app_urls.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class CarPhotoRepository {
  Future<Map<String, dynamic>?> getCarPhotoList() async {
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

    final Map<String, String> bodyParams = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "car_photo_list",
      "driver_uuid": uuid,
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.carSetupAndPhotoList),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: bodyParams,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse != null && decodedResponse['status'] == true) {
          return {
            "car_category_info": decodedResponse['car_category_info'],
            "data": decodedResponse['data'] as List<dynamic>? ?? [],
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> getCarCategoryList() async {
    final String? token = UserDataStore.accessToken ?? await UserDataStore.getAccessToken();
    if (token == null) return null;

    String platform = "web";
    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    }

    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('active_language_code') ?? 'en';

    final uri = Uri.parse(AppUrls.listCarCategory).replace(queryParameters: {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "car_category_list",
    });

    try {
      final response = await ApiService().get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse != null && decodedResponse['status'] == true) {
          return decodedResponse['data'] as List<dynamic>? ?? [];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> uploadCarPhoto({
    required File imageFile,
    required String documentType,
    required String carCategoriesUuid,
  }) async {
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

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppUrls.carSetupAndPhotoUpload),
      );

      request.fields.addAll({
        "platform": platform,
        "language_code": languageCode,
        "action_when": "car_photo_upload",
        "driver_uuid": uuid,
        "car_categories_uuid": carCategoriesUuid,
        "status": "PROGRESS",
      });

      String fileFieldName = '';
      final docTypeUpper = documentType.toUpperCase();
      if (docTypeUpper == 'FRONT') {
        fileFieldName = 'front_avatar';
      } else if (docTypeUpper == 'BACK') {
        fileFieldName = 'back_avatar';
      } else if (docTypeUpper == 'LEFT') {
        fileFieldName = 'left_avatar';
      } else if (docTypeUpper == 'RIGHT') {
        fileFieldName = 'right_avatar';
      } else if (docTypeUpper == 'CAR_SET') {
        fileFieldName = 'car_set_avatar';
      } else {
        fileFieldName = documentType.toLowerCase();
      }

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final ext = path.extension(imageFile.path).toLowerCase();
      MediaType mediaType;
      if (ext == '.png') {
        mediaType = MediaType('image', 'png');
      } else {
        mediaType = MediaType('image', 'jpeg');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          fileFieldName,
          imageFile.path,
          contentType: mediaType,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadAllCarPhotos({
    required File frontFile,
    required File backFile,
    required File leftFile,
    required File rightFile,
    required File carSetFile,
    required String carCategoriesUuid,
  }) async {
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

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppUrls.carSetupAndPhotoUpload),
      );

      request.fields.addAll({
        "platform": platform,
        "language_code": languageCode,
        "action_when": "car_photo_upload",
        "driver_uuid": uuid,
        "car_categories_uuid": carCategoriesUuid,
        "status": "PROGRESS",
      });

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add Front
      request.files.add(
        await http.MultipartFile.fromPath(
          'front_avatar',
          frontFile.path,
          contentType: MediaType('image', path.extension(frontFile.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add Back
      request.files.add(
        await http.MultipartFile.fromPath(
          'back_avatar',
          backFile.path,
          contentType: MediaType('image', path.extension(backFile.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add Left
      request.files.add(
        await http.MultipartFile.fromPath(
          'left_avatar',
          leftFile.path,
          contentType: MediaType('image', path.extension(leftFile.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add Right
      request.files.add(
        await http.MultipartFile.fromPath(
          'right_avatar',
          rightFile.path,
          contentType: MediaType('image', path.extension(rightFile.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add Car Set
      request.files.add(
        await http.MultipartFile.fromPath(
          'car_set_avatar',
          carSetFile.path,
          contentType: MediaType('image', path.extension(carSetFile.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
