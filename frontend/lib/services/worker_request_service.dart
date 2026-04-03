import 'package:dio/dio.dart';
import '../core/network/dio_client.dart'; // change path if your DioClient is elsewhere
import '../models/service_request_model.dart';
import '../models/current_user_model.dart';

class WorkerRequestService {
  Future<Map<String, int>> getWorkerStats() async {
    try {
      final response =
          await DioClient.dio.get("/api/worker/service-requests/worker-status");

      final data = response.data["data"] as Map<String, dynamic>? ?? {};

      return {
        "pending": (data["pending"] ?? 0) as int,
        "accepted": (data["accepted"] ?? 0) as int,
        "rejected": (data["rejected"] ?? 0) as int,
      };
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<CurrentUserModel> getCurrentUser() async {
    try {
      final response = await DioClient.dio.get("/api/auth/check-auth");
      return CurrentUserModel.fromJson(
        response.data["data"] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<List<ServiceRequestModel>> getWorkerRequests({
    required String status,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/api/service-requests/worker",
        queryParameters: {"status": status},
      );

      final docs = response.data["data"]?["docs"] as List? ?? [];

      return docs
          .map((e) => ServiceRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<ServiceRequestModel> acceptRequest(String requestId) async {
    try {
      final response =
          await DioClient.dio.put("/api/service-requests/$requestId/accept");

      return ServiceRequestModel.fromJson(
        response.data["data"] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<ServiceRequestModel> rejectRequest(
    String requestId, {
    String? rejectReason,
  }) async {
    try {
      final response = await DioClient.dio.put(
        "/api/service-requests/$requestId/reject",
        data: {
          "rejectReason": (rejectReason == null || rejectReason.trim().isEmpty)
              ? null
              : rejectReason.trim(),
        },
      );

      return ServiceRequestModel.fromJson(
        response.data["data"] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final error = data["error"];

      if (error is Map<String, dynamic>) {
        final message = error["message"];
        final details = error["details"];

        if (message != null && details != null) {
          return "$message - $details";
        }
        if (message != null) {
          return message.toString();
        }
      }

      if (error != null) {
        return error.toString();
      }
    }

    return e.message ?? "Request failed";
  }
}