import 'package:dio/dio.dart';
import 'package:frontend/core/network/dio_client.dart';

class FollowService {
  Future<void> followWorker(String workerId) async {
    await DioClient.dio.post(
      '/api/follow/$workerId',
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  Future<void> unfollowWorker(String workerId) async {
    await DioClient.dio.delete(
      '/api/unfollow/$workerId',
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

    Future<bool> isFollowingWorker(String workerId) async {
    final response = await DioClient.dio.get(
        '/api/following/$workerId',
        options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) {
            return status != null && status < 500;
        },
        ),
    );

    if (response.statusCode == 200) {
        return true;
    }

    if (response.statusCode == 404) {
        return false;
    }

    throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Unexpected status code: ${response.statusCode}',
        );
    }

  Future<List<Map<String, dynamic>>> getFollowingWorkers() async {
    final response = await DioClient.dio.get(
      '/api/following',
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final List rawFollowing =
        (response.data["data"]?["following"] ?? []) as List;

    final List<Map<String, dynamic>> result = [];

    for (final item in rawFollowing) {
      final worker = Map<String, dynamic>.from(item as Map);

      final workerId = (worker["_id"] ?? "").toString();
      if (workerId.isEmpty) continue;

      try {
        final profileResponse = await DioClient.dio.get(
          '/api/worker/$workerId',
          options: Options(
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

        final profileData =
            Map<String, dynamic>.from(profileResponse.data["data"] ?? {});
        final user = Map<String, dynamic>.from(profileData["_id"] ?? {});

        final List<String> skills =
            List<String>.from(profileData["skills"] ?? []);

        result.add({
          "workerId": workerId,
          "name": (user["fullName"] ?? worker["fullName"] ?? "").toString(),
          "email": (user["email"] ?? worker["email"] ?? "").toString(),
          "imageUrl": (user["image"] ?? "").toString(),
          "skills": skills,
          "profession": _resolveMainJob(skills),
          "rating": ((profileData["rate"] ?? 0) as num).toDouble(),
          "distance": 0.0,
        });
      } catch (_) {
        result.add({
          "workerId": workerId,
          "name": (worker["fullName"] ?? "").toString(),
          "email": (worker["email"] ?? "").toString(),
          "imageUrl": "",
          "skills": <String>[],
          "profession": "Worker",
          "rating": 0.0,
          "distance": 0.0,
        });
      }
    }

    return result;
  }

  String _resolveMainJob(List<String> skills) {
    final normalized = skills.map((e) => e.toLowerCase().trim()).toList();

    if (normalized.contains('plumbing')) return 'Plumber';
    if (normalized.contains('electricity') || normalized.contains('electrical')) {
      return 'Electrician';
    }
    if (normalized.contains('painting')) return 'Painter';
    if (normalized.contains('cleaning')) return 'Cleaner';
    if (normalized.contains('carpentry')) return 'Carpenter';
    return 'Worker';
  }
}