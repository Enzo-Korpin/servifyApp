import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/Access/google_flow/google_auth_service.dart';
import 'package:frontend/Access/login_screens/Login_Screen.dart';
import 'package:frontend/Home_pages/smart_worker_map_page.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/ui/app_notify.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Picklocation.dart';
import 'verify_code_screen.dart';

class SignupUser extends StatefulWidget {
  const SignupUser({super.key});

  @override
  State<SignupUser> createState() => _SignupUserState();
}

class _SignupUserState extends State<SignupUser>
    with SingleTickerProviderStateMixin {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;

  double? selectedLat;
  double? selectedLng;

  late final AnimationController _cardAnimationController;
  late final Animation<Offset> _cardSlideAnimation;
  late final Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.35, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    addressController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF8B97B3),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: const Color(0xFF182B57),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF223766),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2FC8F3),
          width: 1.5,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF223766),
          width: 1.2,
        ),
      ),
    );
  }

  Widget _buildField({
    required String title,
    required TextEditingController controller,
    required String hintText,
    bool obscure = false,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF18B8F2),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            obscureText: obscure,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              hintText: hintText,
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    if (isError) {
      AppNotify.error(context, message);
    } else {
      AppNotify.success(context, message);
    }
  }

  Future<void> _pickAddressFromMap() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PickLocationScreen(),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        addressController.text =
            (result["address"] ?? "Selected Location").toString();
        selectedLat = (result["lat"] as num?)?.toDouble();
        selectedLng = (result["lng"] as num?)?.toDouble();
      });
    }
  }

  Future<void> _submit() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

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

    setState(() => _isLoading = true);

    try {
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
              role: "customer",
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
    if (selectedLat == null || selectedLng == null) {
      _showMessage("Please select your address from the map first");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await GoogleAuthService.signInWithGoogle(
        requestedRole: "customer",
        lat: selectedLat!,
        lng: selectedLng!,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SmartWorkerMapPage()),
          (route) => false,
        );
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

  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _googleSignup,
        icon: Image.asset("assets/google.png", width: 26),
        label: Text(
          "Sign up with Google",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF223766), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08152F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF142954),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                "Create an account",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Find trusted professionals for your home",
                style: GoogleFonts.inter(
                  color: const Color(0xFF97A6C6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              FadeTransition(
                opacity: _cardFadeAnimation,
                child: SlideTransition(
                  position: _cardSlideAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12254B),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF1D3765),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildField(
                          title: "Full Name",
                          controller: fullNameController,
                          hintText: "Enter your Full Name",
                        ),

                        const SizedBox(height: 18),

                        _buildField(
                          title: "Email",
                          controller: emailController,
                          hintText: "Enter your Email",
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 18),

                        _buildField(
                          title: "Password",
                          controller: passwordController,
                          hintText: "Enter your Password",
                          obscure: _hidePassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF8B97B3),
                              size: 22,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        _buildField(
                          title: "Address",
                          controller: addressController,
                          hintText: "Select your address from map",
                          readOnly: true,
                          onTap: _pickAddressFromMap,
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF8B97B3),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EC5F4),
                    disabledBackgroundColor:
                        const Color(0xFF2EC5F4).withOpacity(.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.6,
                          ),
                        )
                      : Text(
                          "Sign Up",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color: Color(0xFF223766),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "or",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7F90B5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(
                      color: Color(0xFF223766),
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _googleButton(),

              const SizedBox(height: 22),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text.rich(
                  TextSpan(
                    text: "By signing up you agree to Servify's ",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF7F90B5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: "Terms of Service",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF18B8F2),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: " and ",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF7F90B5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: "Privacy Policy",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF18B8F2),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 26),

              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF97A6C6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
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
                        "Login",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF18B8F2),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
    );
  }
}