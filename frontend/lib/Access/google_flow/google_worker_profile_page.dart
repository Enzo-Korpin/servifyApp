import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/Access/google_flow/google_auth_service.dart';
import 'package:frontend/Home_pages/home_worker.dart';
import 'package:google_fonts/google_fonts.dart';

class GoogleWorkerProfilePage extends StatefulWidget {
  const GoogleWorkerProfilePage({super.key});

  @override
  State<GoogleWorkerProfilePage> createState() =>
      _GoogleWorkerProfilePageState();
}

class _GoogleWorkerProfilePageState extends State<GoogleWorkerProfilePage> {
  static const Color _navy = Color(0xFF0D1B3E);
  static const Color _cyan = Color(0xFF1EBBF0);
  static const Color _cardBg = Color(0xFF162447);
  static const Color _inputBg = Color(0xFF1E2F55);
  static const Color _inputBorder = Color(0xFF2A3F6F);
  static const Color _textMuted = Color(0xFF8FA3C8);

  final TextEditingController bioController = TextEditingController();

  final List<String> skills = [
    "Plumbing",
    "Electrical",
    "Painting",
    "Cleaning",
    "Carpentry",
  ];

  final List<int> yearsList = List.generate(31, (i) => i);

  final Set<String> selectedSkills = {};
  int? selectedYears;
  bool _isLoading = false;
  bool _skillsDropdownOpen = false;

  @override
  void dispose() {
    bioController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
      filled: true,
      fillColor: _inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cyan, width: 1.5),
      ),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: _textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildSkillsDropdown() {
    final label =
        selectedSkills.isEmpty ? 'Select skills' : selectedSkills.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _skillsDropdownOpen = !_skillsDropdownOpen);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _skillsDropdownOpen ? _cyan : _inputBorder,
                width: _skillsDropdownOpen ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.build_outlined, color: _textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: selectedSkills.isEmpty ? _textMuted : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  _skillsDropdownOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _textMuted,
                ),
              ],
            ),
          ),
        ),
        if (_skillsDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cyan, width: 1.5),
            ),
            child: Column(
              children: skills.asMap().entries.map((entry) {
                final skill = entry.value;
                final isLast = entry.key == skills.length - 1;
                final selected = selectedSkills.contains(skill);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        selectedSkills.remove(skill);
                      } else {
                        selectedSkills.add(skill);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected ? _cyan.withOpacity(0.12) : Colors.transparent,
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(
                                color: _inputBorder,
                                width: 0.8,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: selected ? _cyan : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: selected ? _cyan : _textMuted,
                              width: 1.5,
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          skill,
                          style: GoogleFonts.inter(
                            color: selected ? Colors.white : _textMuted,
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: selectedSkills.map((skill) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cyan.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill,
                      style: GoogleFonts.inter(
                        color: _cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() => selectedSkills.remove(skill));
                      },
                      child: const Icon(Icons.close, size: 13, color: _cyan),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _submit() async {
    final bio = bioController.text.trim();

    if (bio.isEmpty || selectedYears == null || selectedSkills.isEmpty) {
      _showMessage("Please fill all required fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await GoogleAuthService.completeWorkerProfile(
        bio: bio,
        yearsOfExperience: selectedYears!,
        skills: selectedSkills.map((skill) => skill.toLowerCase().trim()).toList(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeWorker()),
          (route) => false,
        );
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?["message"]?.toString() ??
          e.response?.data?["error"]?.toString() ??
          "Failed to complete worker profile";

      _showMessage(message);
    } catch (e) {
      _showMessage("Failed to complete worker profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          if (_skillsDropdownOpen) {
            setState(() => _skillsDropdownOpen = false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Center(
                child: Column(
                  children: [
                    Text(
                      "Complete Worker Profile",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Finish your profile to start earning",
                      style: GoogleFonts.inter(
                        color: _textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _inputBorder),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("BIO"),
                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: "Tell customers about your work",
                        prefixIcon: const Icon(
                          Icons.info_outline,
                          color: _textMuted,
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _label("PRIMARY SKILLS"),
                    _buildSkillsDropdown(),

                    const SizedBox(height: 18),

                    _label("YEARS OF EXPERIENCE"),
                    DropdownButtonFormField<int>(
                      value: selectedYears,
                      dropdownColor: _inputBg,
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: _textMuted,
                      decoration: _inputDecoration(
                        labelText: "Select years",
                        prefixIcon: const Icon(
                          Icons.workspace_premium_outlined,
                          color: _textMuted,
                          size: 18,
                        ),
                      ),
                      items: yearsList
                          .map(
                            (y) => DropdownMenuItem<int>(
                              value: y,
                              child: Text(
                                "$y ${y == 1 ? 'year' : 'years'}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedYears = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "Complete Profile",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
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