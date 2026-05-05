class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? requestId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.requestId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json["_id"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      message: json["message"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "",
      requestId: json["requestId"]?.toString(),
      isRead: json["isRead"] == true,
      createdAt: DateTime.tryParse(json["createdAt"]?.toString() ?? "") ??
          DateTime.now(),
    );
  }
}