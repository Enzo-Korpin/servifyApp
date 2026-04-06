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

  Future<PaginatedRequestsResponse> getCanceledRequests({
    String? afterRejected,
    String? afterCancelled,
    int? limit,
  }) async {
    final futures = await Future.wait([
      getCustomerRequests(
        status: 'rejected',
        after: afterRejected,
        limit: limit,
      ),
      getCustomerRequests(
        status: 'cancelled',
        after: afterCancelled,
        limit: limit,
      ),
    ]);

    final rejectedResponse = futures[0];
    final cancelledResponse = futures[1];

    final merged = [
      ...rejectedResponse.docs,
      ...cancelledResponse.docs,
    ];

    merged.sort((a, b) {
      final byDate = b.createdAt.compareTo(a.createdAt);
      if (byDate != 0) return byDate;
      return b.id.compareTo(a.id);
    });

    return PaginatedRequestsResponse(
      docs: merged,
      nextCursor: null,
    );
  }
}