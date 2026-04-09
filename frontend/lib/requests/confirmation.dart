import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    this.workerName      = 'Worker',
    this.workerImageUrl  = '',
    this.workerRating    = 0,
    this.serviceName     = 'Service Request',
    this.serviceDateTime = 'Request submitted successfully',
    this.serviceIcon     = Icons.home_repair_service,
    required this.workerId,
    this.requestId = '',
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Outer ring: slow, gentle scale-in
  late Animation<double> _outerScale;
  late Animation<double> _outerOpacity;

  // Inner circle: slightly delayed
  late Animation<double> _innerScale;
  late Animation<double> _innerOpacity;

  // Check icon: last to appear
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;

  // Content below the check fades in after check is done
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  // ── Theme colours ──
  static const _navyDark   = Color(0xFF0A1628);
  static const _navyMid    = Color(0xFF1E40AF);
  static const _bgLight    = Color(0xFFEFF6FF);
  static const _borderBlue = Color(0xFFDBEAFE);
  static const _textDark   = Color(0xFF1E293B);
  static const _textMuted  = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();

    // Total duration: 2.2s — slow and satisfying
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Outer ring: 0–50%
    _outerScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _outerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Inner circle: 15–60%
    _innerScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _innerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.4, curve: Curves.easeIn),
      ),
    );

    // Check icon: 35–75% — elastic bounce
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.elasticOut),
      ),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.55, curve: Curves.easeIn),
      ),
    );

    // Content fades + slides up: 60–100%
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Animated check mark ──
  Widget _buildAnimatedCheck() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FadeTransition(
          opacity: _outerOpacity,
          child: ScaleTransition(
            scale: _outerScale,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withOpacity(0.1),
              ),
              child: Center(
                child: FadeTransition(
                  opacity: _innerOpacity,
                  child: ScaleTransition(
                    scale: _innerScale,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFDCFCE7),
                      ),
                      child: Center(
                        child: FadeTransition(
                          opacity: _checkOpacity,
                          child: ScaleTransition(
                            scale: _checkScale,
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF16A34A),
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Worker avatar ──
  Widget _buildAvatar() {
    if (widget.workerImageUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(widget.workerImageUrl),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Icon(Icons.person_outline_rounded,
          color: _navyMid, size: 22),
    );
  }

  // ── Info card wrapper ──
  Widget _infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderBlue, width: 1.5),
      ),
      child: child,
    );
  }

  // ── Eyebrow label ──
  Widget _eyebrow(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: _textMuted,
        letterSpacing: 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
          // ── Dark navy top bar ──
          Container(
            width: double.infinity,
            color: _navyDark,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF63B3FF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF63B3FF).withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF63B3FF),
                          size: 22,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Confirmation",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              child: Column(
                children: [
                  // Animated check
                  _buildAnimatedCheck(),
                  const SizedBox(height: 24),

                  // Animated content below
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        children: [
                          // Title
                          Text(
                            "Your Request has been\nSent!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Subtitle
                          Text(
                            "We've notified ${widget.workerName} and you'll receive a\nconfirmation soon.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.6,
                              color: _textMuted,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Service details card ──
                          _infoCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    widget.serviceIcon,
                                    color: _navyMid,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _eyebrow("Service Details"),
                                      const SizedBox(height: 5),
                                      Text(
                                        widget.serviceName,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        widget.serviceDateTime,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: _textMuted,
                                        ),
                                      ),
                                      if (widget.requestId.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          "Request ID: ${widget.requestId}",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ── Worker card ──
                          _infoCard(
                            child: Row(
                              children: [
                                _buildAvatar(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _eyebrow("Your Professional"),
                                      const SizedBox(height: 5),
                                      Text(
                                        widget.workerName,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              size: 14, color: Color(0xFFF59E0B)),
                                          const SizedBox(width: 3),
                                          Text(
                                            widget.workerRating.toStringAsFixed(1),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFF59E0B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // View Profile button
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProfileWorker(
                                            workerId: widget.workerId),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: _borderBlue, width: 1),
                                    ),
                                    child: Text(
                                      "View Profile",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _navyMid,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── View My Requests button ──
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const RequestsPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _navyMid,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "View My Requests",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Back to Home ──
                          TextButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const WorkerMapPage()),
                                (route) => false,
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Back to Home",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _navyMid,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}