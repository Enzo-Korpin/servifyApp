// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:frontend/core/network/dio_client.dart';
// import 'package:frontend/requests/service_requist_page.dart';
// import 'package:google_fonts/google_fonts.dart';

// class ProfileWorker extends StatefulWidget {
//   final String workerId;

//   const ProfileWorker({super.key, required this.workerId});

//   @override
//   State<ProfileWorker> createState() => _ProfileWorkerState();
// }

// class _ProfileWorkerState extends State<ProfileWorker> {
//   bool _isLoading = true;
//   bool _isFollowing = false;
//   String? _error;

//   String fullName = "";
//   String imageUrl = "";
//   String bio = "";
//   int yearsOfExperience = 0;
//   double rate = 0;
//   int ratingCount = 0;
//   List<String> skills = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadWorker();
//   }

//   Future<void> _loadWorker() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final response = await DioClient.dio.get(
//         '/api/worker/${widget.workerId}',
//         options: Options(
//           sendTimeout: const Duration(seconds: 10),
//           receiveTimeout: const Duration(seconds: 10),
//         ),
//       );

//       final data = response.data["data"] ?? {};
//       final user = data["_id"] ?? {};

//       if (!mounted) return;

//       setState(() {
//         fullName = (user["fullName"] ?? "").toString();
//         imageUrl = (user["image"] ?? "").toString();
//         bio = (data["bio"] ?? "").toString();
//         yearsOfExperience = ((data["yearsOfExperience"] ?? 0) as num).toInt();
//         rate = ((data["rate"] ?? 0) as num).toDouble();
//         ratingCount = ((data["ratingCount"] ?? 0) as num).toInt();
//         skills = List<String>.from(data["skills"] ?? []);
//         _isLoading = false;
//       });
//     } on DioException catch (e) {
//       final message =
//           e.response?.data?["message"]?.toString() ??
//           e.response?.data?["error"]?.toString() ??
//           "Failed to load worker profile";

//       if (!mounted) return;
//       setState(() {
//         _error = message;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _error = "Failed to load worker profile";
//         _isLoading = false;
//       });
//     }
//   }

//   String get aboutTitle {
//     final firstName = fullName.trim().isEmpty
//         ? "Worker"
//         : fullName.trim().split(" ").first;
//     return "ABOUT $firstName";
//   }

//   String _capitalize(String value) {
//     if (value.isEmpty) return value;
//     return value[0].toUpperCase() + value.substring(1);
//   }

//   List<Widget> _buildStars(double rating) {
//     final fullStars = rating.floor().clamp(0, 5);
//     final hasHalfStar = (rating - fullStars) >= 0.5;
//     final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

//     return [
//       ...List.generate(
//         fullStars,
//         (_) => const Icon(
//           Icons.star_rounded,
//           color: Color(0xFFFFB800),
//           size: 22,
//         ),
//       ),
//       if (hasHalfStar)
//         const Icon(
//           Icons.star_half_rounded,
//           color: Color(0xFFFFB800),
//           size: 22,
//         ),
//       ...List.generate(
//         emptyStars,
//         (_) => const Icon(
//           Icons.star_rounded,
//           color: Color(0xFFD8DCE6),
//           size: 22,
//         ),
//       ),
//     ];
//   }

//   Widget _buildAvatar() {
//     if (imageUrl.isNotEmpty) {
//       return Container(
//         width: 104,
//         height: 104,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: const Color(0xFFB9C5DE),
//           border: Border.all(color: Colors.white, width: 3),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: ClipOval(
//           child: Image.network(
//             imageUrl,
//             fit: BoxFit.cover,
//             errorBuilder: (_, __, ___) {
//               return const Icon(
//                 Icons.person_outline_rounded,
//                 size: 52,
//                 color: Colors.white,
//               );
//             },
//           ),
//         ),
//       );
//     }

