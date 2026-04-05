import 'package:flutter/material.dart';
import 'package:frontend/Access/login_screens/Login_screen.dart';
import 'package:frontend/Access/signup_screens/Signup_user.dart';
import 'package:frontend/Access/signup_screens/Signup_worker.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectType extends StatefulWidget {
  const SelectType({super.key});

  @override
  State<SelectType> createState() => _SelectTypeState();
}

class _SelectTypeState extends State<SelectType>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _iRevealController;

  late final Animation<double> _hammerY;
  late final Animation<double> _hammerRotate;
  late final Animation<double> _hammerScale;
  late final Animation<double> _nailBounce;
  late final Animation<double> _sparkScale;
  late final Animation<double> _spark2Scale;

  // "i" reveal animations
  late final Animation<double> _iScale;
  late final Animation<double> _iFade;
  late final Animation<double> _iGlow;

  bool _showNail = true;
  bool _showI = false;

  static const double _restY = -60.0;
  static const double _restAngle = 0.0;

  @override
  void initState() {
    super.initState();

    // Main hammer animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // "i" reveal controller — plays after nail disappears
    _iRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // ── Hammer Y (vertical position) ──
    // Realistic: slow wind-up, fast strike, short bounce, smooth return
    _hammerY = TweenSequence<double>([
      // Wind-up: moves slightly UP first (like a real hammer swing)
      TweenSequenceItem(
        tween: Tween(begin: _restY, end: _restY - 18.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      // Fast swing DOWN
      TweenSequenceItem(
        tween: Tween(begin: _restY - 18.0, end: -10.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      // Strike impact
      TweenSequenceItem(
        tween: Tween(begin: -10.0, end: 18.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      // Quick rebound up
      TweenSequenceItem(
        tween: Tween(begin: 18.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      // Settle back down slightly
      TweenSequenceItem(
        tween: Tween(begin: -8.0, end: 2.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      // Float back to rest
      TweenSequenceItem(
        tween: Tween(begin: 2.0, end: _restY)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 32,
      ),
    ]).animate(_controller);

    // ── Hammer Rotation ──
    // Wind-up tilts back more, then swings forward through impact
    _hammerRotate = TweenSequence<double>([
      // Wind-up: rotate back (counter-clockwise)
      TweenSequenceItem(
        tween: Tween(begin: _restAngle, end: -0.55)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      // Swing forward fast
      TweenSequenceItem(
        tween: Tween(begin: -0.55, end: 0.05)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      // Impact rotation
      TweenSequenceItem(
        tween: Tween(begin: 0.05, end: 0.18)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      // Rebound rotation
      TweenSequenceItem(
        tween: Tween(begin: 0.18, end: -0.10)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      // Settle
      TweenSequenceItem(
        tween: Tween(begin: -0.10, end: 0.02)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      // Return to rest angle
      TweenSequenceItem(
        tween: Tween(begin: 0.02, end: _restAngle)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 32,
      ),
    ]).animate(_controller);

    // ── Hammer Scale (squish on impact) ──
    _hammerScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 53),
      // Squish slightly on impact
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      // Spring back
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 32),
    ]).animate(_controller);

    // ── Nail bounce ──
    _nailBounce = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 53),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 10.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 7,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 10.0, end: -3.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -3.0, end: 0.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 32,
      ),
    ]).animate(_controller);

    // ── Spark 1 (main burst) ──
    _sparkScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 52),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.5, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 12,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 28),
    ]).animate(_controller);

    // ── Spark 2 (secondary smaller spark) ──
    _spark2Scale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 29),
    ]).animate(_controller);

    // ── "i" reveal animations ──
    _iScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_iRevealController);

    _iFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iRevealController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _iGlow = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _iRevealController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showNail = false;
          _showI = true;
        });
        _iRevealController.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _iRevealController.dispose();
    super.dispose();
  }

  Widget _buildLetter(String char) {
    return Text(
      char,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 55,
        color: Colors.black,
        height: 1,
      ),
    );
  }

  Widget _buildIorNail() {
    // Beautiful "i" reveal with scale + glow
    if (_showI) {
      return AnimatedBuilder(
        animation: _iRevealController,
        builder: (context, child) {
          return Transform.scale(
            scale: _iScale.value,
            child: FadeTransition(
              opacity: _iFade,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow ring behind the letter
                  if (_iGlow.value > 0)
                    Opacity(
                      opacity: _iGlow.value,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromARGB(255, 65, 201, 242)
                              .withOpacity(0.35),
                        ),
                      ),
                    ),
                  _buildLetter("i"),
                ],
              ),
            ),
          );
        },
      );
    }

    // Nail (before animation completes)
    if (!_showNail) return _buildLetter("i");

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _nailBounce.value),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nail head
                Container(
                  width: 22,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8A9198), Color(0xFF59636F)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                // Nail shaft
                Container(
                  width: 5,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7A8490), Color(0xFF4A5260)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Nail tip
                ClipPath(
                  clipper: _NailTipClipper(),
                  child: Container(
                    width: 5,
                    height: 7,
                    color: const Color(0xFF4A5260),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    const hammerColor = Color.fromARGB(255, 65, 201, 242);

    return SizedBox(
      width: 320,
      height: 185,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // "Servify" text row
              Positioned(
                top: 100,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildLetter("S"),
                    _buildLetter("e"),
                    _buildLetter("r"),
                    _buildLetter("v"),
                    _buildIorNail(),
                    _buildLetter("f"),
                    _buildLetter("y"),
                  ],
                ),
              ),

              // Hammer with scale squish
              Positioned(
                top: 45 + _hammerY.value,
                left: 100,
                child: Transform.scale(
                  scale: _hammerScale.value,
                  child: Transform.rotate(
                    angle: _hammerRotate.value,
                    alignment: const Alignment(0.22, 0.86),
                    child: Image.asset(
                      "assets/loghummer.png",
                      width: 92,
                      height: 92,
                      color: hammerColor,
                      colorBlendMode: BlendMode.srcIn
                    ),
                  ),
                ),
              ),

              // Main spark burst
              if (_showNail)
                Positioned(
                  top: 90,
                  left: 155,
                  child: Transform.scale(
                    scale: _sparkScale.value,
                    child: Opacity(
                      opacity: _sparkScale.value.clamp(0.0, 1.0),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 22,
                        color: Colors.orange.shade400,
                      ),
                    ),
                  ),
                ),

              // Secondary spark (offset)
              if (_showNail)
                Positioned(
                  top: 100,
                  left: 172,
                  child: Transform.scale(
                    scale: _spark2Scale.value,
                    child: Opacity(
                      opacity: _spark2Scale.value.clamp(0.0, 1.0),
                      child: Icon(
                        Icons.star,
                        size: 11,
                        color: Colors.yellow.shade600,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 35),

              Center(child: _buildAnimatedLogo()),

              Center(
                child: Text(
                  "Find help,fast",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280).withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Image.asset(
                  "assets/logo.png",
                  width: 284,
                  height: 269,
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top: 1, left: 20, bottom: 7),
                child: Text(
                  "Choose You:",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => StartUser()),
                  );
                },
                icon: const Icon(Icons.handyman_outlined, size: 24),
                label: Text(
                  "Provide service",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: const Color.fromARGB(255, 65, 201, 242),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 9),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => SignupUser()),
                  );
                },
                icon:
                    const Icon(Icons.person, color: Colors.black, size: 24),
                label: Text(
                  "Need service",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: const Color(0xFFC9C9C9),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  "Have an account?",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: const Color(0xFF7A8A92),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Login",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 65, 201, 242),
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clipper for the pointed nail tip
class _NailTipClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_NailTipClipper oldClipper) => false;
}