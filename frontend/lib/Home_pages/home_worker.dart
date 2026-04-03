import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service_request_model.dart';
import '../models/current_user_model.dart';
import '../services/worker_request_service.dart';
import '../requests/Widgets/worker_order_card.dart';

class HomeWorker extends StatefulWidget {
  const HomeWorker({super.key});

  @override
  State<HomeWorker> createState() => _HomeWorkerState();
}

class _HomeWorkerState extends State<HomeWorker> {
  final AssetImage backgroundImage = const AssetImage("assets/emptypicture.png");
  CurrentUserModel? _currentUser;

  late final WorkerRequestService _service;

  bool _isInitialLoading = true;
  bool _isTabLoading = false;
  bool _isActionLoading = false;

  String? _error;

  String _selectedStatus = "pending";

  List<ServiceRequestModel> _requests = [];
  Map<String, int> _stats = {
    "pending": 0,
    "accepted": 0,
    "rejected": 0,
  };

  final List<String> _statuses = ["pending", "accepted", "rejected"];

  @override
  void initState() {
    super.initState();
    _service = WorkerRequestService();
    _loadInitialData();
  }

      Future<void> _loadInitialData() async {
        setState(() {
          _isInitialLoading = true;
          _error = null;
        });

        try {
          final results = await Future.wait([
            _service.getCurrentUser(),
            _service.getWorkerStats(),
            _service.getWorkerRequests(status: _selectedStatus),
          ]);

          setState(() {
            _currentUser = results[0] as CurrentUserModel;
            _stats = results[1] as Map<String, int>;
            _requests = results[2] as List<ServiceRequestModel>;
          });
        } catch (e) {
          setState(() {
            _error = e.toString();
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
      if (_selectedStatus == status || _isTabLoading) return;

      setState(() {
        _selectedStatus = status;
        _isTabLoading = true;
        _error = null;
      });

      try {
        final requests = await _service.getWorkerRequests(status: status);

        if (!mounted) return;

        setState(() {
          _requests = requests;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _error = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load $status requests: $e")),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isTabLoading = false;
          });
        }
      }
    }

  Future<void> _refreshCurrentTab() async {
    try {
      final results = await Future.wait([
        _service.getWorkerStats(),
        _service.getWorkerRequests(status: _selectedStatus),
      ]);

      if (!mounted) return;

      setState(() {
        _stats = results[0] as Map<String, int>;
        _requests = results[1] as List<ServiceRequestModel>;
      });
    } catch (e) {
      if (!mounted) return;

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

    return GestureDetector(
      onTap: _isTabLoading ? null : () => _changeStatus(status),
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
        child: Text(
          "${status[0].toUpperCase()}${status.substring(1)}",
          style: GoogleFonts.instrumentSans(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
      if (_isInitialLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 80),
            child: CircularProgressIndicator(),
          ),
        );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
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
                _error!,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {},
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: (_currentUser?.image != null &&
                          _currentUser!.image!.isNotEmpty)
                      ? NetworkImage(_currentUser!.image!)
                      : const AssetImage("assets/emptypicture.png") as ImageProvider,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Welcome, ${_currentUser?.fullName.isNotEmpty == true ? _currentUser!.fullName : "Worker"}",
                style: GoogleFonts.instrumentSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
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
          children: _statuses.map<Widget>((status) {
            return _buildStatusChip(status);
          }).toList(),
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
        if (_isTabLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: LinearProgressIndicator(),
          ),
        if (_requests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Text(
                "No $_selectedStatus requests",
                style: GoogleFonts.instrumentSans(fontSize: 16),
              ),
            ),
          )
        else
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey(_selectedStatus),
            children: _requests.map<Widget>((request) {
              return WorkerOrderCard(
                request: request,
                isUpdating: _isActionLoading,
                onAccept: request.status == "pending"
                    ? () => _acceptRequest(request.id)
                    : null,
                onReject: request.status == "pending"
                    ? () => _rejectRequest(request.id)
                    : null,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshCurrentTab,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }
}