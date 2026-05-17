class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      chatId: (json['chatId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      receiverId: (json['receiverId'] ?? '').toString(),
      text: json['text']?.toString(),
      imageUrl: (json['imageURL'] ?? json['imageUrl'])?.toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
