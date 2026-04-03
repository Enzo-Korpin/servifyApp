import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/Access/login_screens/Login_Screen.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Picklocation.dart';
import 'verify_code_screen.dart';

class SignupUser extends StatefulWidget {
  const SignupUser({super.key});

  @override
  State<SignupUser> createState() => _SignupUserState();
}

class _SignupUserState extends State<SignupUser> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;

  double? selectedLat;
  double? selectedLng;

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

  Future<void> _pickAddressFromMap() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PickLocationScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        addressController.text = result["address"] ?? "Selected Location";
        selectedLat = (result["lat"] as num?)?.toDouble();
        selectedLng = (result["lng"] as num?)?.toDouble();
      });

      debugPrint("Selected address: ${addressController.text}");
      debugPrint("Selected lat: $selectedLat");
      debugPrint("Selected lng: $selectedLng");
    }
  }

  Future<void> _submit() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final address = addressController.text.trim();

    if (fullName.isEmpty) {
      _showMessage("Full name is required");
      return;
    }

    if (email.isEmpty) {
      _showMessage("Email is required");
      return;
    }

    if (password.isEmpty) {
      _showMessage("Password is required");
      return;
    }

    if (selectedLat == null || selectedLng == null) {
      _showMessage("Please select your address from the map");
      return;
    }

    final payload = {
      "fullName": fullName,
      "email": email,
      "password": password,
      "role": "customer",
      "lat": selectedLat,
      "lng": selectedLng,
    };

    debugPrint("========== CUSTOMER SIGNUP PAYLOAD ==========");
    payload.forEach((key, value) {
      debugPrint("$key: $value");
    });
    debugPrint("============================================");

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await DioClient.dio.post(
        '/api/auth/signup',
        data: payload,
      );

      debugPrint("CUSTOMER SIGNUP STATUS: ${response.statusCode}");
      debugPrint("CUSTOMER SIGNUP BODY: ${response.data}");

      if (response.statusCode == 202) {
        if (!mounted) return;

        _showMessage("Registration successful! Check your email.");

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyCodeScreen(
              role: "customer",
              email: email,
            ),
          ),
        );
      } else {
        _showMessage("Signup failed");
      }
    } on DioException catch (e) {
      debugPrint("CUSTOMER SIGNUP ERROR: ${e.response?.data}");

      final message =
          e.response?.data?["message"]?.toString() ??
          e.response?.data?["error"]?.toString() ??
          "Signup failed";

      _showMessage(message);
    } catch (e) {
      _showMessage("Signup failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'User Registration',
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
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
          child: Column(
            children: [
              Center(
                child: Text(
                  "Create an account",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Opacity(
                  opacity: .52,
                  child: Text(
                    textAlign: TextAlign.center,
                    "Find trusted Professional for your home",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "FullName",
                          style: TextStyle(fontSize: 16),
                        ),
                        TextField(
                          controller: fullNameController,
                          decoration: _inputDecoration(
                            labelText: "Enter your Full Name",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Email",
                          style: TextStyle(fontSize: 16),
                        ),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            labelText: "Enter your Email",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Password",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: passwordController,
                          obscureText: _hidePassword,
                          decoration: _inputDecoration(
                            labelText: "Enter your Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _hidePassword = !_hidePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Address",
                          style: TextStyle(fontSize: 16),
                        ),
                        TextField(
                          controller: addressController,
                          readOnly: true,
                          onTap: _pickAddressFromMap,
                          decoration: _inputDecoration(
                            labelText: "Select your address from map",
                            suffixIcon: const Icon(Icons.location_on),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
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
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
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
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "By signing up you agree to Servify's Terms of Service and Privacy Policy",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.instrumentSans(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color.fromARGB(255, 46, 160, 254),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}