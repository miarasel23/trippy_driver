import 'dart:convert';
import '../../../../core/network/api_service.dart';
import '../../../../store/app_globals.dart';
import '../../../../utils/app_urls.dart';
import '../../../../store/user_data_store.dart';
import '../model/chat_message_model.dart';

class ChatRepository {
  final ApiService _apiService = ApiService();

  Future<List<ChatMessageModel>> fetchConversations({
    required String driverUuid,
    required String customerUuid,
    String receiverType = 'CUSTOMER',
  }) async {
    final url = Uri.parse('${AppUrls.baseUrl}/v1/live-chat/conversation');
    final payload = <String, String>{
      'platform': AppGlobals.platform,
      'language_code': AppGlobals.countryCode.toLowerCase() == 'bd' ? 'bn' : 'en',
      'action_when': 'live_chat_message_list',
      'sender_type': 'DRIVER',
      'user1_uuid': driverUuid,
      'user1_type': 'DRIVER',
      'user2_type': receiverType,
    };

    if (receiverType == 'CUSTOMER' && customerUuid.isNotEmpty) {
      payload['receiver_type'] = 'CUSTOMER';
      payload['user2_uuid'] = customerUuid;
    }

    final token = await UserDataStore.getAccessToken();

    try {
      final response = await _apiService.multipartPost(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        fields: payload,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['messages'] != null) {
          return (data['data']['messages'] as List)
              .map((e) => ChatMessageModel.fromJson(e))
              .where((m) => m.status.toUpperCase() == 'ACTIVE')
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendMessage({
    required String driverUuid,
    required String customerUuid,
    required String message,
    String receiverType = 'CUSTOMER',
    String? filePath,
  }) async {
    final url = Uri.parse('${AppUrls.baseUrl}/v1/live-chat/send');
    final fields = <String, String>{
      'platform': AppGlobals.platform,
      'language_code': AppGlobals.countryCode.toLowerCase() == 'bd' ? 'bn' : 'en',
      'action_when': 'live_chat_message_send',
      'sender_type': 'DRIVER',
      'sender_uuid': driverUuid,
      'receiver_type': receiverType,
      'message': message,
    };

    if (receiverType == 'CUSTOMER' && customerUuid.isNotEmpty) {
      fields['receiver_uuid'] = customerUuid;
    }

    final token = await UserDataStore.getAccessToken();

    try {
      final response = await _apiService.multipartPost(
        url,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        fields: fields,
        fileField: 'file',
        filePath: filePath,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
