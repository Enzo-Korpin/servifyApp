import 'package:flutter/material.dart';

class Car_provider extends StatelessWidget {
  final String workerName;
  final List<String> workerSkills;
  final double workerRating;
  final String? workerImage;

  const Car_provider({
    super.key,
    required this.workerName,
    required this.workerSkills,
    required this.workerRating,
    this.workerImage,
  });

  String get _mainJob {
    if (workerSkills.isEmpty) return "Worker";

    final skill = workerSkills.first.toLowerCase().trim();

    switch (skill) {
      case "plumbing":
        return "Plumber";
      case "electricity":
      case "electrical":
        return "Electrician";
      case "painting":
        return "Painter";
      case "cleaning":
        return "Cleaner";
      case "carpentry":
        return "Carpenter";
      default:
        return skill.isEmpty
            ? "Worker"
            : skill[0].toUpperCase() + skill.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = workerImage != null && workerImage!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD0E8F0),
              border: Border.all(color: const Color(0xFF2DB8CC), width: 2),
            ),
            child: ClipOval(
              child: hasImage
                  ? Image.network(
                      workerImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 32,
                        color: Color(0xFF1EBBF0),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 32,
                      color: Color(0xFF1EBBF0),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workerName.isEmpty ? 'Selected Worker' : workerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '$_mainJob  ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A8A9A),
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFC107),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      workerRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A8A9A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pulsing green dot
          const _PulsingDot(),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scaleAnim = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnim = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: Opacity(
                  opacity: _opacityAnim.value,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34C759),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
          // Solid dot on top
          Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: Color(0xFF34C759),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}