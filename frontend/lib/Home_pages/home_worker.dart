import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/current_user_model.dart';
import '../models/service_request_model.dart';
import '../services/worker_request_service.dart';
import '../services/account_switch_service.dart';
import '../requests/Widgets/worker_order_card.dart';
import '../Access/login_screens/Login_Screen.dart';
import 'package:dio/dio.dart';
import 'package:frontend/worker/worker_profile_screen.dart';


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
      nextCursor:
          identical(nextCursor, _unset) ? this.nextCursor : nextCursor as String?,
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

class _HomeWorkerState extends State<HomeWorker> {
  late final WorkerRequestService _service;
  late final AccountSwitchService _accountSwitchService;
  final ScrollController _scrollController = ScrollController();

  CurrentUserModel? _currentUser;
  AuthCheckUser? _authUser;

  bool _isInitialLoading = true;
  bool _isActionLoading = false;
  bool _isSwitchingAccount = false;
  String? _globalError;

  String _selectedStatus = "pending";

  Map<String, int> _stats = {
    "pending": 0,
    "accepted": 0,
    "rejected": 0,
  };

  final List<String> _statuses = ["pending", "accepted", "rejected"];

  late Map<String, _StatusState> _statusData;

  @override
  void initState() {
    super.initState();
    _service = WorkerRequestService();
    _accountSwitchService = AccountSwitchService();

    _statusData = {
      "pending": const _StatusState(),
      "accepted": const _StatusState(),
      "rejected": const _StatusState(),
    };

    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  _StatusState get _currentStatusState => _statusData[_selectedStatus]!;

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 250) {
      _loadMore();
    }
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
      ]);

      final currentUser = results[0] as CurrentUserModel;
      final stats = results[1] as Map<String, int>;
      final firstPage = results[2] as PaginatedServiceRequestsResponse;
      final authUser = results[3] as AuthCheckUser;

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
      });
    } catch (e) {
      setState(() {
        _globalError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _changeStatus(String status) async {
    if (_selectedStatus == status) return;

    setState(() {
      _selectedStatus = status;
    });

    final state = _statusData[status]!;
    if (state.hasLoadedOnce) return;

    await _loadStatusFirstPage(status);
  }

  Future<void> _loadStatusFirstPage(String status) async {
    final current = _statusData[status]!;

    setState(() {
      _statusData[status] = current.copyWith(
        isLoading: true,
        clearError: true,
      );
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
        _statusData[status] = _statusData[status]!.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load $status requests: $e")),
      );
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

      final existingIds = state.requests.map((e) => e.id).toSet();
      final merged = List<ServiceRequestModel>.from(state.requests);

      for (final item in response.docs) {
        if (!existingIds.contains(item.id)) {
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
        _statusData[_selectedStatus] = _statusData[_selectedStatus]!.copyWith(
          isLoadingMore: false,
          error: e.toString(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load more: $e")),
      );
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

      final stats = results[0] as Map<String, int>;
      final response = results[1] as PaginatedServiceRequestsResponse;
      final authUser = results[2] as AuthCheckUser;

      setState(() {
        _stats = stats;
        _authUser = authUser;
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
        _statusData[_selectedStatus] = _statusData[_selectedStatus]!.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Refresh failed: $e")),
      );
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      await _service.acceptRequest(requestId);
      await _refreshCurrentTab();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request accepted successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Accept failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reject Request"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Enter reject reason (optional)",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      await _service.rejectRequest(requestId, rejectReason: reason);
      await _refreshCurrentTab();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request rejected successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reject failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _switchAccount() async {
    if (_authUser == null) return;
    if (_authUser!.role != "worker") return;

    final targetRole =
        _accountSwitchService.getTargetRole(_authUser!.currentRole);

    setState(() {
      _isSwitchingAccount = true;
    });

    try {
      final newCurrentRole = await _accountSwitchService.switchRole(targetRole);

      if (!mounted) return;

      setState(() {
        _authUser = AuthCheckUser(
          id: _authUser!.id,
          fullName: _authUser!.fullName,
          email: _authUser!.email,
          role: _authUser!.role,
          currentRole: newCurrentRole,
          image: _authUser!.image,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Switched to $newCurrentRole account")),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(), // or LoginScreen()
        ),
        (route) => false,
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?["error"]?["message"]?.toString() ??
          e.response?.data?["message"]?.toString() ??
          "Switch account failed";

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Switch account failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingAccount = false;
        });
      }
    }
  }

  Widget _buildStatCard(String title, int value) {
    return Expanded(
      child: Container(
        height: 93,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value.toString(),
                style: GoogleFonts.instrumentSans(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 10, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F6FEB) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF1F6FEB) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${status[0].toUpperCase()}${status.substring(1)}",
              style: GoogleFonts.instrumentSans(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (state.isLoading) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isSelected ? Colors.white : const Color(0xFF1F6FEB),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchAccountButton() {
    if (_authUser == null) return const SizedBox.shrink();
    if (_authUser!.role != "worker") return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSwitchingAccount ? null : _switchAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F6FEB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _isSwitchingAccount
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.swap_horiz, color: Colors.white),
        label: Text(
          _accountSwitchService.getButtonText(_authUser!.currentRole),
          style: GoogleFonts.instrumentSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(50),
               onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const WorkerProfileScreen(),
                    ),
                  );

                  if (updated == true) {
                    if (!mounted) return;
                    await _loadInitialData();
                  }
                },
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: (_currentUser?.image != null &&
                          _currentUser!.image!.isNotEmpty)
                      ? NetworkImage(_currentUser!.image!)
                      : const AssetImage("assets/emptypicture.png")
                          as ImageProvider,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Welcome, ${_currentUser?.fullName.isNotEmpty == true ? _currentUser!.fullName : "Worker"}",
                  style: GoogleFonts.instrumentSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildSwitchAccountButton(),
        const SizedBox(height: 30),
        Row(
          children: [
            _buildStatCard("Pending", _stats["pending"] ?? 0),
            _buildStatCard("Accepted", _stats["accepted"] ?? 0),
            _buildStatCard("Rejected", _stats["rejected"] ?? 0),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          "Requests",
          style: GoogleFonts.instrumentSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          children: _statuses.map(_buildStatusChip).toList(),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Showing ${_selectedStatus[0].toUpperCase()}${_selectedStatus.substring(1)} Requests",
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: _refreshCurrentTab,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInitialLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildGlobalError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Failed to load requests",
              style: GoogleFonts.instrumentSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _globalError ?? "Unknown error",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyList() {
    final state = _currentStatusState;

    if (state.error != null && state.requests.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Failed to load $_selectedStatus requests",
                  style: GoogleFonts.instrumentSans(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadStatusFirstPage(_selectedStatus),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.requests.isEmpty && state.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.requests.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            "No $_selectedStatus requests",
            style: GoogleFonts.instrumentSans(fontSize: 16),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < state.requests.length) {
            final request = state.requests[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
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
            );
          }

          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (!state.hasMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "No more requests",
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13,
                    color: Colors.grey,
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

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(child: _buildInitialLoading()),
      );
    }

    if (_globalError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(child: _buildGlobalError()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshCurrentTab,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _buildHeader(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _buildBodyList(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}