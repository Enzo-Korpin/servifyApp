import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/profiles/profile_worker.dart';
import 'package:frontend/Follow/Follow_service.dart';
import 'Worker_Follow_card.dart';

class FollowedWorkersPage extends StatefulWidget {
  const FollowedWorkersPage({super.key});

  @override
  State<FollowedWorkersPage> createState() => _FollowedWorkersPageState();
}

class _FollowedWorkersPageState extends State<FollowedWorkersPage> {
  final FollowService _followService = FollowService();

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> followedWorkers = [];

  @override
  void initState() {
    super.initState();
    _loadFollowingWorkers();
  }

  Future<void> _loadFollowingWorkers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workers = await _followService.getFollowingWorkers();

      if (!mounted) return;
      setState(() {
        followedWorkers = workers;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            e.response?.data?["message"]?.toString() ??
            e.response?.data?["error"]?.toString() ??
            "Failed to load followed workers";
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load followed workers";
        _isLoading = false;
      });
    }
  }

  Future<void> _unfollowWorker(String workerId) async {
    try {
      await _followService.unfollowWorker(workerId);

      if (!mounted) return;
      setState(() {
        followedWorkers.removeWhere((worker) => worker["workerId"] == workerId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Worker unfollowed"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?["message"]?.toString() ??
          e.response?.data?["error"]?.toString() ??
          "Failed to unfollow";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to unfollow"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF08214A);
    const Color primaryBlue = Color(0xFF2948B8);
    const Color sheetColor = Color(0xFFEAF0F7);

    return Scaffold(
      backgroundColor: darkBlue,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          "Followed Workers",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Quick access to workers you follow",
                    style: TextStyle(
                      color: Color(0xFFB9C6E2),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                decoration: const BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB9C2D0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            "${followedWorkers.length} Workers",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Manage your followed workers list",
                            style: TextStyle(
                              color: Color(0xFF6E7889),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _error!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFF7C879A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: _loadFollowingWorkers,
                                        child: const Text("Retry"),
                                      ),
                                    ],
                                  ),
                                )
                              : followedWorkers.isEmpty
                                  ? const Center(
                                      child: Text(
                                        "No followed workers yet",
                                        style: TextStyle(
                                          color: Color(0xFF7C879A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: followedWorkers.length,
                                      itemBuilder: (context, index) {
                                        final worker = followedWorkers[index];

                                        return FollowedWorkerCard(
                                          name: worker["name"] ?? "",
                                          profession:
                                              worker["profession"] ?? "Worker",
                                          distanceKm:
                                              ((worker["distance"] ?? 0) as num)
                                                  .toDouble(),
                                          rating:
                                              ((worker["rating"] ?? 0) as num)
                                                  .toDouble(),
                                          imageUrl: worker["imageUrl"],
                                          onView: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ProfileWorker(
                                                  workerId: worker["workerId"],
                                                ),
                                              ),
                                            );

                                            _loadFollowingWorkers();
                                          },
                                          onUnfollow: () {
                                            _unfollowWorker(worker["workerId"]);
                                          },
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}