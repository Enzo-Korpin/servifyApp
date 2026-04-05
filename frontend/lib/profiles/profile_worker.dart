import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/requests/service_requist_page.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileWorker extends StatefulWidget {
  final String workerId;

  const ProfileWorker({super.key, required this.workerId});

  @override
  State<ProfileWorker> createState() => _ProfileWorkerState();
}

class _ProfileWorkerState extends State<ProfileWorker>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;

  String fullName = "";
  String imageUrl = "";
  String bio = "";
  int yearsOfExperience = 0;
  double rate = 0;
  int ratingCount = 0;
  List<String> skills = [];

  // Animation for chat icon
  late AnimationController _chatIconController;
  late Animation<double> _chatIconScale;
  late Animation<double> _chatIconRotate;

  @override
  void initState() {
    super.initState();

    _chatIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Scale: pops in from 0 → 1.2 → 1.0
    _chatIconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_chatIconController);

    // Slight wiggle rotation: 0 → -0.15 → 0.15 → 0
    _chatIconRotate = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -0.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.15, end: 0.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.15, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_chatIconController);

    _loadWorker();
  }

  @override
  void dispose() {
    _chatIconController.dispose();
    super.dispose();
  }

  Future<void> _loadWorker() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DioClient.dio.get(
        '/api/worker/${widget.workerId}',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data["data"] ?? {};
      final user = data["_id"] ?? {};

      if (!mounted) return;

      setState(() {
        fullName = (user["fullName"] ?? "").toString();
        imageUrl = (user["image"] ?? "").toString();
        bio = (data["bio"] ?? "").toString();
        yearsOfExperience = (data["yearsOfExperience"] ?? 0) as int;
        rate = ((data["rate"] ?? 0) as num).toDouble();
        ratingCount = (data["ratingCount"] ?? 0) as int;
        skills = List<String>.from(data["skills"] ?? []);
        _isLoading = false;
      });

      // Play chat icon animation once after data loads
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _chatIconController.forward();
      });
    } on DioException catch (e) {
      final message =
          e.response?.data?["message"]?.toString() ??
          e.response?.data?["error"]?.toString() ??
          "Failed to load worker profile";

      if (!mounted) return;
      setState(() {
        _error = message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load worker profile";
        _isLoading = false;
      });
    }
  }

  String get skillsText {
    if (skills.isEmpty) return "No skills added";
    return skills.map(_capitalize).join(", ");
  }

  String get aboutTitle {
    final firstName = fullName.trim().isEmpty
        ? "Worker"
        : fullName.trim().split(" ").first;
    return "About $firstName";
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  List<Widget> _buildStars(double rating) {
    final rounded = rating.round().clamp(0, 5);
    return List.generate(
      5,
      (index) => Icon(
        index < rounded ? Icons.star : Icons.star_border,
        color: Colors.orange,
      ),
    );
  }

  Widget _buildAvatar() {
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 65,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: NetworkImage(imageUrl),
      );
    }

    // Person icon instead of chat icon
    return CircleAvatar(
      radius: 65,
      backgroundColor: Colors.grey.shade400,
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  Widget _buildChatButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ECC71),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 3,
          shadowColor: const Color(0xFF2ECC71).withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated chat icon
            AnimatedBuilder(
              animation: _chatIconController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _chatIconRotate.value,
                  child: Transform.scale(
                    scale: _chatIconScale.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Chat",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 5,
            right: 24,
            left: 24,
            bottom: 12,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWorker,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 30, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Profile Worker",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(child: _buildAvatar()),
            const SizedBox(height: 20),
            Center(
              child: Text(
                fullName.isEmpty ? "Worker Name" : fullName,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Opacity(
                opacity: 0.60,
                child: Text(
                  skillsText,
                  style: GoogleFonts.inriaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Improved chat button with animated icon
            _buildChatButton(),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Experience",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "$yearsOfExperience Years",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Skills",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        skills.isEmpty
                            ? "No skills"
                            : skills.length.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            const Divider(thickness: 1),
            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aboutTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bio.trim().isEmpty ? "No bio added yet." : bio,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Customer Reviews",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  rate.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(children: _buildStars(rate)),
                const SizedBox(height: 5),
                Text(
                  "($ratingCount reviews)",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Request Service button — same color as before
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ServiceRequestScreen(
                        workerId: widget.workerId,
                        workerName: fullName,
                        workerImage: imageUrl,
                        workerSkills: skills,
                        workerRating: rate,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12BFFF),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Request Service",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F0F0),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
      ),
      body: _buildBody(),
    );
  }
}