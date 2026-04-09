import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/services/account_switch_service.dart';
import '../Access/login_screens/Login_Screen.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool isEditing = false;
  bool isLoading = true;
  bool isSwitchingAccount = false;

  String name = "";
  String email = "";
  String imageUrl = "";

  AuthCheckUser? authUser;

  late TextEditingController nameController;
  late AccountSwitchService accountSwitchService;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    accountSwitchService = AccountSwitchService();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final results = await Future.wait([
        DioClient.dio.get("/api/customer/profile"),
        accountSwitchService.checkAuth(),
      ]);

      final profileResponse = results[0] as Response;
      final authCheckUser = results[1] as AuthCheckUser;

      final data = profileResponse.data["data"];

      setState(() {
        name = data["fullName"] ?? "";
        email = data["email"] ?? "";
        imageUrl = data["image"] ?? "";
        authUser = authCheckUser;
        nameController.text = name;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile")),
      );
    }
  }

  void toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty) return;

    try {
      final response = await DioClient.dio.put(
        "/api/customer/profile",
        data: {
          "fullName": nameController.text.trim(),
          "image": imageUrl,
        },
      );

      final data = response.data["data"];

      setState(() {
        name = data["fullName"];
        imageUrl = data["image"] ?? "";
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated")),
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?["message"]?.toString() ??
          e.response?.data?["error"]?.toString() ??
          "Update failed";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    }
  }

  Future<void> switchAccount() async {
    if (authUser == null) return;
    if (authUser!.role != "worker") return;

    final targetRole = accountSwitchService.getTargetRole(authUser!.currentRole);

    setState(() {
      isSwitchingAccount = true;
    });

    try {
      final newCurrentRole = await accountSwitchService.switchRole(targetRole);

      if (!mounted) return;

      setState(() {
        authUser = AuthCheckUser(
          id: authUser!.id,
          fullName: authUser!.fullName,
          email: authUser!.email,
          role: authUser!.role,
          currentRole: newCurrentRole,
          image: authUser!.image,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Switched to $newCurrentRole account")),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(), // or LoginScreen()
        ),
        (route) => false,
      );
    } on DioException catch (e) {
      final message =
          e.response?.data?["error"]?["message"]?.toString() ??
          e.response?.data?["message"]?.toString() ??
          "Switch account failed";

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Switch account failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSwitchingAccount = false;
        });
      }
    }
  }

  Widget _buildAvatar() {
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(imageUrl),
      );
    }

    return const CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, size: 50, color: Colors.white),
    );
  }

  Widget _buildSwitchAccountButton() {
    if (authUser == null) return const SizedBox.shrink();
    if (authUser!.role != "worker") return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: isSwitchingAccount ? null : switchAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F6FEB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: isSwitchingAccount
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.swap_horiz, color: Colors.white),
        label: Text(
          accountSwitchService.getButtonText(authUser!.currentRole),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
            _buildAvatar(),
            const SizedBox(height: 12),
            isEditing
                ? TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                    ),
                  )
                : Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 20),
            _buildSwitchAccountButton(),
            if (authUser?.role == "worker") const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: toggleEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8EEF7),
                ),
                child: Text(
                  isEditing ? "Cancel" : "Edit Profile",
                  style: GoogleFonts.poppins(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (isEditing)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12BFFF),
                  ),
                  child: const Text("Save"),
                ),
              ),
            const SizedBox(height: 20),
            _infoTile(Icons.email, "Email", email),
            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // logout logic later
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFAD7D7),
                ),
                child: Text(
                  "Logout",
                  style: GoogleFonts.poppins(
                    color: Colors.red,
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
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}