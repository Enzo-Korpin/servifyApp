import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../models/service_request_model.dart';
import '../models/current_user_model.dart';

class PaginatedServiceRequestsResponse {
  final List<ServiceRequestModel> docs;
  final String? nextCursor;

  PaginatedServiceRequestsResponse({
    required this.docs,
    required this.nextCursor,
  });
}

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

  Future<PaginatedServiceRequestsResponse> getWorkerRequests({
    required String status,
    String? after,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/api/service-requests/worker",
        queryParameters: {
          "status": status,
          if (after != null && after.trim().isNotEmpty) "after": after.trim(),
        },
      );

      final data = response.data["data"] as Map<String, dynamic>? ?? {};
      final docsJson = (data["docs"] as List?) ?? const [];

      final rawCursor = data["nextCursor"]?.toString();
      final nextCursor =
          (rawCursor == null || rawCursor.isEmpty) ? null : rawCursor;

      final docs = docsJson
          .map((e) => ServiceRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return PaginatedServiceRequestsResponse(
        docs: docs,
        nextCursor: nextCursor,
      );
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
      final message = data["message"];
      if (message != null) return message.toString();

      final error = data["error"];

      if (error is String && error.trim().isNotEmpty) {
        return error;
      }

      if (error is Map<String, dynamic>) {
        final errorMessage = error["message"];
        final details = error["details"];

        if (errorMessage != null && details != null) {
          return "$errorMessage - $details";
        }

        if (errorMessage != null) {
          return errorMessage.toString();
        }
      }
    }

    return e.message ?? "Request failed";
  }
}