//     return Container(
//       width: 104,
//       height: 104,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: const Color(0xFFB9C5DE),
//         border: Border.all(color: Colors.white, width: 3),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: const Icon(
//         Icons.person_outline_rounded,
//         size: 52,
//         color: Colors.white,
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required String label,
//     required IconData icon,
//     required VoidCallback onPressed,
//     bool isPrimary = false,
//   }) {
//     return Expanded(
//       child: SizedBox(
//         height: 50,
//         child: ElevatedButton.icon(
//           onPressed: onPressed,
//           icon: Icon(icon, size: 18),
//           label: Text(
//             label,
//             style: GoogleFonts.inter(
//               fontSize: 15,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           style: ElevatedButton.styleFrom(
//             elevation: isPrimary ? 2 : 0,
//             backgroundColor:
//                 isPrimary ? const Color(0xFF2F57F6) : const Color(0xFFF7F7FA),
//             foregroundColor:
//                 isPrimary ? Colors.white : const Color(0xFF52607A),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14),
//               side: BorderSide(
//                 color: isPrimary
//                     ? const Color(0xFF2F57F6)
//                     : const Color(0xFFE3E6EE),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTopStatCard({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF3F5F8),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, size: 15, color: const Color(0xFFA2AAB8)),
//                 const SizedBox(width: 6),
//                 Text(
//                   title,
//                   style: GoogleFonts.inter(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: 0.3,
//                     color: const Color(0xFFA2AAB8),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             Text(
//               value,
//               style: GoogleFonts.inter(
//                 fontSize: 22,
//                 fontWeight: FontWeight.w800,
//                 color: const Color(0xFF2C3445),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionCard({
//     required IconData icon,
//     required String title,
//     required Widget child,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF3F5F8),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 15, color: const Color(0xFFA2AAB8)),
//               const SizedBox(width: 6),
//               Text(
//                 title,
//                 style: GoogleFonts.inter(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.3,
//                   color: const Color(0xFFA2AAB8),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _buildSkillChip(String skill) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: const Color(0xFFE4ECFF),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         _capitalize(skill),
//         style: GoogleFonts.inter(
//           fontSize: 11,
//           fontWeight: FontWeight.w600,
//           color: const Color(0xFF4B6FEA),
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadedContent() {
//     final topPadding = MediaQuery.of(context).padding.top;

//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           Stack(
//             clipBehavior: Clip.none,
//             alignment: Alignment.center,
//             children: [
//               Container(
//                 width: double.infinity,
//                 height: topPadding + 140,
//                 color: const Color(0xFF0B1E4A),
//                 child: Padding(
//                   padding: EdgeInsets.fromLTRB(18, topPadding + 10, 18, 0),
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Container(
//                           width: 38,
//                           height: 38,
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.12),
//                             shape: BoxShape.circle,
//                           ),
//                           child: IconButton(
//                             onPressed: () => Navigator.pop(context),
//                             icon: const Icon(
//                               Icons.arrow_back_ios_new_rounded,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Transform.translate(
//                         offset: const Offset(0, -6),
//                         child: Text(
//                           "Worker Profile",
//                           style: GoogleFonts.inter(
//                             color: Colors.white,
//                             fontSize: 20,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Positioned(
//                 bottom: -52,
//                 child: _buildAvatar(),
//               ),
//             ],
//           ),
//           const SizedBox(height: 62),

//           Text(
//             fullName.isEmpty ? "Worker Name" : fullName,
//             textAlign: TextAlign.center,
//             style: GoogleFonts.inter(
//               fontSize: 19,
//               fontWeight: FontWeight.w800,
//               color: const Color(0xFF24324A),
//             ),
//           ),

//           const SizedBox(height: 12),

//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 10),
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFAFAFB),
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 14,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     _buildActionButton(
//                       label: "Chat",
//                       icon: Icons.chat_bubble_outline_rounded,
//                       onPressed: () {},
//                     ),
//                     const SizedBox(width: 10),
//                     _buildActionButton(
//                       label: _isFollowing ? "Following" : "Follow",
//                       icon: _isFollowing
//                           ? Icons.check_rounded
//                           : Icons.person_add_alt_1_rounded,
//                       isPrimary: true,
//                       onPressed: () {
//                         setState(() {
//                           _isFollowing = !_isFollowing;
//                         });
//                       },
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 14),

