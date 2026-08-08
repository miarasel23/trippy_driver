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

class CarInfoRepository {
  Future<List<dynamic>?> getCarDocumentList() async {
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

  Future<bool> uploadCarDocument({
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
      if (documentType == 'VEHICLE_REGISTRATION_SMART_CARD_COPY') {
        fileFieldName = 'vehicle_registration_smart_card_copy';
        request.fields['vehicle_registration_number'] = documentNumber;
      } else if (documentType == 'VEHICLE_TAX_FONT_COPY' || documentType == 'VEHICLE_TAX_FRONT_COPY') {
        fileFieldName = 'vehicle_tax_front_copy';
      } else if (documentType == 'VEHICLE_TAX_BACK_COPY') {
        fileFieldName = 'vehicle_tax_back_copy';
      } else if (documentType == 'VEHICLE_FITNESS_CERTIFICATE_FONT_COPY' || documentType == 'VEHICLE_FITNESS_CERTIFICATE_FRONT_COPY') {
        fileFieldName = 'vehicle_fitness_certificate_front_copy';
      } else if (documentType == 'VEHICLE_FITNESS_CERTIFICATE_BACK_COPY') {
        fileFieldName = 'vehicle_fitness_certificate_back_copy';
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

  Future<bool> uploadAllCarDocuments({
    required File smartCardFile,
    required String registrationNumber,
    required File taxFrontFile,
    required File taxBackFile,
    required File fitnessFrontFile,
    required File fitnessBackFile,
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
        "vehicle_registration_number": registrationNumber,
      });

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add smart card
      request.files.add(
        await http.MultipartFile.fromPath(
          'vehicle_registration_smart_card_copy',
          smartCardFile.path,
          contentType: MediaType('image', path.extension(smartCardFile.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add tax front
      request.files.add(
        await http.MultipartFile.fromPath(
          'vehicle_tax_front_copy',
          taxFrontFile.path,
          contentType: MediaType('image', path.extension(taxFrontFile.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add tax back
      request.files.add(
        await http.MultipartFile.fromPath(
          'vehicle_tax_back_copy',
          taxBackFile.path,
          contentType: MediaType('image', path.extension(taxBackFile.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add fitness front
      request.files.add(
        await http.MultipartFile.fromPath(
          'vehicle_fitness_certificate_front_copy',
          fitnessFrontFile.path,
          contentType: MediaType('image', path.extension(fitnessFrontFile.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
        ),
      );

      // Add fitness back
      request.files.add(
        await http.MultipartFile.fromPath(
          'vehicle_fitness_certificate_back_copy',
          fitnessBackFile.path,
          contentType: MediaType('image', path.extension(fitnessBackFile.path).toLowerCase() == '.png' ? 'png' : 'jpeg'),
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
