class PolicyModel {
  final bool status;
  final String message;
  final Map<String, List<PolicyItemModel>> data;

  PolicyModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    Map<String, List<PolicyItemModel>> parsedData = {};
    if (json['data'] != null) {
      json['data'].forEach((key, value) {
        if (value is List) {
          parsedData[key] = value.map((e) => PolicyItemModel.fromJson(e)).toList();
        }
      });
    }
    return PolicyModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: parsedData,
    );
  }
}

class PolicyItemModel {
  final int id;
  final String uuid;
  final String type;
  final String content;
  final String status;
  final String countryCode;
  final String createdAt;
  final String updatedAt;

  PolicyItemModel({
    required this.id,
    required this.uuid,
    required this.type,
    required this.content,
    required this.status,
    required this.countryCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PolicyItemModel.fromJson(Map<String, dynamic> json) {
    return PolicyItemModel(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      type: json['type'] ?? '',
      content: json['content'] ?? '',
      status: json['status'] ?? '',
      countryCode: json['country_code'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
