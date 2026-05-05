import 'package:dio/dio.dart';
import '../models/notification_model.dart';

class NotificationService {
  final Dio dio;

  NotificationService(this.dio);

  Future<List<NotificationModel>> getMyNotifications() async {
    final response = await dio.get("/api/notifications");

    final data = response.data["data"] as List;

    return data
        .map((item) => NotificationModel.fromJson(item))
        .toList();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await dio.patch("/api/notifications/$notificationId/read");
  }

  Future<void> markAllAsRead() async {
    await dio.patch("/api/notifications/read-all");
  }
}