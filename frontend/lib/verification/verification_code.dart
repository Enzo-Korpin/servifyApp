import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationCodeScreen extends StatefulWidget {
  /// The email/phone the code was sent to — shown as a hint.
  final String sentTo;

  const VerificationCodeScreen({
    super.key,
    this.sentTo = '',
  });

  @override
  State<VerificationCodeScreen> createState() =>
      _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen>
    with SingleTickerProviderStateMixin {
  // 6 separate controllers + focus nodes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

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
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)  f.dispose();
    super.dispose();
  }

  // Returns the full 6-digit code as a string
  String get _fullCode =>
      _controllers.map((c) => c.text).join();

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor:
            isError ? const Color(0xFFE24B4A) : _navyMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onVerifyPressed() {
    final code = _fullCode;
    if (code.length < 6) {
      _showSnack("Please enter the complete 6-digit code");
      return;
    }
    // ── Hook your verification logic here ──
    _showSnack("Code verified: $code", isError: false);
  }

  void _onResendPressed() {
    // ── Hook your resend logic here ──
    _showSnack("Verification code resent", isError: false);
  }

  // ── Single OTP digit field ──
  Widget _buildDigitField(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller:    _controllers[index],
        focusNode:     _focusNodes[index],
        textAlign:     TextAlign.center,
        keyboardType:  TextInputType.number,
        maxLength:     1,
        style: GoogleFonts.inter(
          fontSize:   22,
          fontWeight: FontWeight.w700,
          color:      _textDark,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',           // hides the "0/1" counter
          filled:      true,
          fillColor:   Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _controllers[index].text.isNotEmpty
                  ? _navyMid
                  : _borderBlue,
              width: _controllers[index].text.isNotEmpty ? 2 : 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: _navyMid, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: _borderBlue, width: 1.5),
          ),
        ),
        onChanged: (value) {
          setState(() {}); // rebuild to update border colours

          if (value.isNotEmpty && index < 5) {
            // Move focus to next field
            FocusScope.of(context)
                .requestFocus(_focusNodes[index + 1]);
          }
          if (value.isEmpty && index > 0) {
            // Move focus back on delete
            FocusScope.of(context)
                .requestFocus(_focusNodes[index - 1]);
          }
          // Auto-submit when all 6 digits are entered
          if (_fullCode.length == 6) {
            FocusScope.of(context).unfocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
          // ── Dark navy header: Servify logo + name ──
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
                    padding:
                        const EdgeInsets.fromLTRB(20, 12, 20, 36),
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
                                color: const Color(0xFF63B3FF)
                                    .withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF63B3FF)
                                      .withOpacity(0.2),
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
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: const Color(0xFF63B3FF)
                                .withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF63B3FF)
                                  .withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.handyman_outlined,
                            color: Color(0xFF63B3FF),
                            size: 30,
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

                        const SizedBox(height: 5),

                        Text(
                          "Verification Code",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFB4D2FF)
                                .withOpacity(0.55),
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
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    children: [
                      // Title + subtitle
                      Text(
                        "Enter the 6-digit code",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _textMuted,
                            height: 1.6,
                          ),
                          children: [
                            const TextSpan(
                                text: "We sent a verification code to\n"),
                            TextSpan(
                              text: widget.sentTo.isNotEmpty
                                  ? widget.sentTo
                                  : "your registered email",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _navyMid,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── 6 OTP digit fields ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (i) => _buildDigitField(i),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _onVerifyPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _navyMid,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            "Verify Code",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Resend row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive a code?  ",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: _onResendPressed,
                            child: Text(
                              "Resend",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _navyMid,
                              ),
                            ),
                          ),
                        ],
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