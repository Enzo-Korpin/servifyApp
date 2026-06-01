import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/ui/app_notify.dart';
import 'package:frontend/Access/login_screens/Login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _newPasswordCtrl     = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  

  // Single toggle — controls BOTH fields at the same time
  bool _isLoading = false;
  bool _hidePasswords = true;

  // ── Entrance animation ──
  late AnimationController _animController;
  late Animation<double>   _headerFade;
  late Animation<Offset>   _headerSlide;
  late Animation<double>   _formFade;
  late Animation<Offset>   _formSlide;

  // ── Theme colours ──
  static const _navyDark   = Color(0xFF0A1628);
  static const _navyMid    = Color(0xFF1E40AF);
  static const _bgLight    = Color(0xFFEFF6FF);
  static const _borderBlue = Color(0xFFDBEAFE);
  static const _textDark   = Color(0xFF1E293B);
  static const _textMuted  = Color(0xFF94A3B8);
  static const _hintColor  = Color(0xFFCBD5E1);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    if (isError) {
      AppNotify.error(context, message);
    } else {
      AppNotify.success(context, message);
    }
  }

 Future<void> _onResetPressed() async {
  final newPassword = _newPasswordCtrl.text.trim();
  final confirmPassword = _confirmPasswordCtrl.text.trim();

  if (newPassword.isEmpty) {
    _showSnack("Please enter a new password");
    return;
  }

  if (newPassword.length < 6) {
    _showSnack("Password must be at least 6 characters");
    return;
  }

  if (newPassword != confirmPassword) {
    _showSnack("Passwords do not match");
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await DioClient.dio.post(
      '/api/auth/reset-password',
      data: {
        "email": widget.email,
        "code": widget.code,
        "newPassword": newPassword,
        "confirmPassword": confirmPassword,
      },
    );


    _showSnack("Your password has been reset.", isError: false);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  } on DioException catch (e) {
    _showSnack(
      AppNotify.messageFromError(
        e,
        fallback: "We couldn't reset your password. Please try again.",
      ),
    );
  } catch (e) {
    _showSnack("We couldn't reset your password. Please try again.");
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  // ── Reusable labeled password field ──
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showEyeIcon,
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
          controller:  controller,
          obscureText: _hidePasswords,
          style: GoogleFonts.inter(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            hintStyle: GoogleFonts.inter(fontSize: 13, color: _hintColor),
            filled:    true,
            fillColor: Colors.white,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: _textMuted,
            ),
            // Eye icon only on New Password field —
            // but it toggles obscureText on BOTH fields via _hidePasswords
            suffixIcon: showEyeIcon
                ? IconButton(
                    icon: Icon(
                      _hidePasswords
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: _textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _hidePasswords = !_hidePasswords),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
          // ── Dark navy header ──
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Container(
                width: double.infinity,
                color: _navyDark,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                    child: Column(
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF63B3FF).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF63B3FF).withOpacity(0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                color: Color(0xFF63B3FF),
                                size: 22,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Servify icon mark
                        Container(
                          width: 62,
                          height: 62,
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
                            size: 28,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // App name
                        Text(
                          "Servify",
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Reset your password",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFB4D2FF).withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Form section ──
          Expanded(
            child: FadeTransition(
              opacity: _formFade,
              child: SlideTransition(
                position: _formSlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Password — has the eye icon
                      _buildPasswordField(
                        controller:  _newPasswordCtrl,
                        label:       "New Password",
                        showEyeIcon: true,
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password — no eye icon (synced via shared toggle)
                      _buildPasswordField(
                        controller:  _confirmPasswordCtrl,
                        label:       "Confirm Password",
                        showEyeIcon: false,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Tap the eye icon to show or hide both passwords.",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _textMuted,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Reset Password button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onResetPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _navyMid,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            "Reset Password",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Back to sign in
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Remember your password?  ",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: _textMuted,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text(
                                "Sign in",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _navyMid,
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
            ),
          ),
        ],
      ),
    );
  }
}
