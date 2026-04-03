import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:frontend/core/map/map_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({super.key});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final MapController _mapController = MapController();

  LatLng? selectedLocation;
  bool _isGettingCurrentLocation = false;
  bool _mapReady = false;

  static final LatLng _initialLocation = LatLng(31.9539, 35.9106); // Amman

  @override
  void initState() {
    super.initState();
    selectedLocation = _initialLocation;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapReady = true;
      _setInitialCurrentLocation();
    });
  }

  Future<void> _setInitialCurrentLocation() async {
    try {
      final location = await _getDeviceLocation(showErrors: false);
      if (location == null || !mounted) return;

      setState(() {
        selectedLocation = location;
      });

      if (_mapReady) {
        _mapController.move(location, 15);
      }
    } catch (_) {
      // fallback silently
    }
  }

  Future<LatLng?> _getDeviceLocation({bool showErrors = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showErrors) _showMessage("Location services are disabled");
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (showErrors) _showMessage("Location permission denied");
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      if (showErrors) {
        _showMessage("Location permission permanently denied");
      }
      return null;
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
      }
    }

    if (position == null) {
      if (showErrors) {
        _showMessage("Could not determine your current location");
      }
      return null;
    }

    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _useCurrentLocation() async {
    if (_isGettingCurrentLocation) return;

    setState(() {
      _isGettingCurrentLocation = true;
    });

    try {
      final location = await _getDeviceLocation(showErrors: true);
      if (location == null || !mounted) return;

      setState(() {
        selectedLocation = location;
      });

      if (_mapReady) {
        _mapController.move(location, 15);
      }

      _showMessage("Current location selected");
    } finally {
      if (mounted) {
        setState(() {
          _isGettingCurrentLocation = false;
        });
      }
    }
  }

  void _confirmLocation() {
    if (selectedLocation == null) {
      _showMessage("Please select a location first");
      return;
    }

    Navigator.pop(context, {
      "lat": selectedLocation!.latitude,
      "lng": selectedLocation!.longitude,
      "address": "Selected Location",
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedLocation ?? _initialLocation,
              initialZoom: 14,
              onTap: (_, point) {
                setState(() {
                  selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppMapConfig.tileUrl,
                userAgentPackageName: AppMapConfig.userAgent,
                tileProvider:
                    FMTCStore(AppMapConfig.storeName).getTileProvider(),
              ),
              if (selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        size: 45,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      _isGettingCurrentLocation ? null : _useCurrentLocation,
                  icon: _isGettingCurrentLocation
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
                    _isGettingCurrentLocation
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12BFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Confirm Location",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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