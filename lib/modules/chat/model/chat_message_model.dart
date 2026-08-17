class ChatMessageModel {
  final String uuid;
  final String senderUuid;
  final String message;
  final String? fileUrl;
  final String? fileType;
  final String createdAt;
  final String senderType;
  final bool isRead;
  final String status;

  ChatMessageModel({
    required this.uuid,
    required this.senderUuid,
    required this.message,
    this.fileUrl,
    this.fileType,
    required this.createdAt,
    required this.senderType,
    this.isRead = false,
    this.status = 'ACTIVE',
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final rawFile = json['file_url'] ?? json['file'];
    final String? fileStr = (rawFile != null && rawFile.toString().isNotEmpty) ? rawFile.toString() : null;

    return ChatMessageModel(
      uuid: json['uuid'] ?? '',
      senderUuid: json['sender_uuid'] ?? '',
      message: json['message'] ?? '',
      fileUrl: fileStr,
      fileType: json['file_type'],
      createdAt: json['created_at'] ?? '',
      senderType: json['sender_type'] ?? '',
      isRead: json['is_read'] ?? false,
      status: json['status'] ?? 'ACTIVE',
    );
  }
}

