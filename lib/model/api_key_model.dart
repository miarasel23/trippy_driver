class ApiKeyModel {
  final int id;
  final String uuid;
  final String apiUrl;
  final String apiKey;
  final String userAgent;
  final String status;

  const ApiKeyModel({
    required this.id,
    required this.uuid,
    required this.apiUrl,
    required this.apiKey,
    required this.userAgent,
    required this.status,
  });

  bool get isActive => status == 'ACTIVE';

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) {
    return ApiKeyModel(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      apiUrl: json['api_url'] ?? '',
      apiKey: json['api_key'] ?? '',
      userAgent: json['user_agent'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
