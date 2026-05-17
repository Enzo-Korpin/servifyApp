import 'package:flutter/material.dart';
import 'package:frontend/profiles/profile_worker.dart';

class WorkerCard extends StatelessWidget {
  const WorkerCard({super.key, required this.worker});

  final Map<String, dynamic> worker;

  @override
  Widget build(BuildContext context) {
    final workerId = (worker["_id"] ?? "").toString();
    final image = (worker["image"] ?? "").toString().trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFE9EEF5),
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? const Icon(Icons.person, color: Colors.black45)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (worker["name"] ?? "").toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  "${worker["job"]} • ${worker["distance"]}",
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text("${worker["rating"]}"),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: workerId.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfileWorker(workerId: workerId),
                      ),
                    );
                  },
            icon: const Icon(Icons.chevron_right, size: 20),
            label: const Text(
              "View",
              style: TextStyle(color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }
}