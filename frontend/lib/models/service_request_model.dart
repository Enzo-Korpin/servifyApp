class ServiceRequestModel {
  final String id;
  final String customerId;
  final String workerId;
  final String customerName;
  final String? customerImage;
  final String message;
  final String addressText;
  final String status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final String? chatId;
  final String? rejectReason;
  final String? cancelReason;
  final List<double> coordinates;

  ServiceRequestModel({
    required this.id,
    required this.customerId,
    required this.workerId,
    required this.customerName,
    required this.customerImage,
    required this.message,
    required this.addressText,
    required this.status,
    required this.createdAt,
    required this.acceptedAt,
    required this.rejectedAt,
    required this.cancelledAt,
    required this.chatId,
    required this.rejectReason,
    required this.cancelReason,
    required this.coordinates,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    final location = json["location"] as Map<String, dynamic>?;

    return ServiceRequestModel(
      id: json["_id"]?.toString() ?? "",
      customerId: json["customerId"]?.toString() ?? "",
      workerId: json["workerId"]?.toString() ?? "",
      customerName: json["customerName"]?.toString() ?? "Customer",
      customerImage: json["customerImage"]?.toString(),
      message: json["message"]?.toString() ?? "",
      addressText: json["addressText"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "pending",
      createdAt: DateTime.parse(json["createdAt"]),
      acceptedAt:
          json["acceptedAt"] != null ? DateTime.parse(json["acceptedAt"]) : null,
      rejectedAt:
          json["rejectedAt"] != null ? DateTime.parse(json["rejectedAt"]) : null,
      cancelledAt:
          json["cancelledAt"] != null ? DateTime.parse(json["cancelledAt"]) : null,
      chatId: json["chatId"]?.toString(),
      rejectReason: json["rejectReason"]?.toString(),
      cancelReason: json["cancelReason"]?.toString(),
      coordinates: location != null && location["coordinates"] is List
          ? (location["coordinates"] as List)
              .map((e) => (e as num).toDouble())
              .toList()
          : [],
    );
  }
}