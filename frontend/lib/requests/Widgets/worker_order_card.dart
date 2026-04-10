import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/service_request_model.dart';

class WorkerOrderCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isUpdating;

  const WorkerOrderCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
    this.isUpdating = false,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "cancelled":
        return Colors.grey;
      case "pending":
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case "accepted":
        return "ACCEPTED";
      case "rejected":
        return "REJECTED";
      case "cancelled":
        return "CANCELLED";
      case "pending":
      default:
        return "PENDING";
    }
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return "$y-$m-$d  $h:$min";
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE9F2FF),
                child: Icon(Icons.person, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  request.addressText.isNotEmpty
                      ? request.addressText
                      : "No address",
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(request.status),
                  style: GoogleFonts.instrumentSans(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.message.isNotEmpty ? request.message : "No message provided",
            style: GoogleFonts.instrumentSans(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Created: ${_formatDate(request.createdAt)}",
            style: GoogleFonts.instrumentSans(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),

          if (request.status == "accepted" && request.acceptedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Accepted at: ${_formatDate(request.acceptedAt!)}",
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  color: Colors.green[700],
                ),
              ),
            ),

          if (request.status == "rejected" && request.rejectedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Rejected at: ${_formatDate(request.rejectedAt!)}",
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  color: Colors.red[700],
                ),
              ),
            ),

          if (request.rejectReason != null && request.rejectReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Reject reason: ${request.rejectReason}",
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  color: Colors.red[700],
                ),
              ),
            ),

          if (request.status == "cancelled" && request.cancelledAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Cancelled at: ${_formatDate(request.cancelledAt!)}",
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),

          if (request.cancelReason != null && request.cancelReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Cancel reason: ${request.cancelReason}",
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
              ),
            ),

          if (request.status == "pending") ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Accept"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}