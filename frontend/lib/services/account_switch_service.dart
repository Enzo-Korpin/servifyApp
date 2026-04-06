import 'package:dio/dio.dart';
import 'package:frontend/core/network/dio_client.dart';

class AuthCheckUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String currentRole;
  final String? image;

  AuthCheckUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.currentRole,
    this.image,
  });

  factory AuthCheckUser.fromJson(Map<String, dynamic> json) {
    return AuthCheckUser(
      id: json["_id"]?.toString() ?? "",
      fullName: json["fullName"]?.toString() ?? "",
      email: json["email"]?.toString() ?? "",
      role: json["role"]?.toString() ?? "",
      currentRole: json["currentRole"]?.toString() ?? "",
      image: json["image"]?.toString(),
    );
  }
}

class AccountSwitchService {
  Future<AuthCheckUser> checkAuth() async {
    final response = await DioClient.dio.get("/api/auth/check-auth");

    final data = response.data["data"];
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception("Invalid check-auth response");
    }

    return AuthCheckUser.fromJson(data);
  }

  Future<String> switchRole(String targetRole) async {
    final response = await DioClient.dio.post(
      "/api/worker/switch-role",
      data: {
        "targetRole": targetRole,
      },
    );

    final data = response.data["data"];
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception("Invalid switch-role response");
    }

    return data["currentRole"]?.toString() ?? "";
  }

  String getTargetRole(String currentRole) {
    return currentRole == "worker" ? "customer" : "worker";
  }

  String getButtonText(String currentRole) {
    return currentRole == "worker"
        ? "Switch to Customer Account"
        : "Switch to Worker Account";
  }
}