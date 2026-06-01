import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/Access/google_flow/google_auth_service.dart';
import 'package:frontend/Access/google_flow/google_worker_profile_page.dart';
import 'package:frontend/Access/verification/forgot_password.dart';
import 'package:frontend/Home_pages/home_worker.dart';
import 'package:frontend/Home_pages/smart_worker_map_page.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/ui/app_notify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/network/socket_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
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

  void _goToHomeByRole({
    required String? currentRole,
    required String? nextAction,
  }) {
    if (!mounted) return;

    if (nextAction == "COMPLETE_WORKER_PROFILE") {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GoogleWorkerProfilePage()),
        (route) => false,
      );
      return;
    }

    if (currentRole == "customer") {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SmartWorkerMapPage()),
        (route) => false,
      );
    } else if (currentRole == "worker") {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeWorker()),
        (route) => false,
      );
    } else {
      _showMessage("Unknown role");
    }
  }

Future<void> _login() async {
  final email = emailCtrl.text.trim();
  final password = passwordCtrl.text.trim();

  if (email.isEmpty || password.isEmpty) {
    _showMessage("Please enter email and password");
    return;
  }

  setState(() => _isLoading = true);

  try {

    SocketClient.instance.disconnect();

    await DioClient.resetCookieJarCompletely();

    final response = await DioClient.dio.post(
      "/api/auth/login",
      data: {
        "email": email,
        "password": password,
      },
    );

    final data = response.data as Map<String, dynamic>?;

    if (response.statusCode == 200 &&
        data != null &&
        data["success"] == true) {
      bool tokenReady = false;

      for (int i = 0; i < 10; i++) {
        final cookies = await DioClient.cookieJar.loadForRequest(
          Uri.parse(DioClient.baseUrl),
        );

        Cookie? tokenCookie;

        for (final cookie in cookies) {
          if (cookie.name == 'token' && cookie.value.trim().isNotEmpty) {
            tokenCookie = cookie;
            break;
          }
        }

        if (tokenCookie != null) {

          tokenReady = true;
          break;
        }

        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (!tokenReady) {
        throw Exception("Token cookie was not persisted after login");
      }

      await SocketClient.instance.reconnectFresh();

      final userData = data["data"] as Map<String, dynamic>?;
      final currentRole = userData?["currentRole"] ?? userData?["role"];

      _showMessage("You're signed in.", isError: false);

      _goToHomeByRole(
        currentRole: currentRole?.toString(),
        nextAction: null,
      );
    } else {
      final message =
          data?["error"]?["message"]?.toString() ??
          data?["message"]?.toString() ??
          "We couldn't sign you in. Please try again.";

      _showMessage(message);
    }
  } on DioException catch (e) {
    _showMessage(
      AppNotify.messageFromError(
        e,
        fallback: "We couldn't sign you in. Please try again.",
      ),
    );
  } catch (e) {
    _showMessage("We couldn't sign you in. Please try again.");
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _googleLogin() async {
    setState(() => _isGoogleLoading = true);

    try {
      final response = await GoogleAuthService.loginWithGoogle();

      final data = response.data as Map<String, dynamic>?;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data != null &&
          data["success"] == true) {
        final responseData = data["data"] as Map<String, dynamic>?;
        final userData = responseData?["user"] as Map<String, dynamic>?;

        final currentRole = userData?["currentRole"] ?? userData?["role"];
        final nextAction = responseData?["nextAction"];

        _showMessage("You're signed in with Google.", isError: false);

        _goToHomeByRole(
          currentRole: currentRole?.toString(),
          nextAction: nextAction?.toString(),
        );
      } else {
        _showMessage("We couldn't sign you in with Google. Please try again.");
      }
    } on DioException catch (e) {
      final code = e.response?.data?["error"]?["code"]?.toString();

      if (code == "LOCATION_REQUIRED") {
        _showMessage(
          "This Google account isn't registered yet. Please sign up first.",
        );
      } else {
        _showMessage(
          AppNotify.messageFromError(
            e,
            fallback: "We couldn't sign you in with Google. Please try again.",
          ),
        );
      }
    } catch (e) {
      _showMessage("We couldn't sign you in with Google. Please try again.");
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(
              prefixIcon,
              size: 18,
              color: const Color(0xFF94A3B8),
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFDBEAFE),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF1E40AF),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _googleButton() {
    return InkWell(
      onTap: _isGoogleLoading ? null : _googleLogin,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 64,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFDBEAFE),
            width: 1.5,
          ),
        ),
        child: Center(
          child: _isGoogleLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Color(0xFF1E40AF),
                  ),
                )
              : Image.asset(
                  "assets/google.png",
                  width: 70,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF0A1628),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                    child: Column(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: const Color(0xFF63B3FF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF63B3FF).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.handyman_outlined,
                            color: Color(0xFF63B3FF),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Welcome back",
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Sign in to your Servify account",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFB4D2FF).withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    label: "Email",
                    hint: "Enter your email",
                    controller: emailCtrl,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  _buildField(
                    label: "Password",
                    hint: "Enter your password",
                    controller: passwordCtrl,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: _hidePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () {
                        setState(() => _hidePassword = !_hidePassword);
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Forgot password?",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        disabledBackgroundColor:
                            const Color(0xFF1E40AF).withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
                              "Sign in",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFDBEAFE),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "or continue with",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: Color(0xFFDBEAFE),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _googleButton(),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Don't have an account?  ",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            "Sign up",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
