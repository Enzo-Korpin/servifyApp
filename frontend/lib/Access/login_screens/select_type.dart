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

class _SelectTypeState extends State<SelectType> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _iRevealController;
  late final AnimationController _serviceIconsController;

  late final Animation<double> _hammerY;
  late final Animation<double> _hammerRotate;
  late final Animation<double> _hammerScale;
  late final Animation<double> _nailBounce;
  late final Animation<double> _sparkScale;
  late final Animation<double> _spark2Scale;
  late final Animation<double> _iScale;
  late final Animation<double> _iFade;
  late final Animation<double> _iGlow;

  // Per-icon staggered animations
  late final List<Animation<double>> _iconScales;
  late final List<Animation<double>> _iconFades;

  bool _showNail = true;
  bool _showI = false;

  static const double _restY = -60.0;
  static const double _restAngle = 0.0;

  // Icons matching Image 2 style
  final List<Map<String, dynamic>> _services = [
    {'label': 'Plumbing', 'icon': Icons.home_outlined},
    {'label': 'Electrical', 'icon': Icons.bolt_outlined},
    {'label': 'Painting', 'icon': Icons.format_paint_outlined},
    {'label': 'Cleaning', 'icon': Icons.grid_view_rounded},
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _iRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _serviceIconsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // ── Hammer Y ──
    _hammerY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: _restY, end: _restY - 18.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: _restY - 18.0, end: -10.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -10.0, end: 18.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 18.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -8.0, end: 2.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 2.0, end: _restY)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 32,
      ),
    ]).animate(_controller);

    _hammerRotate = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: _restAngle, end: -0.55)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.55, end: 0.05)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.05, end: 0.18)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.18, end: -0.10)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.10, end: 0.02)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.02, end: _restAngle)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 32,
      ),
    ]).animate(_controller);

    _hammerScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 53),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 32),
    ]).animate(_controller);

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

    // ── Staggered icon pop-in (scale + fade, 150ms apart) ──
    _iconScales = List.generate(4, (i) {
      final start = i * 0.18;
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _serviceIconsController,
          curve: Interval(start, end, curve: Curves.elasticOut),
        ),
      );
    });

    _iconFades = List.generate(4, (i) {
      final start = i * 0.18;
      final end = (start + 0.28).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _serviceIconsController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    // Start hammer immediately; icons animate in 300ms after page loads
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _serviceIconsController.forward();
    });

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
    _serviceIconsController.dispose();
    super.dispose();
  }

  Widget _buildLetter(String char) {
    return Text(
      char,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 55,
        color: Colors.white,
        height: 1,
      ),
    );
  }

  Widget _buildIorNail() {
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
                  if (_iGlow.value > 0)
                    Opacity(
                      opacity: _iGlow.value,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF63B3FF).withOpacity(0.35),
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
    const hammerColor = Color(0xFF63B3FF);

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
                      fit: BoxFit.cover,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
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

  // Service tile with staggered pop-in animation
  Widget _buildServiceTile(int index) {
    final service = _services[index];
    return AnimatedBuilder(
      animation: _serviceIconsController,
      builder: (context, child) {
        return Opacity(
          opacity: _iconFades[index].value,
          child: Transform.scale(
            scale: _iconScales[index].value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFF112244),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF63B3FF).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    service['icon'] as IconData,
                    color: const Color(0xFF63B3FF),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  service['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFB4D2FF).withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: Column(
        children: [
          // ── Dark navy header ──
          Container(
            width: double.infinity,
            color: const Color(0xFF0A1628),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  children: [
                    _buildAnimatedLogo(),

                    Text(
                      "Connect · Book · Done",
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB4D2FF).withOpacity(0.75),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      "WHAT WE OFFER",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB4D2FF).withOpacity(0.5),
                        letterSpacing: 1.4,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Staggered icon row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        _services.length,
                        (i) => _buildServiceTile(i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Light bottom section ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "I WANT TO",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151).withOpacity(0.6),
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Provide service
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => StartUser()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.handyman_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Provide a service",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Earn by offering your skills",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFFB4D2FF)
                                        .withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white54,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Need service
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => SignupUser()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFDBEAFE),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF1E40AF),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Need a service",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Find trusted professionals",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Login
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Already have an account?  ",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Sign in",
                            style: GoogleFonts.inter(
                              fontSize: 14,
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