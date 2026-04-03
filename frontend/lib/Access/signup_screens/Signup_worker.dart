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

  int? selectedYears;
  double? _lat;
  double? _lng;

  static const String baseUrl = 'http://10.0.2.2:5000';
  static const String signupEndpoint = '$baseUrl/api/auth/signup';

  @override
  void dispose() {
    addressController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String labelText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      _showMessage('Failed to pick image: $e');
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PickLocationScreen(),
      ),
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

    setState(() {
      _isLoading = true;
    });

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
        "skills": selectedSkills.map((skill) => skill.toLowerCase().trim()).toList(),
        "yearsOfExperience": selectedYears,
        if (base64Image != null) "image": base64Image,
      };

      debugPrint("========== WORKER SIGNUP PAYLOAD ==========");
      debugPrint(jsonEncode(payload));
      debugPrint("===========================================");

      final response = await http.post(
        Uri.parse(signupEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RESPONSE BODY: ${response.body}");

      Map<String, dynamic> data = {};
      try {
        if (response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        }
      } catch (_) {}

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        _showMessage('Registration successful! Check your email.');

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => VerifyCodeScreen(
              role: "worker",
              email: email,
            ),
          ),
        );
      } else {
        final message =
            data['message']?.toString() ??
            data['error']?.toString() ??
            'Signup failed';
        _showMessage(message);
      }
    } catch (e) {
      _showMessage('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Worker Registration',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFF1EBBF0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 20,
            right: 20,
            left: 20,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Create Worker account",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 67,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1EBBF0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionLabel("FullName"),
              TextField(
                controller: nameController,
                decoration: _inputDecoration(
                  labelText: "Enter your Full Name",
                ),
              ),

              const SizedBox(height: 17),

              _buildSectionLabel("Email"),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  labelText: "Enter your Email",
                ),
              ),

              const SizedBox(height: 17),

              _buildSectionLabel("Password"),
              TextField(
                controller: passwordController,
                obscureText: _hidePassword,
                decoration: _inputDecoration(
                  labelText: "Enter your Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hidePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 17),

              _buildSectionLabel("Service Address"),
              TextField(
                controller: addressController,
                readOnly: true,
                onTap: _pickLocation,
                decoration: _inputDecoration(
                  labelText: "Select from map",
                  suffixIcon: const Icon(Icons.location_on),
                ),
              ),

              const SizedBox(height: 17),

              _buildSectionLabel("Primary Skills"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: skills.map((skill) {
                    final selected = selectedSkills.contains(skill);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(skill),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool? value) {
                        if (value == null) return;
                        setState(() {
                          if (value) {
                            selectedSkills.add(skill);
                          } else {
                            selectedSkills.remove(skill);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 17),

              _buildSectionLabel("Experience"),
              DropdownButtonFormField<int>(
                value: selectedYears,
                decoration: _inputDecoration(labelText: "Select years (1 - 30)"),
                items: yearsList
                    .map(
                      (y) => DropdownMenuItem<int>(
                        value: y,
                        child: Text("$y"),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedYears = val;
                  });
                },
              ),

              const SizedBox(height: 35),

              SizedBox(
                height: 60,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1EBBF0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Sign UP",
                          style: GoogleFonts.instrumentSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              Column(
                children: [
                  Text(
                    "By signing up you agree to Servify's Terms of Service and Privacy Policy",
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => const LoginScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Color(0xFF1EBBF0),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}