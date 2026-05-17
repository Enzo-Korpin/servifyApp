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
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class WorkerMapPage extends StatefulWidget {
  const WorkerMapPage({super.key});

  @override
  State<WorkerMapPage> createState() => _WorkerMapPageState();
}

class _WorkerMapPageState extends State<WorkerMapPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  static const bool _useMap = false;
  Timer? _searchDebounce;
  String? _searchNextCursor;
  bool _isSearchingByName = false;
  bool _isLoadingMoreSearch = false;
  bool _hasMoreSearchResults = false;
  int _selectedIndex = 0;
  bool _isGettingLocation = false;
  bool _isLoadingWorkers = false;
  bool _isLoadingUserLocation = false;

  double? _userLat;
  double? _userLng;

  String? _selectedSkill;
  String _activeSort = 'distance';
  bool _distanceAscending = true;
  bool _ratingDescending = true;

  List<Map<String, dynamic>> _allWorkers = [];

  late AnimationController _animController;
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

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
      apiSkill: "Electrical",
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

  void _onSearchChanged() {
    _searchDebounce?.cancel();

    final search = _searchController.text.trim();

    if (mounted) setState(() {});

    if (search.isEmpty) {
      _searchNextCursor = null;
      _hasMoreSearchResults = false;
      _isSearchingByName = false;
      _fetchWorkers();
      return;
    }

    if (search.length < 2) {
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      await _searchWorkersByName(search: search, reset: true);
    });
  }

  Future<void> _searchWorkersByName({
    required String search,
    bool reset = false,
  }) async {
    if (_userLat == null || _userLng == null) return;

    if (reset) {
      _searchNextCursor = null;
      _hasMoreSearchResults = false;
    }

    if (mounted) {
      setState(() {
        if (reset) {
          _isLoadingWorkers = true;
        } else {
          _isLoadingMoreSearch = true;
        }
        _isSearchingByName = true;
      });
    }

    try {
      final queryParameters = <String, dynamic>{
        "search": search,
      };

      if (!reset && _searchNextCursor != null) {
        queryParameters["after"] = _searchNextCursor;
      }

      final response = await DioClient.dio.get(
        '/api/customer/search-workers',
        queryParameters: queryParameters,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data;
      final List rawWorkers = (data["data"]?["workers"] ?? []) as List;
      final String? nextCursor = data["data"]?["nextCursor"]?.toString();

      final mappedWorkers = rawWorkers.map<Map<String, dynamic>>((worker) {
        return {
          "_id": worker["_id"],
          "name": worker["fullName"] ?? "",
          "job": "Worker",
          "skills": <String>[],
          "rating": ((worker["rate"] ?? 0) as num).toDouble(),
          "ratingCount": 0,
          "distanceMeters": 0,
          "distanceValue": 0.0,
          "distance": "",
          "lat": 0.0,
          "lng": 0.0,
          "image": worker["image"],
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        if (reset) {
          _allWorkers = mappedWorkers;
        } else {
          _allWorkers.addAll(mappedWorkers);
        }

        _searchNextCursor = nextCursor;
        _hasMoreSearchResults = nextCursor != null;
      });

      _triggerAnimation(_allWorkers.length);
    } on DioException catch (e) {
      _showMessage(
        e.response?.data?["message"]?.toString() ?? "Failed to search workers",
      );
    } catch (e) {
      _showMessage("Failed to search workers: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWorkers = false;
          _isLoadingMoreSearch = false;
        });
      }
    }
  }

  Future<void> _loadMoreSearchResults() async {
    final search = _searchController.text.trim();

    if (!_isSearchingByName) return;
    if (search.length < 2) return;
    if (_isLoadingMoreSearch) return;
    if (!_hasMoreSearchResults) return;
    if (_searchNextCursor == null) return;

    await _searchWorkersByName(search: search, reset: false);
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _buildAnimations(int count) {
    _slideAnimations.clear();
    _fadeAnimations.clear();
    for (int i = 0; i < count; i++) {
      final start = (i * 0.12).clamp(0.0, 0.85);
      final end = (start + 0.45).clamp(0.0, 1.0);
      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(-0.4, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }
  }

  void _triggerAnimation(int count) {
    _buildAnimations(count);
    _animController.reset();
    _animController.forward();
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
    if (mounted) setState(() => _isLoadingUserLocation = true);
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
        final z = _mapController.camera.zoom == 0
            ? 13.0
            : _mapController.camera.zoom;
        _mapController.move(LatLng(lat, lng), z);
      }
    } on DioException catch (e) {
      _showMessage(
        e.response?.data?["message"]?.toString() ??
            "Failed to load user location",
      );
    } catch (e) {
      _showMessage("Failed to load user location: $e");
    } finally {
      if (mounted) setState(() => _isLoadingUserLocation = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage("Location services are disabled");
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
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
            _showMessage("Could not determine location.");
            return;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _userLat = position!.latitude;
        _userLng = position.longitude;
      });
      if (_useMap)
        _mapController.move(
          LatLng(_userLat!, _userLng!),
          _mapController.camera.zoom == 0 ? 13.0 : _mapController.camera.zoom,
        );
      await _fetchWorkers();
      _showMessage("Showing workers near your current location");
    } on DioException catch (e) {
      _showMessage(
        e.response?.data?["message"]?.toString() ?? "Failed to get location",
      );
    } catch (e) {
      _showMessage("Failed to get location: $e");
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _fetchWorkers() async {
    if (_userLat == null || _userLng == null) return;
    if (mounted) setState(() => _isLoadingWorkers = true);
    try {
      final int limit = _selectedSkill == null ? 15 : 20;
      final queryParameters = <String, dynamic>{
        "lat": _userLat,
        "lng": _userLng,
        "radiusKm": 5,
        "limit": limit,
        "sort": _activeSort,
      };
      if (_selectedSkill != null) queryParameters["skill"] = _selectedSkill;
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
        final profile = Map<String, dynamic>.from(
          worker["workerProfile"] ?? {},
        );
        final location = Map<String, dynamic>.from(worker["location"] ?? {});
        final coords = (location["coordinates"] ?? [0.0, 0.0]) as List;
        final double lng = coords.isNotEmpty
            ? (coords[0] as num).toDouble()
            : 0.0;
        final double lat = coords.length > 1
            ? (coords[1] as num).toDouble()
            : 0.0;
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
      _triggerAnimation(_allWorkers.length);
      if (mounted) setState(() {});
    } on DioException catch (e) {
      _showMessage(
        e.response?.data?["message"]?.toString() ?? "Failed to load workers",
      );
    } catch (e) {
      _showMessage("Failed to load workers: $e");
    } finally {
      if (mounted) setState(() => _isLoadingWorkers = false);
    }
  }

  String _resolveMainJob(List<String> skills) {
    final n = skills.map((e) => e.toLowerCase().trim()).toList();
    if (n.contains('plumbing')) return 'Plumber';
    if (n.contains('Electrical') || n.contains('electrical'))
      return 'Electrician';
    if (n.contains('painting')) return 'Painter';
    if (n.contains('cleaning')) return 'Cleaner';
    if (n.contains('carpentry')) return 'Carpenter';
    return 'Worker';
  }

  void _applyLocalSort() {
    if (_activeSort == 'distance') {
      _allWorkers.sort((a, b) {
        final cmp = (a["distanceValue"] as num).compareTo(
          b["distanceValue"] as num,
        );
        return _distanceAscending ? cmp : -cmp;
      });
    } else if (_activeSort == 'rating') {
      _allWorkers.sort((a, b) {
        final cmp = (b["rating"] as num).compareTo(a["rating"] as num);
        return _ratingDescending ? cmp : -cmp;
      });
    }
  }
  List<Map<String, dynamic>> get _visibleWorkers => List.from(_allWorkers);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E40AF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

Future<void> _onCategoryTap(Category category) async {
  setState(() {
    _selectedSkill = category.apiSkill;
    _activeSort = 'distance';
    _distanceAscending = true;
    _ratingDescending = true;
  });

  final search = _searchController.text.trim();
  if (search.length >= 2) {
    await _searchWorkersByName(search: search, reset: true);
    return;
  }

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

  final search = _searchController.text.trim();
  if (search.length >= 2) {
    _applyLocalSort();
    setState(() {});
    return;
  }

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

  final search = _searchController.text.trim();
  if (search.length >= 2) {
    _applyLocalSort();
    setState(() {});
    return;
  }

  await _fetchWorkers();
}

  // ── Map or placeholder ──
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
            tileProvider: FMTCStore(AppMapConfig.storeName).getTileProvider(),
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
                  .where((w) => w["lat"] != 0 && w["lng"] != 0)
                  .map(
                    (w) => Marker(
                      point: LatLng(w["lat"] as double, w["lng"] as double),
                      width: 44,
                      height: 44,
                      child: _workerPin(w["job"] as String),
                    ),
                  ),
            ],
          ),
        ],
      );
    }

    // Dark navy placeholder to match theme
    return Container(
      color: const Color(0xFF0D1F3C),
      alignment: Alignment.center,
      child: Text(
        "Map view",
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFB4D2FF).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    final visibleWorkers = _visibleWorkers;

    if (_isLoadingUserLocation && _userLat == null && _userLng == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
      );
    }
    if (_userLat == null || _userLng == null) {
      return Center(
        child: Text(
          "Could not load user location",
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
        ),
      );
    }

    return Stack(
      children: [
        // ── Map fills the full screen behind everything ──
        Positioned.fill(child: _buildMapOrPlaceholder(visibleWorkers)),

        // ── Top bar: profile image + search + notification icon ──
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search row
                Row(
                  children: [
                    // Search bar
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF112244).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF63B3FF).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Search worker by name",
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(
                                      0xFFB4D2FF,
                                    ).withOpacity(0.45),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                               onTap: () async {
                                  _searchController.clear();
                                  _searchNextCursor = null;
                                  _hasMoreSearchResults = false;
                                  _isSearchingByName = false;
                                  await _fetchWorkers();
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Notification / profile icon button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF112244).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF63B3FF).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() => _selectedIndex = 4);
                        },
                        icon: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFF63B3FF),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Location button
                _locationButton(),

                const SizedBox(height: 12),

                if (_useMap)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _zoomButtons(),
                  ),
              ],
            ),
          ),
        ),

        // ── Draggable bottom sheet ──
        DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.35,
          maxChildSize: 0.78,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category chips
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _chip(categories[i]),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sort buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Rating sort
                        Expanded(
                          child: GestureDetector(
                            onTap: _onSortRating,
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: _activeSort == 'rating'
                                    ? const Color(0xFF1E40AF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _activeSort == 'rating'
                                      ? const Color(0xFF1E40AF)
                                      : const Color(0xFFDBEAFE),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Rating",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _activeSort == 'rating'
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  if (_activeSort == 'rating') ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      _ratingDescending
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Distance sort
                        Expanded(
                          child: GestureDetector(
                            onTap: _onSortDistance,
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: _activeSort == 'distance'
                                    ? const Color(0xFF1E40AF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _activeSort == 'distance'
                                      ? const Color(0xFF1E40AF)
                                      : const Color(0xFFDBEAFE),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Distance",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _activeSort == 'distance'
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  if (_activeSort == 'distance') ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      _distanceAscending
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Worker list
                  Expanded(
                    child: _isLoadingWorkers
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1E40AF),
                            ),
                          )
                        : visibleWorkers.isEmpty
                        ? Center(
                            child: Text(
                              "No workers found",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _animController,
                            builder: (context, _) {
                              return ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: visibleWorkers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  if (i == visibleWorkers.length - 1) {
                                    _loadMoreSearchResults();
                                  }

                                  if (i >= _slideAnimations.length) {
                                    return WorkerCard(
                                      worker: visibleWorkers[i],
                                    );
                                  }

                                  return FadeTransition(
                                    opacity: _fadeAnimations[i],
                                    child: SlideTransition(
                                      position: _slideAnimations[i],
                                      child: WorkerCard(
                                        worker: visibleWorkers[i],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
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
      
      backgroundColor: const Color(0xFFEFF6FF),
      body: _buildCurrentPage(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF1E40AF),
          unselectedItemColor: const Color(0xFF94A3B8),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description_rounded),
              label: "Requests",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: "Chat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy_rounded),
              label: "AI",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ──

  Widget _locationButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _isGettingLocation ? null : _getCurrentLocation,
        icon: _isGettingLocation
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.my_location_rounded,
                color: Colors.white,
                size: 18,
              ),
        label: Text(
          _isGettingLocation
              ? "Getting location..."
              : "Use My Current Location",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          disabledBackgroundColor: const Color(0xFF1E40AF).withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _chip(Category category) {
    final bool selected = _selectedSkill == category.apiSkill;
    return GestureDetector(
      onTap: () => _onCategoryTap(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E40AF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF1E40AF) : const Color(0xFFDBEAFE),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.key,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 6),
            Image.asset(
              category.value,
              width: 16,
              height: 16,
              fit: BoxFit.contain,
            ),
          ],
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
        color = const Color(0xFF1E40AF);
        break;
      case 'electrician':
        icon = Icons.electrical_services;
        color = const Color(0xFFF59E0B);
        break;
      case 'painter':
        icon = Icons.format_paint;
        color = const Color(0xFF7C3AED);
        break;
      case 'cleaner':
        icon = Icons.cleaning_services;
        color = const Color(0xFF059669);
        break;
      case 'carpenter':
        icon = Icons.handyman;
        color = const Color(0xFF92400E);
        break;
      default:
        icon = Icons.person_pin_circle;
        color = const Color(0xFF94A3B8);
    }
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _userPin() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE24B4A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 22),
    );
  }

  Widget _zoomButtons() {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF112244).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF63B3FF).withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            ),
          ),
          Container(
            height: 1,
            width: 28,
            color: const Color(0xFF63B3FF).withOpacity(0.2),
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white, size: 20),
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            ),
          ),
        ],
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
