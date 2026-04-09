import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../../requests/widgets/request_card_widget.dart';

enum RequestTab { active, completed, canceled }

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final RequestService _requestService = RequestService();
  final ScrollController _scrollController = ScrollController();

  RequestTab _selectedTab = RequestTab.active;

  List<RequestModel> _requests = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _nextCursor;
  String? _errorMessage;

  // ── Colors (matching Servify theme) ──
  static const _navyDark  = Color(0xFF0A1628);
  static const _navyMid   = Color(0xFF1E40AF);
  static const _bgLight   = Color(0xFFEFF6FF);
  static const _borderBlue = Color(0xFFDBEAFE);
  static const _textDark  = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _fetchRequests(refresh: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 120 &&
          !_isLoadingMore &&
          !_isLoading &&
          _hasMore) {
        _fetchRequests();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String? _backendStatusForTab(RequestTab tab) {
    switch (tab) {
      case RequestTab.active:    return 'pending';
      case RequestTab.completed: return 'accepted';
      case RequestTab.canceled:  return null;
    }
  }

  Future<void> _fetchRequests({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _requests = [];
          _nextCursor = null;
          _hasMore = true;
        });
      } else {
        setState(() { _isLoadingMore = true; _errorMessage = null; });
      }

      if (_selectedTab == RequestTab.canceled) {
        final response = await _requestService.getCanceledRequests();
        setState(() { _requests = response.docs; _hasMore = false; });
      } else {
        final response = await _requestService.getCustomerRequests(
          status: _backendStatusForTab(_selectedTab),
          after: refresh ? null : _nextCursor,
        );
        setState(() {
          if (refresh) { _requests = response.docs; }
          else         { _requests.addAll(response.docs); }
          _nextCursor = response.nextCursor;
          _hasMore = response.docs.isNotEmpty && response.nextCursor != null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load requests');
    } finally {
      setState(() { _isLoading = false; _isLoadingMore = false; });
    }
  }

  Future<void> _changeTab(RequestTab tab) async {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    await _fetchRequests(refresh: true);
  }

  String _tabText(RequestTab tab) {
    switch (tab) {
      case RequestTab.active:    return 'Active';
      case RequestTab.completed: return 'Completed';
      case RequestTab.canceled:  return 'Canceled';
    }
  }

  // ── Header with dark navy background + tabs ──
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _navyDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow label
              Text(
                "OVERVIEW",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB4D2FF).withOpacity(0.45),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),

              // Page title
              Text(
                "My Requests",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),

              // Tab chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab(RequestTab.active),
                    const SizedBox(width: 8),
                    _buildTab(RequestTab.completed),
                    const SizedBox(width: 8),
                    _buildTab(RequestTab.canceled),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab chip ──
  Widget _buildTab(RequestTab tab) {
    final selected = _selectedTab == tab;
    return GestureDetector(
      onTap: () => _changeTab(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? _navyMid
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _navyMid
                : const Color(0xFF63B3FF).withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          _tabText(tab),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : const Color(0xFFB4D2FF).withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  // ── Body (list / loading / error / empty) ──
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: _textMuted),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _fetchRequests(refresh: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: _navyMid,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "Retry",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _borderBlue, width: 1.5),
                  ),
                  child: const Icon(Icons.inbox_outlined,
                      size: 32, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),
                Text(
                  "No requests found",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your ${_tabText(_selectedTab).toLowerCase()} requests will appear here",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _textMuted.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _requests.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RequestCardWidget(request: _requests[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
          // Dark navy header
          _buildHeader(),

          // List content on light blue background
          Expanded(
            child: RefreshIndicator(
              color: _navyMid,
              backgroundColor: Colors.white,
              onRefresh: () => _fetchRequests(refresh: true),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }
}