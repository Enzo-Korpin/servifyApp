import 'request_model.dart';

class PaginatedRequestsResponse {
  final List<RequestModel> docs;
  final String? nextCursor;

  PaginatedRequestsResponse({
    required this.docs,
    required this.nextCursor,
  });
}