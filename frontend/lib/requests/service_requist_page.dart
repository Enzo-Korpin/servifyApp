import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/ui/app_notify.dart';
import 'package:frontend/requests/Widgets/card_provider.dart';
import 'package:frontend/requests/confirmation.dart';
import '../Access/signup_screens/Picklocation.dart';

class ServiceRequestScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String? workerImage;
  final List<String> workerSkills;
  final double workerRating;

  const ServiceRequestScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    this.workerImage,
    this.workerSkills = const [],
    this.workerRating = 0,
  });

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final TextEditingController _addressController  = TextEditingController();
  final TextEditingController _descController     = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  double? selectedLat;
  double? selectedLng;
  bool _isSubmitting = false;

  // ── Theme colours ──
  static const _navyDark   = Color(0xFF0A1628);
  static const _navyMid    = Color(0xFF1E40AF);
  static const _bgLight    = Color(0xFFEFF6FF);
  static const _borderBlue = Color(0xFFDBEAFE);
  static const _textDark   = Color(0xFF1E293B);
  static const _textMuted  = Color(0xFF94A3B8);
  static const _hintColor  = Color(0xFFCBD5E1);

  @override
  void dispose() {
    _addressController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false, bool isInfo = true}) {
    if (!mounted) return;
    if (isError) {
      AppNotify.error(context, message);
    } else if (isInfo) {
      AppNotify.info(context, message);
    } else {
      AppNotify.success(context, message);
    }
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PickLocationScreen()),
    );

    if (result != null) {
      setState(() {
        selectedLat = (result["lat"] as num?)?.toDouble();
        selectedLng = (result["lng"] as num?)?.toDouble();
        final address = (result["address"] ?? "").toString().trim();
        _locationController.text = address.isNotEmpty
            ? address
            : "Lat: $selectedLat, Lng: $selectedLng";
      });
    }
  }

  Future<void> _submitRequest() async {
    final message     = _descController.text.trim();
    final addressText = _addressController.text.trim();

    if (message.isEmpty)     { _showMessage("Please describe the problem first."); return; }
    if (addressText.isEmpty) { _showMessage("Please enter an address."); return; }
    if (selectedLat == null || selectedLng == null) {
      _showMessage("Please pick a location on the map.");
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await DioClient.dio.post(
        '/api/service-requests/request',
        data: {
          "workerId":    widget.workerId,
          "message":     message,
          "addressText": addressText,
          "lng":         selectedLng,
          "lat":         selectedLat,
        },
        options: Options(
          sendTimeout:    const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final requestData = response.data["data"] ?? {};
      final requestId   = (requestData["_id"] ?? "").toString();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            workerId:        widget.workerId,
            workerName:      widget.workerName.isEmpty ? "Selected Worker" : widget.workerName,
            workerImageUrl:  (widget.workerImage ?? "").isNotEmpty ? widget.workerImage! : "",
            workerRating:    widget.workerRating,
            serviceName:     widget.workerSkills.isNotEmpty ? widget.workerSkills.join(", ") : "Service Request",
            serviceDateTime: "Request submitted successfully",
            requestId:       requestId,
          ),
        ),
      );
    } on DioException catch (e) {
      _showMessage(
        AppNotify.messageFromError(e, fallback: "We couldn't submit your request. Please try again."),
        isError: true,
      );
    } catch (e) {
      _showMessage(
        AppNotify.messageFromError(e, fallback: "We couldn't submit your request. Please try again."),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
          // ── Dark navy top bar ──
          _buildTopBar(context),

          // ── Scrollable form ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Worker card
                  Car_provider(
                    workerName:   widget.workerName,
                    workerSkills: widget.workerSkills,
                    workerRating: widget.workerRating,
                    workerImage:  widget.workerImage,
                  ),
                  const SizedBox(height: 20),

                  // Description
                  _sectionLabel("Description of Problem"),
                  const SizedBox(height: 7),
                  _inputField(
                    controller: _descController,
                    hint:       "Please provide as much detail as possible...",
                    maxLines:   5,
                  ),
                  const SizedBox(height: 16),

                  // Address
                  _sectionLabel("Address"),
                  const SizedBox(height: 7),
                  _inputField(
                    controller: _addressController,
                    hint:       "e.g. Zarqa, Russaifah",
                  ),
                  const SizedBox(height: 16),

                  // Location picker
                  _sectionLabel("Location"),
                  const SizedBox(height: 7),
                  _inputField(
                    controller: _locationController,
                    hint:       "Pick location from map",
                    readOnly:   true,
                    onTap:      _pickLocationFromMap,
                    suffixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: _navyMid,
                      size: 20,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Submit button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dark navy top bar ──
  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _navyDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              // Back button
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
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF63B3FF),
                    size: 22,
                  ),
                ),
              ),

              // Title
              Expanded(
                child: Text(
                  "Service Request",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              // Spacer to balance back button
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section label ──
  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Styled input field ──
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines       = 1,
    TextInputType? keyboardType,
    bool readOnly      = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller:   controller,
      maxLines:     maxLines,
      keyboardType: keyboardType,
      readOnly:     readOnly,
      onTap:        onTap,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: _textDark,
      ),
      decoration: InputDecoration(
        hintText:    hint,
        suffixIcon:  suffixIcon,
        hintStyle:   GoogleFonts.inter(fontSize: 13, color: _hintColor),
        filled:      true,
        fillColor:   Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderBlue, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _navyMid, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderBlue, width: 1.5),
        ),
      ),
    );
  }

  // ── Submit button ──
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor:         _navyMid,
          disabledBackgroundColor: _navyMid.withOpacity(0.5),
          elevation:    0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                "Submit Request",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}