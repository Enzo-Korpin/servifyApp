import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/ui/app_notify.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkerFeedbacksTab extends StatefulWidget {
  final String workerId;
  final double avgRating;
  final int ratingCount;

  const WorkerFeedbacksTab({
    super.key,
    required this.workerId,
    required this.avgRating,
    required this.ratingCount,
  });

  @override
  State<WorkerFeedbacksTab> createState() => _WorkerFeedbacksTabState();
}

class _WorkerFeedbacksTabState extends State<WorkerFeedbacksTab> {
  static const _navyDark = Color(0xFF0A1628);
  static const _navyMid = Color(0xFF1E40AF);
  static const _bgLight = Color(0xFFEFF6FF);
  static const _amber = Color(0xFFFFB800);

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DioClient.dio.get(
        '/api/feedback/worker/${widget.workerId}',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final raw = response.data["data"];
      final list = (raw is List)
          ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _reviews = list;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppNotify.messageFromError(e, fallback: "We couldn't load your feedback. Please try again.");
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "We couldn't load your feedback. Please try again.";
        _isLoading = false;
      });
    }
  }

  List<Widget> _buildStars(double rating, {double size = 18}) {
    final fullStars = rating.floor().clamp(0, 5);
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return [
      ...List.generate(
        fullStars,
        (_) => Icon(Icons.star_rounded, color: _amber, size: size),
      ),
      if (hasHalfStar)
        Icon(Icons.star_half_rounded, color: _amber, size: size),
      ...List.generate(
        emptyStars,
        (_) =>
            Icon(Icons.star_rounded, color: const Color(0xFFD8DCE6), size: size),
      ),
    ];
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return "";
    final dt = DateTime.tryParse(iso);
    if (dt == null) return "";
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);

    if (diff.inDays < 1) {
      if (diff.inHours < 1) {
        if (diff.inMinutes < 1) return "just now";
        return "${diff.inMinutes}m ago";
      }
      return "${diff.inHours}h ago";
    }
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    if (diff.inDays < 30) return "${(diff.inDays / 7).floor()}w ago";

    return "${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}";
  }

  Widget _buildCustomerAvatar(String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFB9C5DE),
      ),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          : const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final customer = (review["customer"] as Map?)?.cast<String, dynamic>();
    final name = (customer?["fullName"] ?? "").toString().trim();
    final image = (customer?["image"] ?? "").toString();
    final rating = (review["rating"] as num?)?.toDouble() ?? 0.0;
    final comment = (review["comment"] ?? "").toString().trim();
    final createdAt = review["createdAt"]?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCustomerAvatar(image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? "Customer" : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(children: _buildStars(rating, size: 15)),
                  ],
                ),
              ),
              Text(
                _formatDate(createdAt),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: _navyDark,
      padding: EdgeInsets.fromLTRB(20, topPadding + 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Feedbacks",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.avgRating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Row(children: _buildStars(widget.avgRating, size: 20)),
              const SizedBox(width: 10),
              Text(
                "(${widget.ratingCount} ${widget.ratingCount == 1 ? "review" : "reviews"})",
                style: GoogleFonts.inter(
                  color: const Color(0xFFB4D2FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator(color: _navyMid)),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFE24B4A),
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF52607A)),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _loadReviews,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navyMid,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.reviews_outlined,
                  size: 56,
                  color: Color(0xFFB4BCC9),
                ),
                const SizedBox(height: 12),
                Text(
                  "No feedback yet",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF52607A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Reviews from your customers will show up here.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        color: _navyMid,
        backgroundColor: Colors.white,
        onRefresh: _loadReviews,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          itemCount: _reviews.length,
          itemBuilder: (context, index) => _buildReviewCard(_reviews[index]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgLight,
      child: Column(
        children: [
          _buildSummaryHeader(),
          _buildBody(),
        ],
      ),
    );
  }
}
