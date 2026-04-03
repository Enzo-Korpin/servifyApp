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

class _ProfileWorkerState extends State<ProfileWorker> {
  bool _isLoading = true;
  String? _error;

  String fullName = "";
  String imageUrl = "";
  String bio = "";
  int yearsOfExperience = 0;
  double rate = 0;
  int ratingCount = 0;
  List<String> skills = [];

  @override
  void initState() {
    super.initState();
    _loadWorker();
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

    return const CircleAvatar(
      radius: 65,
      backgroundColor: Colors.grey,
      child: Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
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
          padding: const EdgeInsets.all(24),
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

            SizedBox(
              width: double.infinity,
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        "Chat",
                        style: GoogleFonts.inriaSans(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

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
                        skills.isEmpty ? "No skills" : skills.length.toString(),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  rate.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: _buildStars(rate),
                ),
                const SizedBox(height: 5),
                Text(
                  "($ratingCount reviews)",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 25),

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
        elevation: 0,
        title: const Text(
          "Worker Profile",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
}