import 'package:flutter/material.dart';

class RequestCard extends StatelessWidget {
  final String title;
  final String name;
  final String date;
  final String status;
  final String imageUrl;

  const RequestCard({
    super.key,
    required this.title,
    required this.name,
    required this.date,
    required this.status,
    required this.imageUrl,
  });

  Color getStatusColor() {
    switch (status) {
      case "Accepted":
        return Colors.green.shade100;
      case "In Progress":
        return Colors.orange.shade100;
      case "Pending":
        return Colors.orange.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color getStatusTextColor() {
    switch (status) {
      case "Accepted":
        return Colors.green;
      case "In Progress":
        return Colors.orange;
      case "Pending":
        return Colors.deepOrange;
      case "Canceled":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundImage: NetworkImage(imageUrl)),
          const SizedBox(width: 12),

          // Text section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(name, style: TextStyle(color: Colors.grey.shade600)),
                Text(date, style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),

          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: getStatusColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: getStatusTextColor(), fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
