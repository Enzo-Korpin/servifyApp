import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../models/request_model.dart';
import '../models/paginated_requests_response.dart';

class RequestService {
  Future<PaginatedRequestsResponse> getCustomerRequests({
    String? status,
    String? after,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{
      if (limit != null) 'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (after != null && after.isNotEmpty) 'after': after,
    };

    final response = await DioClient.dio.get(
      '/api/service-requests/customer',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    final docsJson = (data['docs'] as List?) ?? [];

    return PaginatedRequestsResponse(
      docs: docsJson
          .map((e) => RequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: data['nextCursor']?.toString(),
    );
  }

  Future<void> submitFeedback({
  required String requestId,
  required int rate,
  String? comment,
}) async {
  await DioClient.dio.post(
    '/api/feedback/$requestId',
    data: {
      'rate': rate,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    },
  );
}

  Future<RequestModel> cancelServiceRequest(
    String requestId, {
    String? cancelReason,
  }) async {
    final body = <String, dynamic>{
      if (cancelReason != null && cancelReason.trim().isNotEmpty)
        'cancelReason': cancelReason.trim(),
    };

    final response = await DioClient.dio.put(
      '/api/service-requests/$requestId/cancel',
      data: body,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return RequestModel.fromJson(data);
  }
}