//                 Row(
//                   children: [
//                     _buildTopStatCard(
//                       icon: Icons.access_time_rounded,
//                       title: "Experience",
//                       value: "$yearsOfExperience Years",
//                     ),
//                     const SizedBox(width: 10),
//                     _buildTopStatCard(
//                       icon: Icons.handyman_outlined,
//                       title: "Skills",
//                       value: skills.length.toString(),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 12),

//                 _buildSectionCard(
//                   icon: Icons.handyman_outlined,
//                   title: "Skills",
//                   child: skills.isEmpty
//                       ? Text(
//                           "No skills added",
//                           style: GoogleFonts.inter(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w500,
//                             color: const Color(0xFF9CA3AF),
//                           ),
//                         )
//                       : Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: skills.map(_buildSkillChip).toList(),
//                         ),
//                 ),

//                 const SizedBox(height: 12),

//                 _buildSectionCard(
//                   icon: Icons.info_outline_rounded,
//                   title: aboutTitle,
//                   child: Text(
//                     bio.trim().isEmpty ? "No bio added yet." : bio,
//                     style: GoogleFonts.inter(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: const Color(0xFF9CA3AF),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 12),

//                 _buildSectionCard(
//                   icon: Icons.reviews_outlined,
//                   title: "CUSTOMER REVIEWS",
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         rate.toStringAsFixed(1),
//                         style: GoogleFonts.inter(
//                           fontSize: 22,
//                           fontWeight: FontWeight.w800,
//                           color: const Color(0xFF1F2937),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Padding(
//                           padding: const EdgeInsets.only(top: 4),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(children: _buildStars(rate)),
//                               const SizedBox(height: 2),
//                               Text(
//                                 "($ratingCount ${ratingCount == 1 ? "review" : "reviews"})",
//                                 style: GoogleFonts.inter(
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w500,
//                                   color: const Color(0xFF9CA3AF),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 14),

//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 18),
//             child: SizedBox(
//               width: double.infinity,
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (_) => ServiceRequestScreen(
//                         workerId: widget.workerId,
//                         workerName: fullName,
//                         workerImage: imageUrl,
//                         workerSkills: skills,
//                         workerRating: rate,
//                       ),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   elevation: 2,
//                   backgroundColor: const Color(0xFF2F57F6),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//                 child: Text(
//                   "Request Service",
//                   style: GoogleFonts.inter(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w800,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildBody() {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_error != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 _error!,
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.inter(fontSize: 16),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: _loadWorker,
//                 child: const Text("Retry"),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return _buildLoadedContent();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F3F6),
//       body: _buildBody(),
//     );
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/requests/service_requist_page.dart';
import 'package:frontend/Follow/Follow_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileWorker extends StatefulWidget {
  final String workerId;

  const ProfileWorker({super.key, required this.workerId});

  @override
  State<ProfileWorker> createState() => _ProfileWorkerState();
}

