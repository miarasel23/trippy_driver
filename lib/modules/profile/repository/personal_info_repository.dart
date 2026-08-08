import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_service.dart';
import '../../splash/model/current_user_model.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/app_urls.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class PersonalInfoRepository {
  Future<List<dynamic>?> getDriverDocumentList() async {
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
      "action_when": "driver_document_list",
      "driver_uuid": uuid,
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.driverDocumentList),
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
          return decodedResponse['data'] as List<dynamic>? ?? [];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProfileName({required String fullName}) async {
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
    final userActiveStatus = UserDataStore.userData?.data?.user?.isActive ?? 'ACTIVE';

    final Map<String, String> body = {
      "platform": platform,
      "language_code": languageCode,
      "action_when": "driver_profile_edit",
      "uuid": uuid,
      "is_active": userActiveStatus,
      "full_name": fullName,
    };

    try {
      final response = await ApiService().post(
        Uri.parse(AppUrls.driverProfileUpdate),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final getUri = Uri.parse(AppUrls.getCurrentDriverUser).replace(
          queryParameters: {
            "platform": platform,
            "language_code": languageCode,
            "action_when": "admin_login",
          },
        );

        final getResponse = await ApiService().get(
          getUri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          showSnackBarOnError: false,
        );

        if (getResponse.statusCode == 200) {
          final jsonData = jsonDecode(getResponse.body);
          final currentUser = CurrentUserModel.fromJson(jsonData);
          await UserDataStore.saveUserData(currentUser);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadDriverDocument({
    required File imageFile,
    required String documentType,
    required String documentNumber,
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
        Uri.parse(AppUrls.driverDocumentUpload),
      );

      request.fields.addAll({
        "platform": platform,
        "language_code": languageCode,
        "action_when": "driver_document_upload",
        "driver_uuid": uuid,
        "status": "PROGRESS",
      });

      String fileFieldName = '';
      if (documentType == 'NID_FRONT_COPY') {
        fileFieldName = 'nid_front_side_copy';
        request.fields['nid_number'] = documentNumber;
      } else if (documentType == 'NID_BACK_COPY') {
        fileFieldName = 'nid_back_side_copy';
        request.fields['nid_number'] = documentNumber;
      } else if (documentType == 'LICENSE_FONT_COPY' || documentType == 'LICENSE_FRONT_COPY') {
        fileFieldName = 'license_front_copy';
        request.fields['license_number'] = documentNumber;
      } else if (documentType == 'LICENSE_BACK_COPY') {
        fileFieldName = 'license_back_copy';
        request.fields['license_number'] = documentNumber;
      } else {
        fileFieldName = documentType.toLowerCase();
        request.fields['license_number'] = documentNumber;
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

  Future<bool> uploadAllDriverDocuments({
    required File nidFront,
    required File nidBack,
    required String nidNumber,
    required File licenseFront,
    required File licenseBack,
    required String licenseNumber,
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
        Uri.parse(AppUrls.driverDocumentUpload),
      );

      request.fields.addAll({
        "platform": platform,
        "language_code": languageCode,
        "action_when": "driver_document_upload",
        "driver_uuid": uuid,
        "status": "PROGRESS",
        "nid_number": nidNumber,
        "license_number": licenseNumber,
      });

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add NID Front
      request.files.add(
        await http.MultipartFile.fromPath(
          'nid_front_side_copy',
          nidFront.path,
          contentType: MediaType('image', path.extension(nidFront.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add NID Back
      request.files.add(
        await http.MultipartFile.fromPath(
          'nid_back_side_copy',
          nidBack.path,
          contentType: MediaType('image', path.extension(nidBack.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add License Front
      request.files.add(
        await http.MultipartFile.fromPath(
          'license_front_copy',
          licenseFront.path,
          contentType: MediaType('image', path.extension(licenseFront.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add License Back
      request.files.add(
        await http.MultipartFile.fromPath(
          'license_back_copy',
          licenseBack.path,
          contentType: MediaType('image', path.extension(licenseBack.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
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
