import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_picker/map_picker.dart';
import 'package:provider/provider.dart';
import 'package:civicfic/providers/settings_provider.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapPickerController _controller = MapPickerController();
  late LatLng _currentPosition;

  @override
  void initState() {
    super.initState();
    // Default coordinates (e.g. Kerala, India: 10.0, 76.0)
    _currentPosition = const LatLng(10.0, 76.0);
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
        backgroundColor: isDark ? Colors.grey[900] : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, size: 28),
            tooltip: 'Confirm selection',
            onPressed: () {
              Navigator.pop(
                context,
                MapPickerResult(
                  latitude: _currentPosition.latitude,
                  longitude: _currentPosition.longitude,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MapPicker(
            mapPickerController: _controller,
            iconWidget: Icon(
              Icons.location_on,
              color: isDark ? Colors.tealAccent : Colors.redAccent,
              size: 50,
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 15.0,
                onPositionChanged: (camera, hasGesture) {
                  _currentPosition = camera.center;
                },
                onMapEvent: (event) {
                  if (event is MapEventMoveStart) {
                    _controller.mapMoving?.call();
                  } else if (event is MapEventMoveEnd) {
                    _controller.mapFinishedMoving?.call();
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.civicfic.app',
                  tileProvider: NetworkTileProvider(),
                  // Apply inverted/dark styling for tiles if in dark mode
                  tileBuilder: isDark
                      ? (context, tileWidget, tile) {
                          return ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              -0.9, 0.0, 0.0, 0.0, 255.0, // red
                              0.0, -0.9, 0.0, 0.0, 255.0, // green
                              0.0, 0.0, -0.9, 0.0, 255.0, // blue
                              0.0, 0.0, 0.0, 1.0, 0.0,    // alpha
                            ]),
                            child: tileWidget,
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
          
          // Bottom confirmation card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: isDark ? Colors.tealAccent : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Drag map to align the pin to the complaint location.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
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
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              MapPickerResult(
                                latitude: _currentPosition.latitude,
                                longitude: _currentPosition.longitude,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.teal : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm Location',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  MapPickerResult({
    required this.latitude,
    required this.longitude,
  });
}
