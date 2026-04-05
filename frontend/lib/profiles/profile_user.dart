import 'package:flutter/material.dart';
import 'package:frontend/Access/login_screens/Login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  final profilimage = const AssetImage("assets/customer.png");
  String name = "Jane Doe";
  String phone = "+1 (555) 123-4567";
  String email = "jane.doe@email.com";
  String address = "123 Main St, Anytown, USA 12345";

  late AnimationController _animController;
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  // How many tiles you want to animate
  static const int _tileCount = 2;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    for (int i = 0; i < _tileCount; i++) {
      final start = (i * 0.25).clamp(0.0, 0.75);
      final end = (start + 0.55).clamp(0.0, 1.0);

      _slideAnimations.add(
        Tween<Offset>(
          begin: const Offset(-0.4, 0), // left to right
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _editprofile() {
    setState(() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFF9FAFB),
          title: const Text("are you sure you want to logout?"),
          content: const Text(
              "you will need to login again to access your account"),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(context);
                  },
                  child: const Text("cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute(
                          builder: (context) => LoginScreen()),
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            )
          ],
        ),
      );
    });
  }

  Widget _animatedTile(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: profilimage,
            ),

            const SizedBox(height: 12),

            Text(
              name,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _editprofile,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFFD8EEF7),
                ),
                child: Text(
                  "Edit Profile",
                  style: GoogleFonts.poppins(
                      color: Colors.blue, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Email tile — slides in first
            AnimatedBuilder(
              animation: _animController,
              builder: (context, _) => _animatedTile(
                0,
                _infoTile(Icons.email, "Email", email),
              ),
            ),

            const SizedBox(height: 15),

            // Address tile — slides in second
            AnimatedBuilder(
              animation: _animController,
              builder: (context, _) => _animatedTile(
                1,
                _infoTile(Icons.location_on, "Address", address),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _editprofile,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFFFAD7D7),
                ),
                child: Text(
                  "Logout",
                  style: GoogleFonts.poppins(
                      color: Colors.red, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}