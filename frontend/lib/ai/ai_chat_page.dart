import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/ui/app_notify.dart';
import 'package:google_fonts/google_fonts.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  bool _showConversations = false;

  String? _activeConversationId;
  String _activeTitle = "New AI Chat";

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoadingConversations = true);

    try {
      final response = await DioClient.dio.get('/api/ai/conversations');

      final List data = response.data as List;

      setState(() {
        _conversations = data.map<Map<String, dynamic>>((c) {
          return {
            "_id": c["_id"],
            "title": c["title"] ?? "New AI Chat",
            "updatedAt": c["updatedAt"],
          };
        }).toList();
      });

      if (_conversations.isNotEmpty && _activeConversationId == null) {
        await _loadMessages(_conversations.first["_id"]);
      }
    } on DioException catch (e) {
      _showMessage(AppNotify.messageFromError(e, fallback: "We couldn't load your conversations. Please try again."));
    } catch (e) {
      _showMessage(AppNotify.messageFromError(e, fallback: "We couldn't load your conversations. Please try again."));
    } finally {
      if (mounted) setState(() => _isLoadingConversations = false);
    }
  }

  Future<void> _loadMessages(String conversationId) async {
    setState(() {
      _isLoadingMessages = true;
      _showConversations = false;
    });

    try {
      final response = await DioClient.dio.get(
        '/api/ai/conversations/$conversationId/messages',
      );

      final data = response.data;
      final List rawMessages = data["messages"] ?? [];

      setState(() {
        _activeConversationId = data["conversationId"].toString();
        _activeTitle = data["title"] ?? "AI Chat";

        _messages = rawMessages.map<Map<String, dynamic>>((m) {
          return {
            "role": m["role"],
            "content": m["content"],
            "category": m["category"],
            "workerType": m["workerType"],
            "urgency": m["urgency"],
            "canUserFix": m["canUserFix"],
            "steps": List<String>.from(m["steps"] ?? []),
            "safetyNotes": List<String>.from(m["safetyNotes"] ?? []),
          };
        }).toList();
      });

      _scrollToBottom();
    } on DioException catch (e) {
      _showMessage(AppNotify.messageFromError(e, fallback: "We couldn't load these messages. Please try again."));
    } catch (e) {
      _showMessage(AppNotify.messageFromError(e, fallback: "We couldn't load these messages. Please try again."));
    } finally {
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();

    setState(() {
      _isSending = true;
      _messages.add({
        "role": "user",
        "content": text,
      });
    });

    _scrollToBottom();

    try {
      final body = {
        "message": text,
        if (_activeConversationId != null)
          "conversationId": _activeConversationId,
      };

      final response = await DioClient.dio.post(
        '/api/ai/messages',
        data: body,
      );

      final data = response.data;

      setState(() {
        _activeConversationId = data["conversationId"].toString();
        _activeTitle = _activeTitle == "New AI Chat" ? text : _activeTitle;

        _messages.add({
          "role": "assistant",
          "content": data["reply"],
          "category": data["category"],
          "workerType": data["workerType"],
          "urgency": data["urgency"],
          "canUserFix": data["canUserFix"],
          "steps": List<String>.from(data["steps"] ?? []),
          "safetyNotes": List<String>.from(data["safetyNotes"] ?? []),
        });
      });

      await _loadConversations();
      _scrollToBottom();
    } on DioException catch (e) {
      _showMessage(AppNotify.messageFromError(e, fallback: "The assistant couldn't respond. Please try again."));
    } catch (e) {
      _showMessage(AppNotify.messageFromError(e, fallback: "The assistant couldn't respond. Please try again."));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startNewChat() {
    setState(() {
      _activeConversationId = null;
      _activeTitle = "New AI Chat";
      _messages = [];
      _showConversations = false;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    AppNotify.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: SafeArea(
        child: Column(
          children: [
            _topBar(),
            if (_showConversations) _conversationPanel(),
            Expanded(
              child: _isLoadingMessages
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E40AF),
                      ),
                    )
                  : _messages.isEmpty
                      ? _emptyState()
                      : _chatList(),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _activeTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _showConversations = !_showConversations);
            },
            icon: const Icon(
              Icons.history_rounded,
              color: Color(0xFF1E40AF),
            ),
          ),
          IconButton(
            onPressed: _startNewChat,
            icon: const Icon(
              Icons.add_circle_rounded,
              color: Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conversationPanel() {
    return Container(
      height: 190,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: _isLoadingConversations
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
            )
          : _conversations.isEmpty
              ? Center(
                  child: Text(
                    "No conversations yet",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final selected =
                        conversation["_id"] == _activeConversationId;

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.chat_bubble_rounded,
                        color: selected
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF94A3B8),
                      ),
                      title: Text(
                        conversation["title"],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      onTap: () => _loadMessages(conversation["_id"]),
                    );
                  },
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Color(0xFF1E40AF),
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Ask Servify AI",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Describe your home problem and AI will suggest the right worker, urgency, and safe next steps.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatList() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _typingBubble();
        }

        final message = _messages[index];
        final isUser = message["role"] == "user";

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: isUser ? _userBubble(message) : _aiBubble(message),
        );
      },
    );
  }

  Widget _userBubble(Map<String, dynamic> message) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 285),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF),
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomRight: const Radius.circular(4),
        ),
      ),
      child: Text(
        message["content"] ?? "",
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _aiBubble(Map<String, dynamic> message) {
    final steps = List<String>.from(message["steps"] ?? []);
    final safetyNotes = List<String>.from(message["safetyNotes"] ?? []);

    return Container(
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomLeft: const Radius.circular(4),
        ),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message["content"] ?? "",
            style: GoogleFonts.inter(
              color: const Color(0xFF1E293B),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          _infoChips(message),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle("Steps"),
            ...steps.map((s) => _bullet(s)),
          ],
          if (safetyNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle("Safety Notes"),
            ...safetyNotes.map((s) => _bullet(s)),
          ],
        ],
      ),
    );
  }

  Widget _infoChips(Map<String, dynamic> message) {
  final List<Widget> chips = [];

  final workerType = message["workerType"];
  final urgency = message["urgency"];
  final canFix = message["canUserFix"];

  if (workerType != null && workerType != "unknown") {
    chips.add(_smallChip(_formatWorkerType(workerType)));
  }

  if (urgency != null && urgency != "unknown") {
    chips.add(_smallChip(_formatUrgency(urgency)));
  }

  if (canFix != null && canFix != "unknown") {
    chips.add(_smallChip(_formatFixability(canFix)));
  }

  if (chips.isEmpty) return const SizedBox();

  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: chips,
  );
}

String _formatWorkerType(String type) {
  switch (type) {
    case "plumber":
      return "Plumber";
    case "electrician":
      return "Electrician";
    case "ac_technician":
      return "AC Technician";
    case "painter":
      return "Painter";
    case "carpenter":
      return "Carpenter";
    case "cleaner":
      return "Cleaner";
    case "handyman":
      return "Handyman";
    default:
      return "";
  }
}

String _formatUrgency(String urgency) {
  switch (urgency) {
    case "low":
      return "Low urgency";
    case "medium":
      return "Medium urgency";
    case "high":
      return "High urgency";
    default:
      return "";
  }
}

String _formatFixability(String fix) {
  switch (fix) {
    case "yes":
      return "You can fix it";
    case "limited":
      return "Try basic fix";
    case "no":
      return "Needs a professional";
    default:
      return "";
  }
}

  Widget _smallChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E40AF),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Color(0xFF1E40AF))),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.35,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Text(
          "AI is thinking...",
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Describe your problem...",
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isSending
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF1E40AF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}