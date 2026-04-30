class RequestModel {
  final String id;
  final String customerId;
  final String workerId;
  final String message;
  final String addressText;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final String? chatId;
  final double? longitude;
  final double? latitude;
  final String? rejectReason;
  final String? cancelReason;
  final bool hasFeedback;

  RequestModel({
    required this.id,
    required this.customerId,
    required this.workerId,
    required this.message,
    required this.addressText,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.cancelledAt,
    this.chatId,
    this.longitude,
    this.latitude,
    this.rejectReason,
    this.cancelReason,
    this.hasFeedback = false,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final coordinates = location?['coordinates'] as List?;

    return RequestModel(
      id: json['_id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      workerId: json['workerId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      addressText: json['addressText']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      acceptedAt:
          json['acceptedAt'] != null ? DateTime.tryParse(json['acceptedAt']) : null,
      rejectedAt:
          json['rejectedAt'] != null ? DateTime.tryParse(json['rejectedAt']) : null,
      cancelledAt:
          json['cancelledAt'] != null ? DateTime.tryParse(json['cancelledAt']) : null,
      chatId: json['chatId']?.toString(),
      longitude: coordinates != null && coordinates.length > 1
          ? (coordinates[0] as num).toDouble()
          : null,
      latitude: coordinates != null && coordinates.length > 1
          ? (coordinates[1] as num).toDouble()
          : null,
      rejectReason: json['rejectReason']?.toString(),
      cancelReason: json['cancelReason']?.toString(),
      hasFeedback: json['hasFeedback'] == true,
    );
  }

  RequestModel copyWith({
    bool? hasFeedback,
  }) {
    return RequestModel(
      id: id,
      customerId: customerId,
      workerId: workerId,
      message: message,
      addressText: addressText,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      acceptedAt: acceptedAt,
      rejectedAt: rejectedAt,
      cancelledAt: cancelledAt,
      chatId: chatId,
      longitude: longitude,
      latitude: latitude,
      rejectReason: rejectReason,
      cancelReason: cancelReason,
      hasFeedback: hasFeedback ?? this.hasFeedback,
    );
  }
}