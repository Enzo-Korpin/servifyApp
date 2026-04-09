import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/Access/login_screens/Login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/Access/signup_screens/verify_code_screen.dart';
import 'Picklocation.dart';

class StartUser extends StatefulWidget {
  const StartUser({super.key});

  @override
  State<StartUser> createState() => _StartUserState();
}

class _StartUserState extends State<StartUser> {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color _navy = Color(0xFF0D1B3E);
  static const Color _cyan = Color(0xFF1EBBF0);
  static const Color _cardBg = Color(0xFF162447);
  static const Color _inputBg = Color(0xFF1E2F55);
  static const Color _inputBorder = Color(0xFF2A3F6F);
  static const Color _textMuted = Color(0xFF8FA3C8);

  // ── Data ───────────────────────────────────────────────────────────────────
  final List<String> skills = [
    "Plumbing",
    "Electricity",
    "Painting",
    "Cleaning",
    "Carpentry",
  ];

  final TextEditingController addressController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final List<int> yearsList = List.generate(30, (i) => i + 1);
  final Set<String> selectedSkills = {};

  File? _selectedImage;
  bool _hidePassword = true;
  bool _isLoading = false;
  bool _skillsDropdownOpen = false;

  int? selectedYears;
  double? _lat;
  double? _lng;

  static const String baseUrl = 'http://10.0.2.2:5000';
  static const String signupEndpoint = '$baseUrl/api/auth/signup';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    addressController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;
      setState(() => _selectedImage = File(picked.path));
    } catch (e) {
      _showMessage('Failed to pick image: $e');
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PickLocationScreen()),
    );
    if (result != null && result is Map) {
      setState(() {
        addressController.text = (result["address"] ?? "").toString();
        _lat = (result["lat"] as num?)?.toDouble();
        _lng = (result["lng"] as num?)?.toDouble();
      });
    }
  }

  Future<void> _signUp() async {
    final fullName = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        _lat == null ||
        _lng == null ||
        selectedSkills.isEmpty ||
        selectedYears == null) {
      _showMessage('Please fill all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? base64Image;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
      }

      final payload = {
        "fullName": fullName,
        "email": email,
        "password": password,
        "role": "worker",
        "lat": _lat,
        "lng": _lng,
        "skills": selectedSkills
            .map((skill) => skill.toLowerCase().trim())
            .toList(),
        "yearsOfExperience": selectedYears,
        if (base64Image != null) "image": base64Image,
      };

      final response = await http.post(
        Uri.parse(signupEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      Map<String, dynamic> data = {};
      try {
        if (response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) data = decoded;
        }
      } catch (_) {}

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        _showMessage('Registration successful! Check your email.');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => VerifyCodeScreen(role: "worker", email: email),
          ),
        );
      } else {
        final message = data['message']?.toString() ??
            data['error']?.toString() ??
            'Signup failed';
        _showMessage(message);
      }
    } catch (e) {
      _showMessage('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Shared input decoration ────────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String labelText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: _textMuted, fontSize: 14),
      filled: true,
      fillColor: _inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cyan, width: 1.5),
      ),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: _textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      );

  // ── Multi-select skills dropdown ───────────────────────────────────────────
  Widget _buildSkillsDropdown() {
    final label = selectedSkills.isEmpty
        ? 'Select skills'
        : selectedSkills.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trigger button
        GestureDetector(
          onTap: () => setState(() => _skillsDropdownOpen = !_skillsDropdownOpen),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _skillsDropdownOpen ? _cyan : _inputBorder,
                width: _skillsDropdownOpen ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.build_outlined, color: _textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: selectedSkills.isEmpty ? _textMuted : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  _skillsDropdownOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _textMuted,
                ),
              ],
            ),
          ),
        ),

        // Dropdown panel
        if (_skillsDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cyan, width: 1.5),
            ),
            child: Column(
              children: skills.asMap().entries.map((entry) {
                final skill = entry.value;
                final isLast = entry.key == skills.length - 1;
                final selected = selectedSkills.contains(skill);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        selectedSkills.remove(skill);
                      } else {
                        selectedSkills.add(skill);
                      }
                    });
                  },
                  borderRadius: BorderRadius.vertical(
                    top: entry.key == 0
                        ? const Radius.circular(14)
                        : Radius.zero,
                    bottom: isLast ? const Radius.circular(14) : Radius.zero,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: selected
                          ? _cyan.withOpacity(0.12)
                          : Colors.transparent,
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: _inputBorder,
                                width: 0.8,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        // Custom checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: selected ? _cyan : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: selected ? _cyan : _textMuted,
                              width: 1.5,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          skill,
                          style: GoogleFonts.inter(
                            color: selected ? Colors.white : _textMuted,
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Selected chips
        if (selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: selectedSkills.map((skill) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cyan.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill,
                      style: GoogleFonts.inter(
                        color: _cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => selectedSkills.remove(skill)),
                      child: const Icon(Icons.close,
                          size: 13, color: _cyan),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        // Close dropdown when tapping outside
        onTap: () {
          if (_skillsDropdownOpen) {
            setState(() => _skillsDropdownOpen = false);
          }
        },
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Header ────────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      "Create Worker Account",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Join Servify and start earning today",
                      style: GoogleFonts.inter(
                        color: _textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Avatar ────────────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _cyan, width: 2.5),
                        color: _inputBg,
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : const Icon(Icons.person,
                                size: 54, color: _textMuted),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _cyan,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: _navy, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Form card ─────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _inputBorder),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    _label("FULL NAME"),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: "Enter your full name",
                        prefixIcon: const Icon(Icons.person_outline,
                            color: _textMuted, size: 18),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Email
                    _label("EMAIL"),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: "Enter your email",
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: _textMuted, size: 18),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Password
                    _label("PASSWORD"),
                    TextField(
                      controller: passwordController,
                      obscureText: _hidePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: "Enter your password",
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: _textMuted, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _textMuted,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Service Address
                    _label("SERVICE ADDRESS"),
                    TextField(
                      controller: addressController,
                      readOnly: true,
                      onTap: _pickLocation,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: "Select from map",
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            color: _textMuted, size: 18),
                        suffixIcon: const Icon(Icons.map_outlined,
                            color: _cyan, size: 18),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Skills (multi-select dropdown)
                    _label("PRIMARY SKILLS"),
                    _buildSkillsDropdown(),

                    const SizedBox(height: 18),

                    // Experience
                    _label("YEARS OF EXPERIENCE"),
                    DropdownButtonFormField<int>(
                      value: selectedYears,
                      dropdownColor: _inputBg,
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: _textMuted,
                      decoration: _inputDecoration(
                        labelText: "Select years (1 – 30)",
                        prefixIcon: const Icon(Icons.workspace_premium_outlined,
                            color: _textMuted, size: 18),
                      ),
                      items: yearsList
                          .map((y) => DropdownMenuItem<int>(
                                value: y,
                                child: Text(
                                  "$y ${y == 1 ? 'year' : 'years'}",
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedYears = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Sign Up button ─────────────────────────────────────────────
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          "Sign Up",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Footer ────────────────────────────────────────────────────
              Center(
                child: Text(
                  "By signing up you agree to Servify's\nTerms of Service and Privacy Policy",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _textMuted,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: GoogleFonts.inter(
                        color: _textMuted, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (ctx) => const LoginScreen()),
                    ),
                    child: Text(
                      "Sign in",
                      style: GoogleFonts.inter(
                        color: _cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}