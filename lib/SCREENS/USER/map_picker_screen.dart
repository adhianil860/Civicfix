import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_picker/map_picker.dart';
import 'package:provider/provider.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:civicfic/services/location_service.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapPickerController _controller = MapPickerController();
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  late LatLng _currentPosition;
  LatLng? _userLivePosition;
  String _detectedAddress = 'Align pin or tap GPS button...';
  String _detectedMunicipality = 'Detecting...';
  bool _isFetchingGPS = false;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    // Default coordinates: Kochi/Kerala (10.0261, 76.3125)
    _currentPosition = const LatLng(10.0261, 76.3125);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLiveGPSLocation(showPopup: true);
    });
  }

  Future<void> _fetchLiveGPSLocation({bool showPopup = false}) async {
    setState(() => _isFetchingGPS = true);
    final pos = await _locationService.getCurrentPosition(context);
    if (pos != null && mounted) {
      final newPos = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentPosition = newPos;
        _userLivePosition = newPos;
      });
      _mapController.move(newPos, 16.5);
      await _updateAddressAndMunicipality(newPos.latitude, newPos.longitude);

      if (showPopup && mounted) {
        LocationService.showLocationDetailsDialog(
          context: context,
          latitude: newPos.latitude,
          longitude: newPos.longitude,
          address: _detectedAddress,
          municipality: _detectedMunicipality,
          onConfirm: () => _confirmAndPop(),
        );
      }
    }
    if (mounted) {
      setState(() => _isFetchingGPS = false);
    }
  }

  Future<void> _updateAddressAndMunicipality(double lat, double lng) async {
    setState(() => _isGeocoding = true);
    String addr = await _locationService.reverseGeocode(lat, lng);
    String muni = _locationService.detectMunicipality(lat, lng, addr);
    if (mounted) {
      setState(() {
        _detectedAddress = addr;
        _detectedMunicipality = muni;
        _isGeocoding = false;
      });
    }
  }

  void _confirmAndPop() {
    Navigator.pop(
      context,
      MapPickerResult(
        latitude: _currentPosition.latitude,
        longitude: _currentPosition.longitude,
        address: _detectedAddress,
        municipality: _detectedMunicipality,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Location',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 24),
            tooltip: 'View Location Details Box',
            onPressed: () {
              LocationService.showLocationDetailsDialog(
                context: context,
                latitude: _currentPosition.latitude,
                longitude: _currentPosition.longitude,
                address: _detectedAddress,
                municipality: _detectedMunicipality,
                onConfirm: _confirmAndPop,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 28),
            tooltip: 'Confirm selection',
            onPressed: _confirmAndPop,
          ),
        ],
      ),
      body: Stack(
        children: [
          MapPicker(
            mapPickerController: _controller,
            iconWidget: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: isDark ? const Color(0xFF0D9488) : const Color(0xFF4F46E5),
                size: 42,
              ),
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 16.0,
                onPositionChanged: (camera, hasGesture) {
                  _currentPosition = camera.center;
                },
                onMapEvent: (event) {
                  if (event is MapEventMoveStart) {
                    _controller.mapMoving?.call();
                  } else if (event is MapEventMoveEnd) {
                    _controller.mapFinishedMoving?.call();
                    _updateAddressAndMunicipality(_currentPosition.latitude, _currentPosition.longitude);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.civicfic.app',
                  tileProvider: NetworkTileProvider(),
                  tileBuilder: isDark
                      ? (context, tileWidget, tile) {
                          return ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              -0.9, 0.0, 0.0, 0.0, 255.0,
                              0.0, -0.9, 0.0, 0.0, 255.0,
                              0.0, 0.0, -0.9, 0.0, 255.0,
                              0.0, 0.0, 0.0, 1.0, 0.0,
                            ]),
                            child: tileWidget,
                          );
                        }
                      : null,
                ),

                // Live User Location Marker Layer on Map
                if (_userLivePosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userLivePosition!,
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.25),
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.blueAccent, blurRadius: 6)],
                              ),
                              child: const Icon(Icons.my_location, color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Floating GPS Live Location Button
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton.extended(
              heroTag: 'live_gps_btn',
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
              elevation: 4,
              onPressed: _isFetchingGPS ? null : () => _fetchLiveGPSLocation(showPopup: true),
              icon: _isFetchingGPS
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.my_location, size: 22),
              label: Text(
                _isFetchingGPS ? 'Locating...' : 'Live GPS',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),

          // Bottom Address & Confirmation Card / Pop-up Box
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF4F46E5),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Detected Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (_isGeocoding) ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(strokeWidth: 1.5),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _detectedAddress,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '🏛️ $_detectedMunicipality',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.grey[700],
                            side: BorderSide(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirmAndPop,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm Location',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== MAP PICKER RESULT CLASS ==========
class MapPickerResult {
  final double latitude;
  final double longitude;
  final String address;
  final String municipality;

  MapPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.municipality,
  });
}
