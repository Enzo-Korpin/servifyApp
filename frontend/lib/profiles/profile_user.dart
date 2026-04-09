import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/services/account_switch_service.dart';
import '../Access/login_screens/Login_Screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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

  final FocusNode _nameFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  File? _pickedImageFile;

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
    _nameFocusNode.dispose();
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

    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nameFocusNode.requestFocus();
        nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: nameController.text.length,
        );
      });
    } else {
      _nameFocusNode.unfocus();
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return;

      setState(() {
        _pickedImageFile = File(file.path);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image selected successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to select image: $e")),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (file == null) return;

      setState(() {
        _pickedImageFile = File(file.path);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Picture taken successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to take picture: $e")),
      );
    }
  }

  Future<void> _showImageOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D4D8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Profile Photo",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF2F57F6),
                    ),
                  ),
                  title: Text(
                    "Take a picture",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _takePicture();
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF2F57F6),
                    ),
                  ),
                  title: Text(
                    "Choose from gallery",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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

      _nameFocusNode.unfocus();

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
          builder: (_) => const LoginScreen(),
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
    Widget avatarContent;

    if (_pickedImageFile != null) {
      avatarContent = ClipOval(
        child: Image.file(
          _pickedImageFile!,
          width: 110,
          height: 110,
          fit: BoxFit.cover,
        ),
      );
    } else if (imageUrl.isNotEmpty) {
      avatarContent = ClipOval(
        child: Image.network(
          imageUrl,
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 110,
              height: 110,
              color: const Color(0xFF95A7C9),
              child: const Icon(
                Icons.person_outline,
                size: 50,
                color: Colors.white,
              ),
            );
          },
        ),
      );
    } else {
      avatarContent = Container(
        width: 110,
        height: 110,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF95A7C9),
        ),
        child: const Icon(
          Icons.person_outline,
          size: 50,
          color: Colors.white,
        ),
      );
    }

    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF95A7C9),
            ),
            child: avatarContent,
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showImageOptions,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F57F6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0B1E4A),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
            borderRadius: BorderRadius.circular(16),
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

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF0F0F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7C93C9),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9AA3B2),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
      backgroundColor: const Color(0xFF0B1E4A),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF0B1E4A),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    Text(
                      "Profile",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildAvatar(),
                    const SizedBox(height: 14),
                    isEditing
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFDDE5FF),
                                width: 1.6,
                              ),
                            ),
                            child: TextField(
                              controller: nameController,
                              focusNode: _nameFocusNode,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              cursorColor: const Color(0xFF2F57F6),
                              decoration: InputDecoration(
                                hintText: "Full Name",
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.black38,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          )
                        : Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F7F8),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildSwitchAccountButton(),
                    if (authUser?.role == "worker") const SizedBox(height: 12),

                    _buildMainActionButton(
                      text: isEditing ? "Cancel" : "Edit Profile",
                      backgroundColor: const Color(0xFF2F57F6),
                      textColor: Colors.white,
                      onPressed: toggleEdit,
                    ),

                    const SizedBox(height: 14),

                    if (isEditing)
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF12BFFF),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "Save",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            "ACCOUNT INFO",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB4BBC7),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _infoTile(Icons.email_outlined, "Email", email),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildMainActionButton(
                      text: "Logout",
                      icon: Icons.logout_rounded,
                      backgroundColor: const Color(0xFFFFEAEA),
                      textColor: const Color(0xFFFF6B6B),
                      onPressed: () {
                        // logout logic later
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}