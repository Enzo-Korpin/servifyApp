import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/core/network/socket_client.dart';
import 'package:frontend/models/chat_message_model.dart';
import 'package:frontend/models/chat_user_model.dart';
import 'package:frontend/models/current_user_model.dart';
import 'package:frontend/services/chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  StreamSubscription<ChatMessageModel>? _newMessageSub;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<String>? _errorSub;

  CurrentUserModel? _currentUser;
  ChatUserModel? _selectedUser;
  List<ChatUserModel> _users = [];
  List<ChatMessageModel> _messages = [];

  String? _nextCursor;
  String? _joinedChatId;
  bool _loadingUsers = true;
  bool _loadingMessages = false;
  bool _sending = false;
  bool _socketConnected = false;
  String? _errorMessage;
  File? _selectedImageFile;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

Future<void> _initializeChat() async {
  setState(() {
    _loadingUsers = true;
    _errorMessage = null;
  });

  try {
    _currentUser = await _chatService.getCurrentUser();

    _newMessageSub = SocketClient.instance.newMessages.listen(_handleIncomingMessage);

    _connectionSub = SocketClient.instance.connectionStatus.listen((connected) {
      if (!mounted) return;
      setState(() => _socketConnected = connected);
    });

    _errorSub = SocketClient.instance.errors.listen((message) {
      if (!mounted) return;
      setState(() => _errorMessage = message);
    });

    _socketConnected = SocketClient.instance.isConnected;

    _users = await _chatService.getChatUsers();
  } catch (error) {
    _errorMessage = error.toString();
  } finally {
    if (mounted) {
      setState(() => _loadingUsers = false);
    }
  }
}

  Future<void> _refreshUsers() async {
    setState(() => _loadingUsers = true);

    try {
      _users = await _chatService.getChatUsers();

      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _openConversation(ChatUserModel user) async {

    if (_joinedChatId != null) {
      SocketClient.instance.leaveChat(_joinedChatId!);
    }

    setState(() {
      _selectedUser = user;
      _messages = [];
      _nextCursor = null;
      _joinedChatId = null;
      _loadingMessages = true;
      _errorMessage = null;
    });

    try {
      final result = await _chatService.getMessages(userId: user.id);

      _messages = result.messages;
      _nextCursor = result.nextCursor;

      final chatId = _firstChatId(_messages);
      if (chatId != null) {
        _joinedChatId = chatId;
        SocketClient.instance.joinChat(chatId);
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() => _loadingMessages = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    final selectedUser = _selectedUser;
    final nextCursor = _nextCursor;

    if (selectedUser == null || nextCursor == null || _loadingMessages) return;

    setState(() => _loadingMessages = true);

    try {
      final result = await _chatService.getMessages(
        userId: selectedUser.id,
        before: nextCursor,
      );

      _messages = [...result.messages, ..._messages];
      _nextCursor = result.nextCursor;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _pickingImage = true);

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) {
        setState(() => _pickingImage = false);
        return;
      }

      setState(() => _selectedImageFile = File(pickedFile.path));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $error'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<String?> _fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (error) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: $error')),
      );
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final selectedUser = _selectedUser;
    final text = _messageController.text.trim();
    final imageFile = _selectedImageFile;
    final currentUserId = _currentUser?.id ?? "unknown";

    if (selectedUser == null || (text.isEmpty && imageFile == null) || _sending) return;

    _messageController.clear();
    final tempImageFile = imageFile;
    setState(() {
      _sending = true;
      _errorMessage = null;
      _selectedImageFile = null;
    });

    try {
      String? base64Image;
      if (tempImageFile != null) {
        base64Image = await _fileToBase64(tempImageFile);
      }

      if (!SocketClient.instance.isConnected) {
        await SocketClient.instance.connect();
      }

      if (SocketClient.instance.isConnected && base64Image == null) {
        // Send text-only via socket
        SocketClient.instance.sendMessage(
          receiverId: selectedUser.id,
          text: text,
        );
      } else if (SocketClient.instance.isConnected && base64Image != null) {
        // Send with image via socket
        SocketClient.instance.sendMessage(
          receiverId: selectedUser.id,
          text: text.isNotEmpty ? text : null,
          image: base64Image,
        );
      } else {
        // Fallback to REST API
        final message = await _chatService.sendMessageOverRest(
          receiverId: selectedUser.id,
          text: text,
          image: base64Image,
        );
        _upsertMessage(message);
      }
    } catch (_) {
      try {
        String? base64Image;
        if (tempImageFile != null) {
          base64Image = await _fileToBase64(tempImageFile);
        }

        final message = await _chatService.sendMessageOverRest(
          receiverId: selectedUser.id,
          text: text,
          image: base64Image,
        );
        _upsertMessage(message);
      } catch (error) {
        _errorMessage = error.toString();
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  void _handleIncomingMessage(ChatMessageModel message) {
    final selectedUser = _selectedUser;
    final currentUser = _currentUser;

    if (currentUser == null) return;

    final belongsToOpenConversation = selectedUser != null &&
        ((message.senderId == currentUser.id && message.receiverId == selectedUser.id) ||
            (message.senderId == selectedUser.id && message.receiverId == currentUser.id));

    if (message.chatId.isNotEmpty && _joinedChatId == null && belongsToOpenConversation) {
      _joinedChatId = message.chatId;
      SocketClient.instance.joinChat(message.chatId);
    }

    if (!belongsToOpenConversation) {
      _refreshUsers();
      return;
    }

    _upsertMessage(message);
    _scrollToBottom();
  }

  void _upsertMessage(ChatMessageModel message) {
    if (!mounted) return;

    setState(() {
      final existingIndex = _messages.indexWhere((item) => item.id == message.id);

      if (existingIndex >= 0) {
        _messages[existingIndex] = message;
      } else {
        _messages.add(message);
      }

      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }

  String? _firstChatId(List<ChatMessageModel> messages) {
    for (final message in messages) {
      if (message.chatId.trim().isNotEmpty) return message.chatId;
    }

    return null;
  }

  void _goBackToUsers() {
    if (_joinedChatId != null) {
      SocketClient.instance.leaveChat(_joinedChatId!);
    }

    setState(() {
      _selectedUser = null;
      _messages = [];
      _joinedChatId = null;
      _nextCursor = null;
    });

    _refreshUsers();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    if (_joinedChatId != null) {
      SocketClient.instance.leaveChat(_joinedChatId!);
    }

    _newMessageSub?.cancel();
    _connectionSub?.cancel();
    _errorSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: _selectedUser == null ? _buildUsersList() : _buildConversation(),
    );
  }

  Widget _buildUsersList() {
    return Column(
      children: [
        _buildHeader(
          title: 'Messages',
          subtitle: '',
          showBack: false,
          onRefresh: _refreshUsers,
        ),
        if (_errorMessage != null) _buildErrorBanner(),
        Expanded(
          child: _loadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No conversations yet',
                      subtitle: 'A chat appears here after a service request creates a conversation.',
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshUsers,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return _buildUserTile(user);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildConversation() {
    final user = _selectedUser!;

    return Column(
      children: [
        _buildHeader(
          title: user.fullName,
          subtitle: '',
          showBack: true,
          onBack: _goBackToUsers,
        ),
        if (_errorMessage != null) _buildErrorBanner(),
        Expanded(
          child: _loadingMessages && _messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No messages yet',
                      subtitle: 'Send the first message. It will be saved in MongoDB and emitted through Socket.IO.',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _messages.length + (_nextCursor != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_nextCursor != null && index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextButton(
                              onPressed: _loadOlderMessages,
                              child: _loadingMessages
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Load older messages'),
                            ),
                          );
                        }

                        final messageIndex = _nextCursor != null ? index - 1 : index;
                        return _buildMessageBubble(_messages[messageIndex]);
                      },
                    ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildHeader({
    required String title,
    required String subtitle,
    required bool showBack,
    VoidCallback? onBack,
    VoidCallback? onRefresh,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: const Color(0xFF1E293B),
            ),
          CircleAvatar(
            backgroundColor: const Color(0xFFDBEAFE),
            child: Icon(
              showBack ? Icons.person_outline : Icons.chat_outlined,
              color: const Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _socketConnected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              color: const Color(0xFF1E40AF),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(
          color: Color(0xFFBE123C),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUserTile(ChatUserModel user) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openConversation(user),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user.image != null && user.image!.isNotEmpty
                    ? NetworkImage(user.image!)
                    : null,
                backgroundColor: const Color(0xFFDBEAFE),
                child: user.image == null || user.image!.isEmpty
                    ? Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.currentRole ?? user.role ?? 'Servify user',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isMine = message.senderId == _currentUser?.id;
    final text = message.text?.trim();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF1E40AF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: text == null || text.isEmpty ? 0 : 8),
                child: GestureDetector(
                  onTap: () => _showImageFullscreen(message.imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(message.imageUrl!),
                  ),
                ),
              ),
            if (text != null && text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  color: isMine ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImageFullscreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black.withOpacity(0.9),
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: Image.network(imageUrl),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    if (_selectedUser == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImageFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImageFile!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImageFile = null),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  onPressed: _pickingImage || _sending ? null : _pickImage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                  ),
                  child: _pickingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  onPressed: _sending ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

