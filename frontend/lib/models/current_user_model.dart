class CurrentUserModel {
  final String id;
  final String fullName;
  final String? email;
  final String? image;
  final String? currentRole;

  CurrentUserModel({
    required this.id,
    required this.fullName,
    this.email,
    this.image,
    this.currentRole,
  });

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    return CurrentUserModel(
      id: json["_id"]?.toString() ?? "",
      fullName: json["fullName"]?.toString() ?? "",
      email: json["email"]?.toString(),
      image: json["image"] == null ? null : json["image"].toString(),
      currentRole: json["currentRole"]?.toString(),
    );
  }
}