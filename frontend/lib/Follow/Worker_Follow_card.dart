import 'package:flutter/material.dart';

class FollowedWorkerCard extends StatelessWidget {
  final String name;
  final String profession;
  final double distanceKm;
  final double rating;
  final String? imageUrl;
  final VoidCallback? onView;
  final VoidCallback? onUnfollow;

  const FollowedWorkerCard({
    super.key,
    required this.name,
    required this.profession,
    required this.distanceKm,
    required this.rating,
    this.imageUrl,
    this.onView,
    this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFFF6F7FB);
    const Color softText = Color(0xFF7B8190);
    const Color titleColor = Color(0xFF1F2430);
    const Color dangerColor = Color(0xFFE25555);
    const Color starColor = Color(0xFFF4B400);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onView,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFE4E8F1),
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                      ? NetworkImage(imageUrl!)
                      : null,
                  child: (imageUrl == null || imageUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.grey, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        distanceKm > 0
                            ? '$profession • ${distanceKm.toStringAsFixed(1)} km'
                            : profession,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: softText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: starColor, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Transform.translate(
                  offset: const Offset(0, -6),
                  child: OutlinedButton(
                    onPressed: onUnfollow,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dangerColor,
                      side: const BorderSide(color: dangerColor, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(90, 36),
                    ),
                    child: const Text(
                      'Unfollow',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}