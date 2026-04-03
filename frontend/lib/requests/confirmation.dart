import 'package:flutter/material.dart';
import 'package:frontend/Home_pages/home_user.dart';
import 'package:frontend/profiles/profile_worker.dart';
import 'package:frontend/requests/Requists_page.dart';

class ConfirmationScreen extends StatefulWidget {
  final String workerName;
  final String workerImageUrl;
  final double workerRating;
  final String serviceName;
  final String serviceDateTime;
  final IconData serviceIcon;
  final String workerId;
  final String requestId;

  const ConfirmationScreen({
    super.key,
    this.workerName = 'Worker',
    this.workerImageUrl = '',
    this.workerRating = 0,
    this.serviceName = 'Service Request',
    this.serviceDateTime = 'Request submitted successfully',
    this.serviceIcon = Icons.home_repair_service,
    required this.workerId,
    this.requestId = '',
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleScaleAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _circleScaleAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedCheckMark() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _circleScaleAnimation,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color.fromARGB(255, 65, 166, 70).withOpacity(0.15),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _iconScaleAnimation,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFC8F1D7),
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF29B35B),
                  size: 34,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildWorkerAvatar() {
    if (widget.workerImageUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(widget.workerImageUrl),
      );
    }

    return const CircleAvatar(
      radius: 28,
      child: Icon(Icons.person),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirmation',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 227, 227, 227),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildAnimatedCheckMark(),
              const SizedBox(height: 28),
              const Text(
                'Your Request has been\nSent!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "We've notified ${widget.workerName} and you'll receive a\nconfirmation soon.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),
              _buildInfoCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.serviceIcon,
                        color: const Color(0xFF33B5E5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SERVICE DETAILS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.serviceName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.serviceDateTime,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          if (widget.requestId.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              "Request ID: ${widget.requestId}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                child: Row(
                  children: [
                    _buildWorkerAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR PROFESSIONAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.workerName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 18, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                widget.workerRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileWorker(workerId: widget.workerId),
                          ),
                        );
                      },
                      child: const Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF33B5E5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RequestsPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF33B5E5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'View My Requests',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerMapPage(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF33B5E5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}