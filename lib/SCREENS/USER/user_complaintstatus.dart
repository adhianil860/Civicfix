// user_complaintstatus.dart
// Shows all complaints submitted by the current user.
// Features:
//   - Real-time updates via StreamBuilder
//   - Delete a complaint (only allowed if status is 'Pending')
//   - View complaint location on map (if user pinned a location)
//   - Shows admin remark if admin left a comment

import 'package:civicfic/WIDGETS/empty_state_widget.dart';
import 'package:civicfic/WIDGETS/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/image_service.dart';
import 'package:civicfic/services/notification_service.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:civicfic/screens/complaint_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class UserComplaintstatus extends StatefulWidget {
  const UserComplaintstatus({super.key});

  @override
  State<UserComplaintstatus> createState() => _UserComplaintstatusState();
}

class _UserComplaintstatusState extends State<UserComplaintstatus> {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  // ===== DELETE COMPLAINT =====
  // Only allow deletion if the complaint is still 'Pending'
  void _deleteComplaint(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Complaint'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this complaint?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteComplaint(complaint.id);
                if (mounted) {
                  _notificationService.showSuccess(
                    context,
                    'Complaint deleted successfully',
                  );
                }
              } catch (e) {
                if (mounted) {
                  _notificationService.showError(
                    context,
                    'Failed to delete: $e',
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ===== VIEW COMPLAINT ON MAP =====
  void _viewOnMap(ComplaintModel complaint) {
    // Safety check: only show map if coordinates exist
    if (complaint.latitude == null || complaint.longitude == null) {
      _notificationService.showInfo(
        context,
        'No map location for this complaint',
      );
      return;
    }

    final latLng = LatLng(complaint.latitude!, complaint.longitude!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                complaint.location,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          // FlutterMap shows the OpenStreetMap tiles (free!)
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: latLng,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none, // Read-only, no dragging
                ),
              ),
              children: [
                // OpenStreetMap tiles (free)
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.civicfic',
                ),
                // Red pin marker at the complaint location
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latLng,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: Text(
          "Please login to view complaints",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    return Container(
      color: settings.isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
      // StreamBuilder listens to Firestore stream in real time
      child: StreamBuilder<List<ComplaintModel>>(
        stream: _firestoreService.getUserComplaints(user.uid),
        builder: (context, snapshot) {
          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          // No data
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inbox,
              title: 'No complaints found',
              subtitle: 'Report your first complaint now!',
              onAction: () {},
              actionText: 'Report Complaint',
            );
          }

          // Data — show list of complaint cards
          final complaints = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return _buildComplaintCard(complaint, settings);
            },
          );
        },
      ),
    );
  }

  Widget _buildComplaintCard(
      ComplaintModel complaint, SettingsProvider settings) {
    return GestureDetector(
      key: ValueKey(complaint.id),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailsScreen(
              complaint: complaint,
              isAdmin: false,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: settings.isDarkMode ? Colors.grey[800]! : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER ROW =====
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: complaint.statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    complaint.categoryIcon,
                    color: complaint.statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    complaint.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          settings.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: complaint.statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(complaint.statusIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        complaint.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== CATEGORY & PRIORITY =====
            Row(
              children: [
                _buildChip(
                  complaint.category,
                  settings.isDarkMode ? Colors.grey[700]! : Colors.grey.shade100,
                  settings.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  complaint.priority,
                  _getPriorityColor(complaint.priority).withOpacity(0.15),
                  _getPriorityColor(complaint.priority),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== DESCRIPTION =====
            Text(
               complaint.description,
               style: TextStyle(
                 fontSize: 14,
                 height: 1.4,
                 color: settings.isDarkMode ? Colors.white70 : Colors.black54,
               ),
               maxLines: 2,
               overflow: TextOverflow.ellipsis,
            ),

            if (complaint.imageBase64 != null && complaint.imageBase64!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ImageService.buildImageWidget(
                complaint.imageBase64,
                height: 160,
                borderRadius: BorderRadius.circular(12),
              ),
            ],

            const SizedBox(height: 16),

            // ===== LOCATION & DATE =====
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    complaint.location,
                    style: TextStyle(
                      fontSize: 13,
                      color: settings.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(complaint.createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: settings.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),

            // ===== ADMIN REMARK (only show if admin left a comment) =====
            if (complaint.adminRemark != null &&
                complaint.adminRemark!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: settings.isDarkMode
                      ? Colors.blue.shade900.withOpacity(0.2)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: settings.isDarkMode 
                        ? Colors.blue.withOpacity(0.3) 
                        : Colors.blue.shade200
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 20, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Remark',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            complaint.adminRemark!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              color: settings.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ===== ACTION BUTTONS =====
            Row(
              children: [
                // View on Map button (only show if coordinates exist)
                if (complaint.latitude != null && complaint.longitude != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewOnMap(complaint),
                      icon: Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: settings.isDarkMode
                            ? Colors.white
                            : Colors.blue,
                      ),
                      label: Text(
                        'Map View',
                        style: TextStyle(
                          color: settings.isDarkMode
                              ? Colors.white
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: settings.isDarkMode
                              ? Colors.grey.shade600
                              : Colors.blue.shade300,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                if (complaint.latitude != null && complaint.longitude != null)
                  const SizedBox(width: 12),

                // Delete button (only for Pending complaints)
                if (complaint.status == 'Pending')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteComplaint(complaint),
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.white),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  // Build a small chip/tag widget
  Widget _buildChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day} ${_getMonth(date.month)} ${date.year}";
  }

  String _getMonth(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case "High":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      case "Low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}