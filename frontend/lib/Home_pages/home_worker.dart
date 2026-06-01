import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/current_user_model.dart';
import '../models/service_request_model.dart';
import '../services/worker_request_service.dart';
import '../services/account_switch_service.dart';
import '../requests/Widgets/worker_order_card.dart';
import '../Access/login_screens/Login_Screen.dart';
import '../Access/login_screens/select_type.dart';
import 'package:dio/dio.dart';
import 'package:frontend/worker/worker_profile_screen.dart';
import 'package:frontend/worker/worker_feedbacks_tab.dart';
import 'package:frontend/chat/chat_page.dart';
import 'package:frontend/ai/ai_chat_page.dart';
import 'package:frontend/core/network/socket_client.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/ui/app_notify.dart';

class _StatusState {
  static const Object _unset = Object();

  final List<ServiceRequestModel> requests;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasLoadedOnce;

  const _StatusState({
    this.requests = const [],
    this.nextCursor,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  _StatusState copyWith({
    List<ServiceRequestModel>? requests,
    Object? nextCursor = _unset,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool? hasLoadedOnce,
  }) {
    return _StatusState(
      requests: requests ?? this.requests,
      nextCursor: identical(nextCursor, _unset)
          ? this.nextCursor
          : nextCursor as String?,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}

class HomeWorker extends StatefulWidget {
  const HomeWorker({super.key});

  @override
  State<HomeWorker> createState() => _HomeWorkerState();
}

class _HomeWorkerState extends State<HomeWorker>
    with SingleTickerProviderStateMixin {
  late final WorkerRequestService _service;
  late final AccountSwitchService _accountSwitchService;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _entranceController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _statsFade;
  late Animation<Offset> _statsSlide;
  late Animation<double> _listFade;

  CurrentUserModel? _currentUser;
  AuthCheckUser? _authUser;

  bool _isInitialLoading = true;
  bool _isActionLoading = false;
  bool _isSwitchingAccount = false;
  bool _isLoggingOut = false;
  String? _globalError;

  int _selectedIndex = 0;
  String _selectedStatus = "pending";

  double _avgRating = 0;
  int _ratingCount = 0;

  Map<String, int> _stats = {
    "pending": 0,
    "accepted": 0,
    "rejected": 0,
    "cancelled": 0,
  };

  final List<String> _statuses = [
    "pending",
    "accepted",
    "rejected",
    "cancelled",
  ];

  late Map<String, _StatusState> _statusData;

  static const _navyDark = Color(0xFF0A1628);
  static const _navyMid = Color(0xFF1E40AF);
  static const _bgLight = Color(0xFFEFF6FF);
  static const _borderBlue = Color(0xFFDBEAFE);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _service = WorkerRequestService();
    _accountSwitchService = AccountSwitchService();

    _statusData = {
      "pending": const _StatusState(),
      "accepted": const _StatusState(),
      "rejected": const _StatusState(),
      "cancelled": const _StatusState(),
    };

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _statsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );

    _statsSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );

    _listFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  _StatusState get _currentStatusState => _statusData[_selectedStatus]!;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 250) _loadMore();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
      _globalError = null;
    });

    try {
      final results = await Future.wait([
        _service.getCurrentUser(),
        _service.getWorkerStats(),
        _service.getWorkerRequests(status: _selectedStatus),
        _accountSwitchService.checkAuth(),
        _service.getMyRating(),
      ]);

      final currentUser = results[0] as CurrentUserModel;
      final stats = results[1] as Map<String, int>;
      final firstPage = results[2] as PaginatedServiceRequestsResponse;
      final authUser = results[3] as AuthCheckUser;
      final rating = results[4] as Map<String, num>;

      _statusData[_selectedStatus] = _statusData[_selectedStatus]!.copyWith(
        requests: firstPage.docs,
        nextCursor: firstPage.nextCursor,
        hasMore: firstPage.docs.isNotEmpty && firstPage.nextCursor != null,
        isLoading: false,
        isLoadingMore: false,
        hasLoadedOnce: true,
        clearError: true,
      );

      setState(() {
        _currentUser = currentUser;
        _stats = stats;
        _authUser = authUser;
        _avgRating = (rating["rate"] ?? 0).toDouble();
        _ratingCount = (rating["ratingCount"] ?? 0).toInt();
      });

      _entranceController.forward(from: 0);
    } catch (e) {
      setState(() => _globalError = e.toString());
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _changeStatus(String status) async {
    if (_selectedStatus == status) return;
    setState(() => _selectedStatus = status);
    if (_statusData[status]!.hasLoadedOnce) return;
    await _loadStatusFirstPage(status);
  }

  Future<void> _loadStatusFirstPage(String status) async {
    setState(() {
      _statusData[status] =
          _statusData[status]!.copyWith(isLoading: true, clearError: true);
    });

    try {
      final response = await _service.getWorkerRequests(status: status);
      if (!mounted) return;
      setState(() {
        _statusData[status] = _statusData[status]!.copyWith(
          requests: response.docs,
          nextCursor: response.nextCursor,
          hasMore: response.docs.isNotEmpty && response.nextCursor != null,
          isLoading: false,
          isLoadingMore: false,
          hasLoadedOnce: true,
          clearError: true,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusData[status] =
            _statusData[status]!.copyWith(isLoading: false, error: e.toString());
      });
      _showSnack(AppNotify.messageFromError(e, fallback: "We couldn't load your requests. Please try again."));
    }
  }

  Future<void> _loadMore() async {
    final state = _currentStatusState;
    if (_isInitialLoading ||
        _isActionLoading ||
        _isSwitchingAccount ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.nextCursor == null) {
      return;
    }

    setState(() {
      _statusData[_selectedStatus] = state.copyWith(isLoadingMore: true);
    });

    try {
      final response = await _service.getWorkerRequests(
        status: _selectedStatus,
        after: state.nextCursor,
      );

      if (!mounted) return;

      final ids = state.requests.map((e) => e.id).toSet();
      final merged = List<ServiceRequestModel>.from(state.requests);

      for (final item in response.docs) {
        if (!ids.contains(item.id)) {
          merged.add(item);
        }
      }

      setState(() {
        _statusData[_selectedStatus] = _statusData[_selectedStatus]!.copyWith(
          requests: merged,
          nextCursor: response.nextCursor,
          hasMore: response.docs.isNotEmpty && response.nextCursor != null,
          isLoadingMore: false,
          hasLoadedOnce: true,
          clearError: true,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusData[_selectedStatus] = _statusData[_selectedStatus]!
            .copyWith(isLoadingMore: false, error: e.toString());
      });
      _showSnack(AppNotify.messageFromError(e, fallback: "We couldn't load more requests. Please try again."));
    }
  }

  Future<void> _refreshCurrentTab() async {
    final state = _currentStatusState;
    setState(() {
      _statusData[_selectedStatus] = state.copyWith(
        isLoading: true,
        isLoadingMore: false,
        clearError: true,
      );
    });

    try {
      final results = await Future.wait([
        _service.getWorkerStats(),
        _service.getWorkerRequests(status: _selectedStatus),
        _accountSwitchService.checkAuth(),
      ]);

      if (!mounted) return;

      setState(() {
        _stats = results[0] as Map<String, int>;
        _authUser = results[2] as AuthCheckUser;
        final response = results[1] as PaginatedServiceRequestsResponse;
        _statusData[_selectedStatus] = _statusData[_selectedStatus]!.copyWith(
          requests: response.docs,
          nextCursor: response.nextCursor,
          hasMore: response.docs.isNotEmpty && response.nextCursor != null,
          isLoading: false,
          isLoadingMore: false,
          hasLoadedOnce: true,
          clearError: true,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusData[_selectedStatus] = _statusData[_selectedStatus]!
            .copyWith(isLoading: false, error: e.toString());
      });
      _showSnack(AppNotify.messageFromError(e, fallback: "We couldn't refresh. Please try again."));
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    setState(() => _isActionLoading = true);
    try {
      await _service.acceptRequest(requestId);
      await _refreshCurrentTab();
      if (!mounted) return;
      _showSnack("Request accepted.", isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack(AppNotify.messageFromError(e, fallback: "We couldn't accept this request. Please try again."));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Reject Request",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: "Enter reject reason (optional)",
            hintStyle: GoogleFonts.inter(color: _textMuted),
            filled: true,
            fillColor: _bgLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderBlue, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderBlue, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _navyMid, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                color: _textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context, controller.text.trim()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE24B4A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Reject",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (reason == null) return;

    setState(() => _isActionLoading = true);
    try {
      await _service.rejectRequest(requestId, rejectReason: reason);
      await _refreshCurrentTab();
      if (!mounted) return;
      _showSnack("Request rejected.", isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack(AppNotify.messageFromError(e, fallback: "We couldn't reject this request. Please try again."));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _switchAccount() async {
    if (_authUser == null || _authUser!.role != "worker") return;
    final targetRole =
        _accountSwitchService.getTargetRole(_authUser!.currentRole);

    setState(() => _isSwitchingAccount = true);

    try {
      final newRole = await _accountSwitchService.switchRole(targetRole);
      if (!mounted) return;

      setState(() {
        _authUser = AuthCheckUser(
          id: _authUser!.id,
          fullName: _authUser!.fullName,
          email: _authUser!.email,
          role: _authUser!.role,
          currentRole: newRole,
          image: _authUser!.image,
        );
      });

      _showSnack("Switched to your $newRole account.", isError: false);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnack(AppNotify.messageFromError(e, fallback: "We couldn't switch accounts. Please try again."));
    } catch (e) {
      if (!mounted) return;
      _showSnack(AppNotify.messageFromError(e, fallback: "We couldn't switch accounts. Please try again."));
    } finally {
      if (mounted) setState(() => _isSwitchingAccount = false);
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    if (isError) {
      AppNotify.error(context, message);
    } else {
      AppNotify.success(context, message);
    }
  }

  Future<void> logoutUser() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      SocketClient.instance.disconnect();
      await Future.delayed(const Duration(milliseconds: 200));

      await DioClient.dio.post("/api/auth/logout");

      await DioClient.resetCookieJarCompletely();

      if (!mounted) return;

      AppNotify.success(context, "You've been logged out.");

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SelectType()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      AppNotify.error(context, AppNotify.messageFromError(e, fallback: "We couldn't log you out. Please try again."));
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<void> confirmLogout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await logoutUser();
    }
  }

  Widget _buildMainActionButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
    IconData? icon,
    bool isBusy = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isBusy
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRatingPill() {
    final hasRatings = _ratingCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasRatings)
            Text(
              _avgRating.toStringAsFixed(1),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            )
          else
            Text(
              "New",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          const SizedBox(width: 3),
          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 15),
        ],
      ),
    );
  }

  Widget _buildNavyHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          width: double.infinity,
          color: _navyDark,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () async {
                          final updated =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const WorkerProfileScreen(),
                            ),
                          );
                          if (updated == true && mounted) {
                            await _loadInitialData();
                          }
                        },
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF63B3FF).withOpacity(0.35),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFF1A3A6E),
                            backgroundImage: (_currentUser?.image != null &&
                                    _currentUser!.image!.isNotEmpty)
                                ? NetworkImage(_currentUser!.image!)
                                : const AssetImage("assets/emptypicture.png")
                                    as ImageProvider,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFFB4D2FF).withOpacity(0.5),
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _currentUser?.fullName.isNotEmpty == true
                                        ? _currentUser!.fullName
                                        : "Worker",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildRatingPill(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_authUser != null && _authUser!.role == "worker")
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSwitchingAccount ? null : _switchAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navyMid,
                          disabledBackgroundColor: _navyMid.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isSwitchingAccount
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.swap_horiz_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                        label: Text(
                          _accountSwitchService
                              .getButtonText(_authUser!.currentRole),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final configs = [
      {"label": "Pending", "key": "pending", "color": Colors.black},
      {"label": "Accepted", "key": "accepted", "color": Colors.black},
      {"label": "Rejected", "key": "rejected", "color": Colors.black},
      {"label": "Cancelled", "key": "cancelled", "color": Colors.black},
    ];

    return FadeTransition(
      opacity: _statsFade,
      child: SlideTransition(
        position: _statsSlide,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: configs.map((c) {
            final color = c["color"] as Color;
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 2,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderBlue, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (c["label"] as String).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (_stats[c["key"] as String] ?? 0).toString(),
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isSelected = _selectedStatus == status;
    final state = _statusData[status]!;

    return GestureDetector(
      onTap: () => _changeStatus(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? _navyMid : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _navyMid : _borderBlue,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${status[0].toUpperCase()}${status.substring(1)}",
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : _textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (state.isLoading) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isSelected ? Colors.white : _navyMid,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsSection() {
    return FadeTransition(
      opacity: _listFade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "REQUESTS",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151).withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._statuses.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStatusChip(s),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Showing ${_selectedStatus[0].toUpperCase()}${_selectedStatus.substring(1)} Requests",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
              GestureDetector(
                onTap: _refreshCurrentTab,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _borderBlue, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: _navyMid,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBodyList() {
    final state = _currentStatusState;

    if (state.error != null && state.requests.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _emptyState(
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFE24B4A),
          title: "Failed to load requests",
          subtitle: state.error,
          action: () => _loadStatusFirstPage(_selectedStatus),
          actionLabel: "Retry",
        ),
      );
    }

    if (state.requests.isEmpty && state.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: _navyMid),
        ),
      );
    }

    if (state.requests.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _emptyState(
          icon: Icons.inbox_outlined,
          iconColor: _textMuted,
          title: "No $_selectedStatus requests",
          subtitle: "New requests will appear here",
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < state.requests.length) {
            final request = state.requests[index];
            return FadeTransition(
              opacity: _listFade,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: WorkerOrderCard(
                  request: request,
                  isUpdating: _isActionLoading || _isSwitchingAccount,
                  onAccept: request.status == "pending"
                      ? () => _acceptRequest(request.id)
                      : null,
                  onReject: request.status == "pending"
                      ? () => _rejectRequest(request.id)
                      : null,
                ),
              ),
            );
          }

          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: _navyMid),
              ),
            );
          }

          if (!state.hasMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "You're all caught up",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _textMuted,
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
        childCount: state.requests.length + 1,
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? action,
    String? actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderBlue, width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _textMuted,
                ),
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: action,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: _navyMid,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: _bgLight,
        body: const Center(
          child: CircularProgressIndicator(color: _navyMid),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgLight,
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildRequestsPage();
      case 1:
        return const ChatPage();
      case 2:
        return const AiChatPage();
      case 3:
        return _buildMyFeedbacksPage();
      case 4:
        return _buildProfilePage();
      default:
        return _buildRequestsPage();
    }
  }

  Widget _buildMyFeedbacksPage() {
    final workerId = _currentUser?.id ?? "";
    if (workerId.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _navyMid));
    }
    return WorkerFeedbacksTab(
      key: ValueKey("feedbacks-$workerId-$_ratingCount"),
      workerId: workerId,
      avgRating: _avgRating,
      ratingCount: _ratingCount,
    );
  }

  Widget _buildRequestsPage() {
    if (_globalError != null) {
      return _emptyState(
        icon: Icons.wifi_off_rounded,
        iconColor: const Color(0xFFE24B4A),
        title: "Failed to load",
        subtitle: _globalError,
        action: _loadInitialData,
        actionLabel: "Retry",
      );
    }

    return RefreshIndicator(
      color: _navyMid,
      backgroundColor: Colors.white,
      onRefresh: _refreshCurrentTab,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildNavyHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 20),
                  _buildRequestsSection(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildBodyList(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildNavyHeader(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const WorkerProfileScreen(),
                      ),
                    );
                    if (updated == true && mounted) {
                      await _loadInitialData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navyMid,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Edit Profile",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMainActionButton(
                  text: "Logout",
                  icon: Icons.logout_rounded,
                  backgroundColor: const Color(0xFFFFEAEA),
                  textColor: const Color(0xFFFF6B6B),
                  onPressed: confirmLogout,
                  isBusy: _isLoggingOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: _navyMid,
        unselectedItemColor: const Color(0xFF94A3B8),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description_rounded),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy_rounded),
            label: "AI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline_rounded),
            activeIcon: Icon(Icons.star_rounded),
            label: "My Feedbacks",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}