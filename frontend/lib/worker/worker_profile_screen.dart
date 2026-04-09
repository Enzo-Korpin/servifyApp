import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  String _fullName = "";
  String _image = "";
  String _bio = "";
  int _yearsOfExperience = 0;
  List<String> _skills = [];

  late TextEditingController _fullNameController;
  late TextEditingController _imageController;
  late TextEditingController _bioController;
  late TextEditingController _yearsController;
  late TextEditingController _skillInputController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _imageController = TextEditingController();
    _bioController = TextEditingController();
    _yearsController = TextEditingController();
    _skillInputController = TextEditingController();
    _loadWorkerProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _imageController.dispose();
    _bioController.dispose();
    _yearsController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerProfile() async {
    setState(() {
      _isLoading = true;
    });

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
        _imageController.text = _image;
        _bioController.text = _bio;
        _yearsController.text = _yearsOfExperience.toString();

        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
      });

      final message =
          e.response?.data?["error"]?["message"]?.toString() ??
          e.response?.data?["message"]?.toString() ??
          "Failed to load worker profile";

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load worker profile")),
      );
    }
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        _fullNameController.text = _fullName;
        _imageController.text = _image;
        _bioController.text = _bio;
        _yearsController.text = _yearsOfExperience.toString();
      }
      _isEditing = !_isEditing;
    });
  }

  void _addSkill() {
    final skill = _skillInputController.text.trim();
    if (skill.isEmpty) return;

    final exists = _skills.any(
      (s) => s.toLowerCase() == skill.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Skill already exists")),
      );
      return;
    }

    setState(() {
      _skills.add(skill);
      _skillInputController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Future<void> _saveProfile() async {
    final fullName = _fullNameController.text.trim();
    final image = _imageController.text.trim();
    final bio = _bioController.text.trim();
    final years = int.tryParse(_yearsController.text.trim());

    final cleanedSkills = _skills
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (fullName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Full name must be at least 2 characters")),
      );
      return;
    }

    if (years == null || years < 0 || years > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Years of experience must be between 0 and 60")),
      );
      return;
    }

    if (cleanedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one skill")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await DioClient.dio.put(
        "/api/worker/profile",
        data: {
          "fullName": fullName,
          "image": image,
          "bio": bio,
          "yearsOfExperience": years,
          "skills": cleanedSkills,
        },
      );

      final data = response.data["data"] as Map<String, dynamic>? ?? {};
      final userData = data["_id"] as Map<String, dynamic>? ?? {};

      setState(() {
        _fullName = userData["fullName"]?.toString() ?? fullName;
        _image = userData["image"]?.toString() ?? image;
        _bio = data["bio"]?.toString() ?? bio;
        _yearsOfExperience = (data["yearsOfExperience"] as num?)?.toInt() ?? years;
        _skills = ((data["skills"] as List?) ?? [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();

        _fullNameController.text = _fullName;
        _imageController.text = _image;
        _bioController.text = _bio;
        _yearsController.text = _yearsOfExperience.toString();

        _isEditing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Worker profile updated successfully")),
    );

    Navigator.pop(context, true);
    } on DioException catch (e) {
      final message =
          e.response?.data?["error"]?["message"]?.toString() ??
          e.response?.data?["message"]?.toString() ??
          "Update failed";

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildAvatar() {
    if (_image.isNotEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundImage: NetworkImage(_image),
      );
    }

    return const CircleAvatar(
      radius: 55,
      backgroundColor: Color(0xFFE2E8F0),
      child: Icon(Icons.person, size: 44, color: Colors.black54),
    );
  }

  Widget _buildReadOnlyTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : "-",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsWrap() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: _skills.isEmpty
          ? Text(
              "No skills added",
              style: GoogleFonts.poppins(color: Colors.grey),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  deleteIcon: _isEditing ? const Icon(Icons.close, size: 18) : null,
                  onDeleted: _isEditing ? () => _removeSkill(skill) : null,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEditFields() {
    return Column(
      children: [
        TextField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: "Full Name",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _imageController,
          decoration: const InputDecoration(
            labelText: "Image URL",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _bioController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Bio",
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _yearsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Years of Experience",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillInputController,
                decoration: const InputDecoration(
                  labelText: "Add Skill",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _addSkill,
                child: const Text("Add"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Worker Profile",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 14),
            Text(
              _fullName.isNotEmpty ? _fullName : "Worker",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            if (_isEditing) _buildEditFields(),

            if (!_isEditing) ...[
              _buildReadOnlyTile(
                icon: Icons.person_outline,
                title: "Full Name",
                value: _fullName,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyTile(
                icon: Icons.image_outlined,
                title: "Image URL",
                value: _image,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyTile(
                icon: Icons.work_outline,
                title: "Bio",
                value: _bio,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyTile(
                icon: Icons.timeline_outlined,
                title: "Years of Experience",
                value: _yearsOfExperience.toString(),
              ),
              const SizedBox(height: 12),
            ],

            if (_isEditing) const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Skills",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildSkillsWrap(),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _toggleEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDCEEFF),
                ),
                child: Text(
                  _isEditing ? "Cancel" : "Edit Worker Profile",
                  style: GoogleFonts.poppins(
                    color: Colors.blue.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6FEB),
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
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}