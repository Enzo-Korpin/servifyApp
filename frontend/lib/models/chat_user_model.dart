class ChatUserModel {
  final String id;
  final String fullName;
  final String? image;
  final String? role;
  final String? currentRole;

  const ChatUserModel({
    required this.id,
    required this.fullName,
    this.image,
    this.role,
    this.currentRole,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? 'Unknown user').toString(),
      image: json['image']?.toString(),
      role: json['role']?.toString(),
      currentRole: json['currentRole']?.toString(),
    );
  }
}
