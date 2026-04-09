import 'package:flutter/material.dart';
import 'Worker_Follow_card.dart';

class FollowedWorkersPage extends StatefulWidget {
  const FollowedWorkersPage({super.key});

  @override
  State<FollowedWorkersPage> createState() => _FollowedWorkersPageState();
}

class _FollowedWorkersPageState extends State<FollowedWorkersPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> followedWorkers = [
    {
      "name": "Anas",
      "profession": "Plumber",
      "distance": 0.0,
      "rating": 4.0,
      "imageUrl": "",
    },
    {
      "name": "Karam Naser",
      "profession": "Cleaner",
      "distance": 3.2,
      "rating": 4.3,
      "imageUrl": "",
    },
    {
      "name": "Ahmad Ali",
      "profession": "Electrician",
      "distance": 1.7,
      "rating": 4.8,
      "imageUrl": "",
    },
  ];

  String search = "";

  List<Map<String, dynamic>> get filteredWorkers {
    if (search.trim().isEmpty) return followedWorkers;

    return followedWorkers.where((worker) {
      final name = worker["name"].toString().toLowerCase();
      final profession = worker["profession"].toString().toLowerCase();
      final query = search.toLowerCase();

      return name.contains(query) || profession.contains(query);
    }).toList();
  }

  void _unfollowWorker(int indexInOriginalList) {
    setState(() {
      followedWorkers.removeAt(indexInOriginalList);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Worker unfollowed"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF08214A);
    const Color midBlue = Color(0xFF102C63);
    const Color primaryBlue = Color(0xFF2948B8);
    const Color sheetColor = Color(0xFFEAF0F7);

    return Scaffold(
      backgroundColor: darkBlue,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Followed Workers",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Quick access to workers you follow",
                    style: TextStyle(
                      color: Color(0xFFB9C6E2),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: midBlue,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          search = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search followed workers",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                decoration: const BoxDecoration(
                  color: sheetColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB9C2D0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            "${filteredWorkers.length} Workers",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Manage your followed workers list",
                            style: TextStyle(
                              color: Color(0xFF6E7889),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: filteredWorkers.isEmpty
                          ? const Center(
                              child: Text(
                                "No followed workers found",
                                style: TextStyle(
                                  color: Color(0xFF7C879A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredWorkers.length,
                              itemBuilder: (context, index) {
                                final worker = filteredWorkers[index];

                                final originalIndex = followedWorkers.indexOf(worker);

                                return FollowedWorkerCard(
                                  name: worker["name"],
                                  profession: worker["profession"],
                                  distanceKm: worker["distance"],
                                  rating: worker["rating"],
                                  imageUrl: worker["imageUrl"],
                                  onView: () {
                                    // put your navigation here
                                  },
                                  onUnfollow: () {
                                    _unfollowWorker(originalIndex);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}