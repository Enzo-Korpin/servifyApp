import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/models/chat_message_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketClient {
  SocketClient._();

  static final SocketClient instance = SocketClient._();

  IO.Socket? _socket;
  Future<void>? _connecting;

  final StreamController<ChatMessageModel> _newMessagesController =
      StreamController<ChatMessageModel>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<ChatMessageModel> get newMessages => _newMessagesController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  Stream<String> get errors => _errorController.stream;

  bool get isConnected => _socket?.connected == true;

  Future<String?> _loadTokenFromCookieJar() async {
    final cookieJar = DioClient.cookieJar;
    if (cookieJar == null) {

      return null;
    }

    final baseUri = Uri.parse(DioClient.dio.options.baseUrl);
    final List<Cookie> cookies = await cookieJar.loadForRequest(baseUri);

    for (final cookie in cookies) {

    }

    for (final cookie in cookies) {
      if (cookie.name == 'token' && cookie.value.trim().isNotEmpty) {
        final token = cookie.value;

        // Decode to verify which user this token belongs to
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final decodedPayload = utf8.decode(base64Url.decode(parts[1] + '=='));

          }
        } catch (e) {

        }
        
        return token;
      }
    }

    return null;
  }

  Future<void> connect() async {
    if (isConnected) {

      return;
    }
    if (_connecting != null) {

      return _connecting!;
    }

    final completer = Completer<void>();
    _connecting = completer.future;

    final baseUrl = DioClient.dio.options.baseUrl.replaceFirst(RegExp(r'/$'), '');

    final token = await _loadTokenFromCookieJar();

    if (token == null) {

      _connecting = null;
      if (!completer.isCompleted) {
        completer.completeError("No token available");
      }
      return;
    }

    // final extraHeaders = <String, String>{};
    final options = IO.OptionBuilder()
    .setTransports(['websocket'])
    .enableForceNew()
    .disableAutoConnect()
    .setAuth({'token': token})
    .setExtraHeaders({
      'Authorization': 'Bearer $token',
    })
    .enableReconnection()
    .setReconnectionAttempts(3)
    .setReconnectionDelay(1000)
    .build();

    // extraHeaders['Cookie'] = 'token=$token';
    // extraHeaders['Authorization'] = 'Bearer $token';
    // options['auth'] = {'token': token};
    // options['extraHeaders'] = extraHeaders;

    final socket = IO.io(baseUrl, options);
    _socket = socket;

    socket.on('connect', (_) {

      _connectionController.add(true);
      if (!completer.isCompleted) completer.complete();
    });

    socket.on('disconnect', (_) {

      _connectionController.add(false);
    });

    socket.on('connect_error', (error) {

      _connectionController.add(false);
      _errorController.add(error?.toString() ?? 'Socket connection failed');
      if (!completer.isCompleted) completer.complete();
    });

    socket.on('new_message', (payload) {
      final data = _extractData(payload);
      if (data == null) return;

      try {
        _newMessagesController.add(ChatMessageModel.fromJson(data));
      } catch (error) {
        _errorController.add('Failed to parse incoming message: $error');
      }
    });

    socket.on('message_error', (payload) {
      _errorController.add(_extractErrorMessage(payload));
    });

    socket.on('chat_error', (payload) {
      _errorController.add(_extractErrorMessage(payload));
    });

    socket.connect();

    await completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () {

      },
    );

    _connecting = null;

  }

  void joinChat(String chatId) {
    if (chatId.trim().isEmpty || !isConnected) return;
    _socket?.emit('join_chat', {'chatId': chatId});
  }

  void leaveChat(String chatId) {
    if (chatId.trim().isEmpty || !isConnected) return;
    _socket?.emit('leave_chat', {'chatId': chatId});
  }

  void sendMessage({
    required String receiverId,
    String? text,
    String? image,
  }) {
    final cleanText = text?.trim();
    if ((cleanText == null || cleanText.isEmpty) &&
        (image == null || image.trim().isEmpty)) {
      return;
    }

    if (!isConnected) {
      throw StateError('Socket is not connected');
    }

    final payload = {
      'receiverId': receiverId,
      if (cleanText != null && cleanText.isNotEmpty) 'text': cleanText,
      if (image != null && image.trim().isNotEmpty) 'image': image,
    };

    _socket?.emit('send_message', payload);
  }

  void startTyping(String chatId) {
    if (chatId.trim().isEmpty || !isConnected) return;
    _socket?.emit('typing_start', {'chatId': chatId});
  }

  void stopTyping(String chatId) {
    if (chatId.trim().isEmpty || !isConnected) return;
    _socket?.emit('typing_stop', {'chatId': chatId});
  }

  Map<String, dynamic>? _extractData(dynamic payload) {
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final data = map['data'];

      if (data is Map) return Map<String, dynamic>.from(data);
      return map;
    }

    return null;
  }



  String _extractErrorMessage(dynamic payload) {
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final error = map['error'];

      if (error is Map && error['message'] != null) {
        return error['message'].toString();
      }

      if (map['message'] != null) return map['message'].toString();
    }

    return 'Socket error';
  }

  Future<void> reconnectFresh() async {
  disconnect();

  await Future.delayed(const Duration(milliseconds: 300));

  await connect();
}

  void disconnect() {

    if (_socket != null) {

      _socket?.disconnect();
      _socket?.dispose();
    }
    
    _socket = null;
    _connecting = null;
    
    // Clear all event listeners by resetting streams
    // This ensures no old handlers persist
    _connectionController.add(false);

  }
}

