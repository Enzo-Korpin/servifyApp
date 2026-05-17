import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/models/chat_message_model.dart';
import 'package:frontend/models/chat_user_model.dart';
import 'package:frontend/models/current_user_model.dart';

class ChatMessagesPageResult {
  final List<ChatMessageModel> messages;
  final String? nextCursor;

  const ChatMessagesPageResult({
    required this.messages,
    required this.nextCursor,
  });
}

class ChatService {
  Future<CurrentUserModel> getCurrentUser() async {
    final response = await DioClient.dio.get('/api/auth/check-auth');
    final payload = response.data;
    final data = _unwrapData(payload);

    if (data is! Map) {
      throw Exception('Invalid current user response');
    }

    return CurrentUserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ChatUserModel>> getChatUsers() async {
    final response = await DioClient.dio.get('/api/message/users');
    final payload = response.data;
    final data = _unwrapData(payload);

    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((item) => ChatUserModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ChatMessagesPageResult> getMessages({
    required String userId,
    String? before,
    int limit = 10,
  }) async {
    final response = await DioClient.dio.get(
      '/api/message/$userId',
      queryParameters: {
        'limit': limit,
        if (before != null && before.trim().isNotEmpty) 'before': before,
      },
    );

    final payload = response.data;
    final data = _unwrapData(payload);

    if (data is List) {
      return ChatMessagesPageResult(
        messages: data
            .whereType<Map>()
            .map((item) => ChatMessageModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        nextCursor: null,
      );
    }

    if (data is Map) {
      final messagesData = data['messages'];
      final messages = messagesData is List
          ? messagesData
              .whereType<Map>()
              .map((item) => ChatMessageModel.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : <ChatMessageModel>[];

      return ChatMessagesPageResult(
        messages: messages,
        nextCursor: data['nextCursor']?.toString(),
      );
    }

    return const ChatMessagesPageResult(messages: [], nextCursor: null);
  }

  Future<ChatMessageModel> sendMessageOverRest({
    required String receiverId,
    String text = '',
    String? image,
  }) async {
    final response = await DioClient.dio.post(
      '/api/message/send/$receiverId',
      data: {
        if (text.trim().isNotEmpty) 'text': text.trim(),
        if (image != null && image.trim().isNotEmpty) 'image': image,
      },
    );

    final data = _unwrapData(response.data);

    if (data is! Map) {
      throw Exception('Invalid send message response');
    }

    return ChatMessageModel.fromJson(Map<String, dynamic>.from(data));
  }

  dynamic _unwrapData(dynamic payload) {
    if (payload is Map && payload.containsKey('data')) {
      return payload['data'];
    }

    return payload;
  }
}
