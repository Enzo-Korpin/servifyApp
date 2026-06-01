import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ui/app_notify.dart';
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

  bool get _hasCoordinates => request.coordinates.length >= 2;

  Future<void> _openGoogleMaps(BuildContext context) async {
    if (!_hasCoordinates) {
      AppNotify.info(context, "No location is available for this request.");
      return;
    }

    // MongoDB coordinates are [lng, lat]
    final lng = request.coordinates[0];
    final lat = request.coordinates[1];

    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      AppNotify.error(context, "We couldn't open Google Maps.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);
    final status = request.status.toLowerCase();

    final hasCustomerImage =
        request.customerImage != null && request.customerImage!.isNotEmpty;

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
          // 1. Name + Status
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE9F2FF),
                backgroundImage:
                    hasCustomerImage ? NetworkImage(request.customerImage!) : null,
                child: hasCustomerImage
                    ? null
                    : const Icon(Icons.person, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.customerName.isNotEmpty
                          ? request.customerName
                          : "Customer",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Customer",
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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

          const SizedBox(height: 14),

          // 2. Description
          Text(
            "Description",
            style: GoogleFonts.instrumentSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.message.isNotEmpty
                ? request.message
                : "No description provided",
            style: GoogleFonts.instrumentSans(
              fontSize: 14,
              color: Colors.black87,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 12),

          // 3. Address
          Text(
            "Address",
            style: GoogleFonts.instrumentSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request.addressText.isNotEmpty
                      ? request.addressText
                      : "No address",
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4. Created date
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                "Created: ${_formatDate(request.createdAt)}",
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          if (status == "accepted" && request.acceptedAt != null)
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

          if (status == "rejected" && request.rejectedAt != null)
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

          if (request.rejectReason != null &&
              request.rejectReason!.trim().isNotEmpty)
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

          if (status == "cancelled" && request.cancelledAt != null)
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

          if (request.cancelReason != null &&
              request.cancelReason!.trim().isNotEmpty)
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

          // 5. Google Maps button ONLY in pending
          if ((status == "pending" || status == "accepted") && _hasCoordinates) ...[
  const SizedBox(height: 14),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: isUpdating ? null : () => _openGoogleMaps(context),
      icon: const Icon(Icons.map_rounded),
      label: const Text("Open in Google Maps"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF1E40AF).withOpacity(0.45),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),
],

          // 6. Accept / Reject
          if (status == "pending") ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.green.withOpacity(0.45),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
                      disabledBackgroundColor: Colors.red.withOpacity(0.45),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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