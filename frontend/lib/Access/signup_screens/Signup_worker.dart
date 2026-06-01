import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/Access/google_flow/google_auth_service.dart';
import 'package:frontend/Access/google_flow/google_worker_profile_page.dart';
import 'package:frontend/Access/login_screens/Login_screen.dart';
import 'package:frontend/Access/signup_screens/verify_code_screen.dart';
import 'package:frontend/Home_pages/home_worker.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/ui/app_notify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'Picklocation.dart';

class StartUser extends StatefulWidget {
  const StartUser({super.key});

  @override
  State<StartUser> createState() => _StartUserState();
}

class _StartUserState extends State<StartUser> {
  static const Color _navy = Color(0xFF0D1B3E);
  static const Color _cyan = Color(0xFF1EBBF0);
  static const Color _cardBg = Color(0xFF162447);
  static const Color _inputBg = Color(0xFF1E2F55);
  static const Color _inputBorder = Color(0xFF2A3F6F);
  static const Color _textMuted = Color(0xFF8FA3C8);

  final List<String> skills = [
    "Plumbing",
    "Electrical",
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

  @override
  void dispose() {
    addressController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    if (isError) {
      AppNotify.error(context, message);
    } else {
      AppNotify.success(context, message);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
      });
    } catch (e) {
      _showMessage("We couldn't open that image. Please try another.");
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PickLocationScreen()),
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
      _showMessage("Please fill all required fields");
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
        "skills": selectedSkills.map((skill) {
          return skill.toLowerCase().trim();
        }).toList(),
        "yearsOfExperience": selectedYears,
        if (base64Image != null) "image": base64Image,
      };

      final response = await DioClient.dio.post(
        "/api/auth/signup",
        data: payload,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        if (!mounted) return;

        _showMessage(
          "Account created! Check your email for the code.",
          isError: false,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyCodeScreen(
              role: "worker",
              email: email,
            ),
          ),
        );
      } else {
        _showMessage("We couldn't create your account. Please try again.");
      }
    } on DioException catch (e) {
      _showMessage(
        AppNotify.messageFromError(
          e,
          fallback: "We couldn't create your account. Please try again.",
        ),
      );
    } catch (e) {
      _showMessage("We couldn't create your account. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignup() async {
    if (_lat == null || _lng == null) {
      _showMessage("Please select your service address first");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await GoogleAuthService.signInWithGoogle(
        requestedRole: "worker",
        lat: _lat!,
        lng: _lng!,
      );

      final data = response.data as Map<String, dynamic>;
      final nextAction = data["data"]?["nextAction"];

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        if (nextAction == "COMPLETE_WORKER_PROFILE") {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const GoogleWorkerProfilePage(),
            ),
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeWorker()),
            (route) => false,
          );
        }
      } else {
        _showMessage("We couldn't sign you up with Google. Please try again.");
      }
    } on DioException catch (e) {
      _showMessage(
        AppNotify.messageFromError(
          e,
          fallback: "We couldn't sign you up with Google. Please try again.",
        ),
      );
    } catch (e) {
      _showMessage("We couldn't sign you up with Google. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
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

  Widget _label(String text) {
    return Padding(
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
  }

  Widget _buildSkillsDropdown() {
    final label =
        selectedSkills.isEmpty ? "Select skills" : selectedSkills.join(", ");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _skillsDropdownOpen = !_skillsDropdownOpen);
          },
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? _cyan.withOpacity(0.12)
                          : Colors.transparent,
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(
                                color: _inputBorder,
                                width: 0.8,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
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
                              ? const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          skill,
                          style: GoogleFonts.inter(
                            color: selected ? Colors.white : _textMuted,
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        if (selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: selectedSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
                      onTap: () {
                        setState(() => selectedSkills.remove(skill));
                      },
                      child: const Icon(Icons.close, size: 13, color: _cyan),
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

  Widget _googleButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _googleSignup,
        icon: Image.asset("assets/google.png", width: 26),
        label: Text(
          "Sign up with Google",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _inputBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          if (_skillsDropdownOpen) {
            setState(() => _skillsDropdownOpen = false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

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
                            : const Icon(
                                Icons.person,
                                size: 54,
                                color: _textMuted,
                              ),
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
                            border: Border.all(color: _navy, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

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
                    _label("FULL NAME"),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: "Enter your full name",
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: _textMuted,
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _label("EMAIL"),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: "Enter your email",
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: _textMuted,
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _label("PASSWORD"),
                    TextField(
                      controller: passwordController,
                      obscureText: _hidePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: "Enter your password",
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: _textMuted,
                          size: 18,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() => _hidePassword = !_hidePassword);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _label("SERVICE ADDRESS"),
                    TextField(
                      controller: addressController,
                      readOnly: true,
                      onTap: _pickLocation,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: "Select from map",
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: _textMuted,
                          size: 18,
                        ),
                        suffixIcon: const Icon(
                          Icons.map_outlined,
                          color: _cyan,
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _label("PRIMARY SKILLS"),
                    _buildSkillsDropdown(),

                    const SizedBox(height: 18),

                    _label("YEARS OF EXPERIENCE"),
                    DropdownButtonFormField<int>(
                      value: selectedYears,
                      dropdownColor: _inputBg,
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: _textMuted,
                      decoration: _inputDecoration(
                        labelText: "Select years (1 – 30)",
                        prefixIcon: const Icon(
                          Icons.workspace_premium_outlined,
                          color: _textMuted,
                          size: 18,
                        ),
                      ),
                      items: yearsList.map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text(
                            "$y ${y == 1 ? 'year' : 'years'}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedYears = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

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
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
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

              const SizedBox(height: 14),

              Row(
                children: [
                  const Expanded(
                    child: Divider(color: _inputBorder, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "or",
                      style: GoogleFonts.inter(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: _inputBorder, thickness: 1),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _googleButton(),

              const SizedBox(height: 20),

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
                      color: _textMuted,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
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