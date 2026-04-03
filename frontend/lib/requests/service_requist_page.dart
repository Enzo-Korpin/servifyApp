import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/network/dio_client.dart';
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
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  double? selectedLat;
  double? selectedLng;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PickLocationScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        selectedLat = (result["lat"] as num?)?.toDouble();
        selectedLng = (result["lng"] as num?)?.toDouble();

        final address = (result["address"] ?? "").toString().trim();
        if (address.isNotEmpty) {
          _locationController.text = address;
        } else {
          _locationController.text = "Lat: $selectedLat, Lng: $selectedLng";
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    final message = _descController.text.trim();
    final addressText = _addressController.text.trim();

    if (message.isEmpty) {
      _showMessage("Please describe the problem");
      return;
    }

    if (addressText.isEmpty) {
      _showMessage("Please enter the address");
      return;
    }

    if (selectedLat == null || selectedLng == null) {
      _showMessage("Please pick location from map");
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await DioClient.dio.post(
        '/api/service-requests/request',
        data: {
          "workerId": widget.workerId,
          "message": message,
          "addressText": addressText,
          "lng": selectedLng,
          "lat": selectedLat,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final requestData = response.data["data"] ?? {};
      final requestId = (requestData["_id"] ?? "").toString();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            workerId: widget.workerId,
            workerName:
                widget.workerName.isEmpty ? "Selected Worker" : widget.workerName,
            workerImageUrl:
                (widget.workerImage ?? "").isNotEmpty ? widget.workerImage! : "",
            workerRating: widget.workerRating,
            serviceName: widget.workerSkills.isNotEmpty
                ? widget.workerSkills.join(", ")
                : "Service Request",
            serviceDateTime: "Request submitted successfully",
            requestId: requestId,
          ),
        ),
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?["message"]?.toString() ??
          e.response?.data?["error"]?.toString() ??
          "Failed to submit request";

      _showMessage(message);
    } catch (e) {
      _showMessage("Failed to submit request");
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F5),
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Car_provider(
                      workerName: widget.workerName,
                      workerSkills: widget.workerSkills,
                      workerRating: widget.workerRating,
                      workerImage: widget.workerImage,
                    ),
                    const SizedBox(height: 24),

                    const _SectionLabel(text: 'Description of Problem'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _descController,
                      hint: 'Please provide as much detail as possible...',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),

                    const _SectionLabel(text: 'Address'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _addressController,
                      hint: 'e.g. Zarqa, Russaifah',
                    ),
                    const SizedBox(height: 20),

                    const _SectionLabel(text: 'Location'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _locationController,
                      hint: 'Pick location from map',
                      readOnly: true,
                      onTap: _pickLocationFromMap,
                      suffixIcon: const Icon(
                        Icons.location_on,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _SubmitButton(
              isSubmitting: _isSubmitting,
              onPressed: _submitRequest,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(
              Icons.chevron_left,
              size: 28,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const Expanded(
            child: Text(
              'Service Request',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
        letterSpacing: -0.2,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffixIcon,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFFBBBBC8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF1EBBF0),
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2DB8CC), Color(0xFF1A9BB0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2DB8CC).withOpacity(0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1EBBF0),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}