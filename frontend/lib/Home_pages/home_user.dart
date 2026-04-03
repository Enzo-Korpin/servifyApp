import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:frontend/Home_pages/worker_card.dart';
import 'package:frontend/core/map/map_config.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/profiles/profile_user.dart';
import 'package:frontend/requests/Requists_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class WorkerMapPage extends StatefulWidget {
  const WorkerMapPage({super.key});

  @override
  State<WorkerMapPage> createState() => _WorkerMapPageState();
}

class _WorkerMapPageState extends State<WorkerMapPage> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  static const bool _useMap = false;

  int _selectedIndex = 0;
  bool _isGettingLocation = false;
  bool _isLoadingWorkers = false;
  bool _isLoadingUserLocation = false;

  double? _userLat;
  double? _userLng;

  String? _selectedSkill; // null = all
  String _activeSort = 'distance'; // distance | rating
  bool _distanceAscending = true;
  bool _ratingDescending = true;

  List<Map<String, dynamic>> _allWorkers = [];

  static const LatLng _fallbackLocation = LatLng(31.9539, 35.9106);

  final List<Category> categories = const [
    Category(
      key: "All",
      value: "assets/plumbing.png",
      apiSkill: null,
      workerType: "All",
    ),
    Category(
      key: "Plumbing",
      value: "assets/plumbing.png",
      apiSkill: "plumbing",
      workerType: "Plumber",
    ),
    Category(
      key: "Electrical",
      value: "assets/electrsian.png",
      apiSkill: "electricity",
      workerType: "Electrician",
    ),
    Category(
      key: "Painting",
      value: "assets/painter.png",
      apiSkill: "painting",
      workerType: "Painter",
    ),
    Category(
      key: "Cleaning",
      value: "assets/cleaner.png",
      apiSkill: "cleaning",
      workerType: "Cleaner",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _fetchUserLocationFromBackend();

    if (_userLat == null || _userLng == null) {
      if (!mounted) return;
      setState(() {
        _userLat = _fallbackLocation.latitude;
        _userLng = _fallbackLocation.longitude;
      });
      _showMessage("Using default location");
    }

    await _fetchWorkers();
  }

  Future<void> _fetchUserLocationFromBackend() async {
    if (mounted) {
      setState(() {
        _isLoadingUserLocation = true;
      });
    }

    try {
      final response = await DioClient.dio.get(
        '/api/auth/check-auth',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data;
      final coords = (data["data"]?["location"]?["coordinates"] ?? []) as List;

      if (coords.length != 2) {
        _showMessage("User location not found");
        return;
      }

      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();

      if (!mounted) return;

      setState(() {
        _userLat = lat;
        _userLng = lng;
      });

      if (_useMap) {
        final currentZoom =
            _mapController.camera.zoom == 0 ? 13.0 : _mapController.camera.zoom;
        _mapController.move(LatLng(lat, lng), currentZoom);
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?["message"]?.toString() ??
          e.response?.data?["error"]?.toString() ??
          "Failed to load user location";
      _showMessage(message);
    } catch (e) {
      _showMessage("Failed to load user location: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserLocation = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage("Location services are disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage("Location permission denied");
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage("Location permission permanently denied");
        return;
      }

      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (_) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (_) {
          position = await Geolocator.getLastKnownPosition();
          if (position == null) {
            _showMessage(
              "Could not determine location. Enable location services and try again.",
            );
            return;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _userLat = position!.latitude;
        _userLng = position.longitude;
      });

      if (_useMap) {
        _mapController.move(
          LatLng(_userLat!, _userLng!),
          _mapController.camera.zoom == 0 ? 13.0 : _mapController.camera.zoom,
        );
      }

      await _fetchWorkers();

      _showMessage("Showing workers near your current location");
    } on DioException catch (e) {
      final message =
          e.response?.data?["message"]?.toString() ??
          e.response?.data?["error"]?.toString() ??
          "Failed to get location";
      _showMessage(message);
    } catch (e) {
      _showMessage("Failed to get location: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _fetchWorkers() async {
    if (_userLat == null || _userLng == null) return;

    if (mounted) {
      setState(() {
        _isLoadingWorkers = true;
      });
    }

    try {
      final int limit = _selectedSkill == null ? 15 : 20;

      final queryParameters = <String, dynamic>{
        "lat": _userLat,
        "lng": _userLng,
        "radiusKm": 5,
        "limit": limit,
        "sort": _activeSort,
      };

      if (_selectedSkill != null) {
        queryParameters["skill"] = _selectedSkill;
      }

      final response = await DioClient.dio.get(
        '/api/customer/filtered-workers',
        queryParameters: queryParameters,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data;
      final List rawWorkers = (data["data"]?["workers"] ?? []) as List;

      _allWorkers = rawWorkers.map<Map<String, dynamic>>((worker) {
        final profile = Map<String, dynamic>.from(worker["workerProfile"] ?? {});
        final location = Map<String, dynamic>.from(worker["location"] ?? {});
        final coords = (location["coordinates"] ?? [0.0, 0.0]) as List;

        final double lng =
            coords.isNotEmpty ? (coords[0] as num).toDouble() : 0.0;
        final double lat =
            coords.length > 1 ? (coords[1] as num).toDouble() : 0.0;

        final skills = List<String>.from(profile["skills"] ?? []);

        return {
          "_id": worker["_id"],
          "name": worker["fullName"] ?? "",
          "job": _resolveMainJob(skills),
          "skills": skills,
          "rating": ((profile["rate"] ?? 0) as num).toDouble(),
          "ratingCount":
              profile["ratingCount"] ?? profile["numberOfRatings"] ?? 0,
          "distanceMeters": (worker["distanceMeters"] ?? 0) as num,
          "distanceValue": ((worker["distanceMeters"] ?? 0) as num) / 1000,
          "distance":
              "${(((worker["distanceMeters"] ?? 0) as num) / 1000).toStringAsFixed(1)} km",
          "lat": lat,
          "lng": lng,
          "image": worker["image"],
        };
      }).toList();

      _applyLocalSort();

      if (mounted) {
        setState(() {});
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?["message"]?.toString() ??
          e.response?.data?["error"]?.toString() ??
          "Failed to load workers";
      _showMessage(message);
    } catch (e) {
      _showMessage("Failed to load workers: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWorkers = false;
        });
      }
    }
  }

  String _resolveMainJob(List<String> skills) {
    final normalized = skills.map((e) => e.toLowerCase().trim()).toList();

    if (normalized.contains('plumbing')) return 'Plumber';
    if (normalized.contains('electricity') || normalized.contains('electrical')) {
      return 'Electrician';
    }
    if (normalized.contains('painting')) return 'Painter';
    if (normalized.contains('cleaning')) return 'Cleaner';
    if (normalized.contains('carpentry')) return 'Carpenter';

    return 'Worker';
  }

  void _applyLocalSort() {
    if (_activeSort == 'distance') {
      _allWorkers.sort((a, b) {
        final cmp =
            (a["distanceValue"] as num).compareTo(b["distanceValue"] as num);
        return _distanceAscending ? cmp : -cmp;
      });
    } else if (_activeSort == 'rating') {
      _allWorkers.sort((a, b) {
        final cmp = (b["rating"] as num).compareTo(a["rating"] as num);
        return _ratingDescending ? cmp : -cmp;
      });
    }
  }

  List<Map<String, dynamic>> get _visibleWorkers {
    List<Map<String, dynamic>> result = List.from(_allWorkers);

    final search = _searchController.text.trim().toLowerCase();
    if (search.isNotEmpty) {
      result = result.where((worker) {
        final name = (worker["name"] ?? "").toString().toLowerCase();
        return name.contains(search);
      }).toList();
    }

    return result;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onCategoryTap(Category category) async {
    setState(() {
      _selectedSkill = category.apiSkill;
      _activeSort = 'distance';
      _distanceAscending = true;
      _ratingDescending = true;
    });

    await _fetchWorkers();
  }

  Future<void> _onSortDistance() async {
    setState(() {
      if (_activeSort == 'distance') {
        _distanceAscending = !_distanceAscending;
      } else {
        _activeSort = 'distance';
        _distanceAscending = true;
      }
    });

    await _fetchWorkers();
  }

  Future<void> _onSortRating() async {
    setState(() {
      if (_activeSort == 'rating') {
        _ratingDescending = !_ratingDescending;
      } else {
        _activeSort = 'rating';
        _ratingDescending = true;
      }
    });

    await _fetchWorkers();
  }

  Widget _buildMapOrPlaceholder(List<Map<String, dynamic>> visibleWorkers) {
    if (_useMap) {
      return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(_userLat!, _userLng!),
          initialZoom: 13,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: AppMapConfig.tileUrl,
            userAgentPackageName: AppMapConfig.userAgent,
            tileProvider:
                FMTCStore(AppMapConfig.storeName).getTileProvider(),
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_userLat!, _userLng!),
                width: 44,
                height: 44,
                child: _userPin(),
              ),
              ...visibleWorkers
                  .where((worker) => worker["lat"] != 0 && worker["lng"] != 0)
                  .map(
                    (worker) => Marker(
                      point: LatLng(
                        worker["lat"] as double,
                        worker["lng"] as double,
                      ),
                      width: 44,
                      height: 44,
                      child: _workerPin(worker["job"] as String),
                    ),
                  ),
            ],
          ),
        ],
      );
    }

    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Text(
        "Map disabled for now",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    final visibleWorkers = _visibleWorkers;

    if (_isLoadingUserLocation && _userLat == null && _userLng == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userLat == null || _userLng == null) {
      return const Center(
        child: Text("Could not load user location"),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: _buildMapOrPlaceholder(visibleWorkers),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                _searchBar(),
                const SizedBox(height: 12),
                _locationButton(),
                const SizedBox(height: 16),
                if (_useMap)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _zoomButtons(),
                  ),
              ],
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.35,
          maxChildSize: 0.78,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) => _chip(categories[i]),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemCount: categories.length,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _onSortRating,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _activeSort == 'rating'
                                  ? const Color(0xFFEBF5FF)
                                  : Colors.white,
                              foregroundColor: _activeSort == 'rating'
                                  ? const Color(0xFF2563EB)
                                  : Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: _activeSort == 'rating'
                                      ? const Color(0xFF2563EB)
                                      : Colors.black12,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Rating"),
                                if (_activeSort == 'rating') ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    _ratingDescending
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _onSortDistance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _activeSort == 'distance'
                                  ? const Color(0xFFEBF5FF)
                                  : Colors.white,
                              foregroundColor: _activeSort == 'distance'
                                  ? const Color(0xFF2563EB)
                                  : Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: _activeSort == 'distance'
                                      ? const Color(0xFF2563EB)
                                      : Colors.black12,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Distance"),
                                if (_activeSort == 'distance') ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    _distanceAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingWorkers
                        ? const Center(child: CircularProgressIndicator())
                        : visibleWorkers.isEmpty
                            ? const Center(
                                child: Text(
                                  "No workers found",
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (_, i) =>
                                    WorkerCard(worker: visibleWorkers[i]),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemCount: visibleWorkers.length,
                              ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return const RequestsPage();
      case 2:
        return const Center(child: Text("Chat Screen"));
      case 3:
        return const Center(child: Text("AI Screen"));
      case 4:
        return const CustomerProfileScreen();
      default:
        return _buildHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.black45,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: "My requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            label: "AI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _locationButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isGettingLocation ? null : _getCurrentLocation,
        icon: _isGettingLocation
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.my_location, color: Colors.white),
        label: Text(
          _isGettingLocation
              ? "Getting Location..."
              : "Use My Current Location",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _workerPin(String job) {
    IconData icon;
    Color color;

    switch (job.toLowerCase()) {
      case 'plumber':
        icon = Icons.plumbing;
        color = Colors.blue;
        break;
      case 'electrician':
        icon = Icons.electrical_services;
        color = Colors.amber;
        break;
      case 'painter':
        icon = Icons.format_paint;
        color = Colors.purple;
        break;
      case 'cleaner':
        icon = Icons.cleaning_services;
        color = Colors.green;
        break;
      case 'carpenter':
        icon = Icons.handyman;
        color = Colors.brown;
        break;
      default:
        icon = Icons.person_pin_circle;
        color = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _userPin() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 22),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search worker by name",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.close, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _zoomButtons() {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            ),
          ),
          Container(height: 1, width: 32, color: Colors.black12),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.black87),
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(Category category) {
    final bool selected = _selectedSkill == category.apiSkill;

    return InkWell(
      onTap: () => _onCategoryTap(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEBF5FF) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Text(
              category.key,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF2563EB) : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Image.asset(
              category.value,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class Category {
  final String key;
  final String value;
  final String? apiSkill;
  final String workerType;

  const Category({
    required this.key,
    required this.value,
    required this.apiSkill,
    required this.workerType,
  });
}