class _ProfileWorkerState extends State<ProfileWorker> {
  final FollowService _followService = FollowService();

  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
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
      final profileFuture = DioClient.dio.get(
        '/api/worker/${widget.workerId}',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final followFuture = _followService.isFollowingWorker(widget.workerId);

      final results = await Future.wait<dynamic>([profileFuture, followFuture]);

      final response = results[0] as Response;
      final isFollowing = results[1] as bool;

      final data = response.data["data"] ?? {};
      final user = data["_id"] ?? {};

      if (!mounted) return;

      setState(() {
        fullName = (user["fullName"] ?? "").toString();
        imageUrl = (user["image"] ?? "").toString();
        bio = (data["bio"] ?? "").toString();
        yearsOfExperience = ((data["yearsOfExperience"] ?? 0) as num).toInt();
        rate = ((data["rate"] ?? 0) as num).toDouble();
        ratingCount = ((data["ratingCount"] ?? 0) as num).toInt();
        skills = List<String>.from(data["skills"] ?? []);
        _isFollowing = isFollowing;
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

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (_isFollowing) {
        await _followService.unfollowWorker(widget.workerId);

        if (!mounted) return;
        setState(() {
          _isFollowing = false;
        });

        _showMessage("Worker unfollowed");
      } else {
        await _followService.followWorker(widget.workerId);

        if (!mounted) return;
        setState(() {
          _isFollowing = true;
        });

        _showMessage("Worker followed successfully");
      }
    } on DioException catch (e) {
      final message =
        e.response?.data?["message"]?.toString() ??
        e.response?.data?["error"]?.toString() ??
        e.response?.data.toString() ??
        "Failed to update follow";
      _showMessage(message);
    } catch (_) {
      _showMessage("Failed to update follow");
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String get aboutTitle {
    final firstName = fullName.trim().isEmpty
        ? "Worker"
        : fullName.trim().split(" ").first;
    return "ABOUT $firstName";
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  List<Widget> _buildStars(double rating) {
    final fullStars = rating.floor().clamp(0, 5);
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return [
      ...List.generate(
        fullStars,
        (_) => const Icon(
          Icons.star_rounded,
          color: Color(0xFFFFB800),
          size: 22,
        ),
      ),
      if (hasHalfStar)
        const Icon(
          Icons.star_half_rounded,
          color: Color(0xFFFFB800),
          size: 22,
        ),
      ...List.generate(
        emptyStars,
        (_) => const Icon(
          Icons.star_rounded,
          color: Color(0xFFD8DCE6),
          size: 22,
        ),
      ),
    ];
  }

  Widget _buildAvatar() {
    if (imageUrl.isNotEmpty) {
      return Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFB9C5DE),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return const Icon(
                Icons.person_outline_rounded,
                size: 52,
                color: Colors.white,
              );
            },
          ),
        ),
      );
    }

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFB9C5DE),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        size: 52,
        color: Colors.white,
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    return Expanded(
      child: SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 18),
          label: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            elevation: isPrimary ? 2 : 0,
            backgroundColor:
                isPrimary ? const Color(0xFF2F57F6) : const Color(0xFFF7F7FA),
            foregroundColor:
                isPrimary ? Colors.white : const Color(0xFF52607A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isPrimary
                    ? const Color(0xFF2F57F6)
                    : const Color(0xFFE3E6EE),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: const Color(0xFFA2AAB8)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: const Color(0xFFA2AAB8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2C3445),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFFA2AAB8)),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: const Color(0xFFA2AAB8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE4ECFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _capitalize(skill),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4B6FEA),
        ),
      ),
    );
  }

  Widget _buildLoadedContent() {
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: topPadding + 140,
                color: const Color(0xFF0B1E4A),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, topPadding + 10, 18, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -6),
                        child: Text(
                          "Worker Profile",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -52,
                child: _buildAvatar(),
              ),
            ],
          ),
          const SizedBox(height: 62),

          Text(
            fullName.isEmpty ? "Worker Name" : fullName,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF24324A),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFB),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildActionButton(
                      label: "Chat",
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(
                      label: _isFollowing ? "Following" : "Follow",
                      icon: _isFollowing
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      isPrimary: true,
                      isLoading: _isFollowLoading,
                      onPressed: _isFollowLoading ? null : _toggleFollow,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildTopStatCard(
                      icon: Icons.access_time_rounded,
                      title: "Experience",
                      value: "$yearsOfExperience Years",
                    ),
                    const SizedBox(width: 10),
                    _buildTopStatCard(
                      icon: Icons.handyman_outlined,
                      title: "Skills",
                      value: skills.length.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  icon: Icons.handyman_outlined,
                  title: "Skills",
                  child: skills.isEmpty
                      ? Text(
                          "No skills added",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map(_buildSkillChip).toList(),
                        ),
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  icon: Icons.info_outline_rounded,
                  title: aboutTitle,
                  child: Text(
                    bio.trim().isEmpty ? "No bio added yet." : bio,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  icon: Icons.reviews_outlined,
                  title: "CUSTOMER REVIEWS",
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rate.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: _buildStars(rate)),
                              const SizedBox(height: 2),
                              Text(
                                "($ratingCount ${ratingCount == 1 ? "review" : "reviews"})",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: SizedBox(
              width: double.infinity,
              height: 56,
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
                  elevation: 2,
                  backgroundColor: const Color(0xFF2F57F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Request Service",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
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
                style: GoogleFonts.inter(fontSize: 16),
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

    return _buildLoadedContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: _buildBody(),
    );
  }
}