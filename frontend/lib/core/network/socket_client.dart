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
      print("ERROR: CookieJar is null!");
      return null;
    }

    final baseUri = Uri.parse(DioClient.dio.options.baseUrl);
    final List<Cookie> cookies = await cookieJar.loadForRequest(baseUri);

    print("DEBUG _loadTokenFromCookieJar: Found ${cookies.length} cookies");
    for (final cookie in cookies) {
      print("DEBUG CookieJar contains: ${cookie.name}=${cookie.value.substring(0, 30)}...");
    }

    for (final cookie in cookies) {
      if (cookie.name == 'token' && cookie.value.trim().isNotEmpty) {
        final token = cookie.value;
        print("DEBUG: Using token: ${token.substring(0, 50)}...");
        
        // Decode to verify which user this token belongs to
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final decodedPayload = utf8.decode(base64Url.decode(parts[1] + '=='));
            print("DEBUG: Token payload: $decodedPayload");
          }
        } catch (e) {
          print("DEBUG: Could not decode token: $e");
        }
        
        return token;
      }
    }

    print("ERROR: No valid token cookie found in jar!");
    return null;
  }

  Future<void> connect() async {
    if (isConnected) {
      print("DEBUG: Socket already connected, skipping");
      return;
    }
    if (_connecting != null) {
      print("DEBUG: Socket already connecting, awaiting...");
      return _connecting!;
    }

    final completer = Completer<void>();
    _connecting = completer.future;

    final baseUrl = DioClient.dio.options.baseUrl.replaceFirst(RegExp(r'/$'), '');
    
    print("DEBUG Socket.connect: Loading token from CookieJar...");
    final token = await _loadTokenFromCookieJar();
    print("DEBUG Socket.connect: Token loaded: ${token != null ? '${token.substring(0, 20)}...' : 'NULL'}");

    if (token == null) {
      print("ERROR: No token found in CookieJar! Cannot connect socket.");
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

    print("DEBUG Socket.connect: Creating new socket instance...");
    final socket = IO.io(baseUrl, options);
    _socket = socket;

    socket.on('connect', (_) {
      print("DEBUG Socket: Connected successfully");
      _connectionController.add(true);
      if (!completer.isCompleted) completer.complete();
    });

    socket.on('disconnect', (_) {
      print("DEBUG Socket: Disconnected");
      _connectionController.add(false);
    });

    socket.on('connect_error', (error) {
      print("DEBUG Socket: Connection error: $error");
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

    print("DEBUG Socket.connect: Calling socket.connect()...");
    socket.connect();

    await completer.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        print("WARNING: Socket connection timed out after 4 seconds");
      },
    );

    _connecting = null;
    print("DEBUG Socket.connect: Connect sequence complete");
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
    
    print("DEBUG SocketClient.sendMessage emitting: $payload");

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
    print("DEBUG Socket.disconnect: Starting cleanup...");
    
    if (_socket != null) {
      print("DEBUG Socket.disconnect: Disconnecting socket");
      _socket?.disconnect();
      _socket?.dispose();
    }
    
    _socket = null;
    _connecting = null;
    
    // Clear all event listeners by resetting streams
    // This ensures no old handlers persist
    _connectionController.add(false);
    
    print("DEBUG Socket.disconnect: Cleanup complete, socket is null");
  }
}
