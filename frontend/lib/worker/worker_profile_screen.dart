import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/ui/app_notify.dart';
import 'package:image_picker/image_picker.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  String _fullName = "";
  String _image = "";
  String _bio = "";
  int _yearsOfExperience = 0;
  List<String> _skills = [];

  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _yearsController;

  final ImagePicker _imagePicker = ImagePicker();
  File? _pickedImageFile;

  final List<String> _availableSkills = [
    "Plumbing",
    "Electrical",
    "Cleaning",
    "Painting",
  ];

  // ── Entrance animation ──
  late AnimationController _entranceController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardsFade;
  late Animation<Offset> _cardsSlide;

  // ── Theme colours ──
  static const _navyDark = Color(0xFF0A1628);
  static const _navyMid = Color(0xFF1E40AF);
  static const _bgLight = Color(0xFFEFF6FF);
  static const _borderBlue = Color(0xFFDBEAFE);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF94A3B8);
  static const _hintColor = Color(0xFFCBD5E1);

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _bioController = TextEditingController();
    _yearsController = TextEditingController();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _cardsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _loadWorkerProfile();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await DioClient.dio.get("/api/worker/profile");
      final data = response.data["data"] as Map<String, dynamic>? ?? {};
      final userData = data["_id"] as Map<String, dynamic>? ?? {};

      setState(() {
        _fullName = userData["fullName"]?.toString() ?? "";
        _image = userData["image"]?.toString() ?? "";
        _bio = data["bio"]?.toString() ?? "";
        _yearsOfExperience = (data["yearsOfExperience"] as num?)?.toInt() ?? 0;
        _skills = ((data["skills"] as List?) ?? [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();

        _fullNameController.text = _fullName;
        _bioController.text = _bio;
        _yearsController.text = _yearsOfExperience.toString();
        _isLoading = false;
      });

      _entranceController.forward(from: 0);
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      _showSnack(
        AppNotify.messageFromError(
          e,
          fallback: "We couldn't load your profile. Please try again.",
        ),
      );
    } catch (_) {
      setState(() => _isLoading = false);
      _showSnack("We couldn't load your profile. Please try again.");
    }
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        _fullNameController.text = _fullName;
        _bioController.text = _bio;
        _yearsController.text = _yearsOfExperience.toString();
      }
      _isEditing = !_isEditing;
    });
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
        _image = file.path;
      });

      if (!mounted) return;
      _showSnack("Image selected.", isError: false);
    } catch (e) {
      _showSnack("We couldn't select that image. Please try another.");
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  void _openSkillsSelector() async {
    final tempSelected = List<String>.from(_skills);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Select Skills",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "You can choose more than one skill",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _textMuted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _availableSkills.length,
                            itemBuilder: (context, index) {
                              final skill = _availableSkills[index];
                              final isSelected = tempSelected.contains(skill);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? _navyMid
                                        : const Color(0xFFE2E8F0),
                                    width: 1.4,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  activeColor: _navyMid,
                                  checkboxShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    skill,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textDark,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setModalState(() {
                                      if (value == true) {
                                        if (!tempSelected.contains(skill)) {
                                          tempSelected.add(skill);
                                        }
                                      } else {
                                        tempSelected.remove(skill);
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _skills = tempSelected;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navyMid,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              "Done",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

Future<void> _saveProfile() async {
  final fullName = _fullNameController.text.trim();
  final bio = _bioController.text.trim();
  final years = int.tryParse(_yearsController.text.trim());

  final cleanedSkills = _skills
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();

  if (fullName.length < 2) {
    _showSnack("Full name must be at least 2 characters");
    return;
  }

  if (years == null || years < 0 || years > 60) {
    _showSnack("Years of experience must be between 0 and 60");
    return;
  }

  if (cleanedSkills.isEmpty) {
    _showSnack("Add at least one skill");
    return;
  }

  setState(() => _isSaving = true);

  try {
    String? base64Image;

    if (_pickedImageFile != null) {
      final bytes = await _pickedImageFile!.readAsBytes();

      base64Image =
          "data:image/jpeg;base64,${base64Encode(bytes)}";
    }

    final response = await DioClient.dio.put(
      "/api/worker/profile",
      data: {
        "fullName": fullName,
        "image": base64Image ?? _image,
        "bio": bio,
        "yearsOfExperience": years,
        "skills": cleanedSkills,
      },
    );

    final data = response.data["data"] as Map<String, dynamic>? ?? {};
    final userData = data["_id"] as Map<String, dynamic>? ?? {};

    setState(() {
      _fullName = userData["fullName"]?.toString() ?? fullName;
      _image = userData["image"]?.toString() ?? _image;
      _bio = data["bio"]?.toString() ?? bio;

      _yearsOfExperience =
          (data["yearsOfExperience"] as num?)?.toInt() ?? years;

      _skills = ((data["skills"] as List?) ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      _fullNameController.text = _fullName;
      _bioController.text = _bio;
      _yearsController.text = _yearsOfExperience.toString();

      _pickedImageFile = null;

      _isEditing = false;
    });

    if (!mounted) return;

    _showSnack("Your profile has been updated.", isError: false);

    Navigator.pop(context, true);
  } on DioException catch (e) {
    _showSnack(
      AppNotify.messageFromError(
        e,
        fallback: "We couldn't update your profile. Please try again.",
      ),
    );
  } catch (_) {
    _showSnack("We couldn't update your profile. Please try again.");
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    if (isError) {
      AppNotify.error(context, msg);
    } else {
      AppNotify.success(context, msg);
    }
  }



  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _isEditing ? _pickFromGallery : null,
      child: Stack(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF63B3FF).withOpacity(0.35),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF1A3A6E),
              backgroundImage: _pickedImageFile != null
                  ? FileImage(_pickedImageFile!)
                  : (_image.isNotEmpty ? NetworkImage(_image) : null),
              child: (_pickedImageFile == null && _image.isEmpty)
                  ? const Icon(
                      Icons.person_outline_rounded,
                      size: 38,
                      color: Color(0xFF63B3FF),
                    )
                  : null,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _navyMid,
                  shape: BoxShape.circle,
                  border: Border.all(color: _navyDark, width: 2),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderBlue, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _bgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _navyMid, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isNotEmpty ? value : "—",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderBlue, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SKILLS",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _skills.isEmpty
              ? Text(
                  "No skills added",
                  style: GoogleFonts.inter(color: _textMuted, fontSize: 13),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _bgLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _borderBlue, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            skill,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _navyMid,
                            ),
                          ),
                          if (_isEditing) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _removeSkill(skill),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: _navyMid,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildSkillsDropdownSelector() {
    return GestureDetector(
      onTap: _openSkillsSelector,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderBlue, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.build_circle_outlined, color: _textMuted, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _skills.isEmpty
                    ? "Select one or more skills"
                    : _skills.join(", "),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _skills.isEmpty ? _hintColor : _textDark,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    VoidCallback? onEditingComplete,
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
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onEditingComplete: onEditingComplete,
          style: GoogleFonts.inter(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _textMuted, size: 18),
            hintStyle: GoogleFonts.inter(color: _hintColor, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildEditFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _styledField(
          controller: _fullNameController,
          label: "Full Name",
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _styledField(
          controller: _bioController,
          label: "Bio",
          icon: Icons.description_outlined,
          maxLines: 4,
        ),
        const SizedBox(height: 14),
        _styledField(
          controller: _yearsController,
          label: "Years of Experience",
          icon: Icons.access_time_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        Text(
          "SKILLS",
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 7),
        _buildSkillsDropdownSelector(),
        const SizedBox(height: 10),
        _buildSkillsCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgLight,
        body: Center(
          child: CircularProgressIndicator(color: _navyMid),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgLight,
      body: Column(
        children: [
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.maybePop(context),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF63B3FF).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
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
                            Expanded(
                              child: Text(
                                "Worker Profile",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 36),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildAvatar(),
                        const SizedBox(height: 12),
                        Text(
                          _fullName.isNotEmpty ? _fullName : "Worker",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Worker account",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFB4D2FF).withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _cardsFade,
              child: SlideTransition(
                position: _cardsSlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing)
                        _buildEditFields()
                      else ...[
                        _infoTile(
                          icon: Icons.person_outline_rounded,
                          label: "Full Name",
                          value: _fullName,
                        ),
                        const SizedBox(height: 10),
                        _infoTile(
                          icon: Icons.description_outlined,
                          label: "Bio",
                          value: _bio,
                        ),
                        const SizedBox(height: 10),
                        _infoTile(
                          icon: Icons.access_time_rounded,
                          label: "Years of Experience",
                          value: "$_yearsOfExperience years",
                        ),
                        const SizedBox(height: 10),
                        _buildSkillsCard(),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _toggleEdit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isEditing ? Colors.white : _navyMid,
                            disabledBackgroundColor: _navyMid.withOpacity(0.5),
                            elevation: 0,
                            side: _isEditing
                                ? const BorderSide(
                                    color: _borderBlue,
                                    width: 1.5,
                                  )
                                : BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            _isEditing
                                ? Icons.close_rounded
                                : Icons.edit_rounded,
                            color: _isEditing ? _navyMid : Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            _isEditing ? "Cancel" : "Edit Worker Profile",
                            style: GoogleFonts.inter(
                              color: _isEditing ? _navyMid : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navyMid,
                              disabledBackgroundColor: _navyMid.withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    "Save Changes",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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