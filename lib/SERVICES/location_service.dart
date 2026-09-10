import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check GPS enabled status and permissions with user dialog pop-ups
  Future<bool> checkLocationPermissionAndService(BuildContext context) async {
    // 1. Check if location services (GPS) are enabled on device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.location_off_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Turn On Location (GPS)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Your mobile device\'s Location Services (GPS) are currently turned OFF.\n\nPlease turn ON GPS to allow CivicFix to track your live position on the map and detect your municipality.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings_remote, size: 18),
                label: const Text('Turn On Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openLocationSettings();
                },
              ),
            ],
          ),
        );
      }
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    // 2. Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (context.mounted) {
        bool? allow = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.my_location_rounded, color: Color(0xFF4F46E5), size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Location Permission Needed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: const Text(
              'CivicFix needs your permission to access your mobile device\'s live GPS location.\n\nThis is used to show your live location on the map and automatically set the issue address.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Allow Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (allow != true) return false;
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission was denied by user.')),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.security_rounded, color: Colors.redAccent, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Permission Blocked in Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Location permission is permanently denied in your mobile settings.\n\nPlease open App Settings and grant Location permission for CivicFix.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Open App Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openAppSettings();
                },
              ),
            ],
          ),
        );
      }
      return false;
    }

    return true;
  }

  /// Get current live GPS position
  Future<Position?> getCurrentPosition(BuildContext context) async {
    bool hasPermission = await checkLocationPermissionAndService(context);
    if (!hasPermission) return null;

    try {
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return pos;
    } catch (e) {
      // Fallback to last known position
      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) return lastPos;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch live GPS position: $e')),
        );
      }
      return null;
    }
  }

  /// Reverse geocode coordinates to full human-readable address
  Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {'User-Agent': 'CivicFixApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'].toString();
        }
      }
    } catch (_) {}

    return 'Location (${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
  }

  /// Automatically identify Municipality based on coordinates and address keywords
  String detectMunicipality(double latitude, double longitude, String address) {
    String lowerAddr = address.toLowerCase();

    // 1. Keyword check for Thrikkakara Municipality
    final thrikkakaraKeywords = [
      'thrikkakara',
      'kakkanad',
      'edachira',
      'infopark',
      'chittethukara',
      'vazhakkala',
      'padamugal',
      'triveni'
    ];
    for (var kw in thrikkakaraKeywords) {
      if (lowerAddr.contains(kw)) {
        return 'Thrikkakara Municipality';
      }
    }

    // 2. Keyword check for Kalamassery Municipality
    final kalamasseryKeywords = [
      'kalamassery',
      'cusat',
      'hmt',
      'premier',
      'glass factory',
      'south kalamassery',
      'njalakam',
      'pathadipalam'
    ];
    for (var kw in kalamasseryKeywords) {
      if (lowerAddr.contains(kw)) {
        return 'Kalamassery Municipality';
      }
    }

    // 3. Geofence Bounding Box Check for Kochi Regions
    // Thrikkakara (approx lat: 9.98 to 10.05, long: 76.32 to 76.38)
    if (latitude >= 9.98 && latitude <= 10.05 && longitude >= 76.32 && longitude <= 76.38) {
      return 'Thrikkakara Municipality';
    }

    // Kalamassery (approx lat: 10.02 to 10.09, long: 76.30 to 76.36)
    if (latitude >= 10.02 && latitude <= 10.09 && longitude >= 76.30 && longitude <= 76.36) {
      return 'Kalamassery Municipality';
    }

    // Default to nearest municipality (e.g. Thrikkakara Municipality)
    return 'Thrikkakara Municipality';
  }

  /// Calculate distance in meters using Haversine formula
  double calculateDistanceMeters(double lat1, double lng1, double lat2, double lng2) {
    final Distance distance = const Distance();
    return distance.as(LengthUnit.Meter, LatLng(lat1, lng1), LatLng(lat2, lng2));
  }

  /// Display a modal popup box displaying live location details for user on mobile
  static Future<void> showLocationDetailsDialog({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String address,
    required String municipality,
    VoidCallback? onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location_rounded, color: Color(0xFF4F46E5), size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Live Location Detected',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CivicFix successfully locked your live GPS location:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, color: Color(0xFF4F46E5), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        municipality,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'GPS: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          if (onConfirm != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('Use Location'),
            ),
        ],
      ),
    );
  }
}
