import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';
import 'package:civicfic/WIDGETS/empty_state_widget.dart';
import 'package:civicfic/WIDGETS/loading_widget.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/image_service.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/models/notification_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:civicfic/screens/complaint_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminComplaints extends StatefulWidget {
  const AdminComplaints({super.key});

  @override
  State<AdminComplaints> createState() => _AdminComplaintsState();
}

class _AdminComplaintsState extends State<AdminComplaints> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedFilter = 'All'; // Filter by status
  String _searchQuery = ''; // Search by title
  
  // Status options for filtering and updating
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'In Progress',
    'Resolved',
    'Rejected'
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: Column(
        children: [
          // Search Bar for local filtering by title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by title...',
                  hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          // Filter chips for status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: _statusOptions.map((status) {
                final isSelected = _selectedFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      status,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? (isDark ? Colors.white : Colors.blue.shade900) 
                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = status;
                      });
                    },
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    selectedColor: const Color(0xFF2563EB).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected 
                            ? const Color(0xFF2563EB).withOpacity(0.5) 
                            : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 10),

          // Real-time Complaints List
          Expanded(
            child: StreamBuilder<List<ComplaintModel>>(
              stream: _firestoreService.getAllComplaints(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: TextStyle(color: isDark ? Colors.white : Colors.black))
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No complaints found',
                    subtitle: 'Complaints submitted by citizens will appear here',
                    icon: Icons.inbox,
                  );
                }

                // Filter data locally based on status and search query
                List<ComplaintModel> filteredComplaints = snapshot.data!.where((complaint) {
                  final matchesFilter = _selectedFilter == 'All' || complaint.status == _selectedFilter;
                  final matchesSearch = complaint.title.toLowerCase().contains(_searchQuery);
                  return matchesFilter && matchesSearch;
                }).toList();

                if (filteredComplaints.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No matching complaints',
                    subtitle: 'Try adjusting your search query or filter',
                    icon: Icons.search_off,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredComplaints.length,
                  itemBuilder: (context, index) {
                    final complaint = filteredComplaints[index];
                    return _buildComplaintCard(complaint, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget for building individual complaint cards
  Widget _buildComplaintCard(ComplaintModel complaint, bool isDark) {
    return GestureDetector(
      key: ValueKey(complaint.id),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailsScreen(
              complaint: complaint,
              isAdmin: true,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Title and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.category, size: 16, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              complaint.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint.category,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(complaint.status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description preview
            Text(
              complaint.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
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
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComplaintDetailsScreen(
                              complaint: complaint,
                              isAdmin: true,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    if (complaint.latitude != null && complaint.longitude != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('Map'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        ),
                        onPressed: () => _showMapDialog(complaint, isDark),
                      ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showUpdateStatusDialog(complaint, isDark),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 24,
                      onPressed: () => _showDeleteConfirmation(complaint, isDark),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  // Helper widget to display status badge
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'In Progress':
        color = Colors.blue;
        break;
      case 'Resolved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Dialog to view full complaint details
  void _showDetailsDialog(ComplaintModel complaint, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Complaint Details', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (complaint.imageBase64 != null && complaint.imageBase64!.isNotEmpty)
                  ImageService.buildImageWidget(
                    complaint.imageBase64,
                    height: 220,
                    borderRadius: BorderRadius.circular(12),
                  ),
                const SizedBox(height: 16),
                _detailRow('Title:', complaint.title, isDark),
                _detailRow('Category:', complaint.category, isDark),
                _detailRow('Status:', complaint.status, isDark),
                _detailRow('Date:', complaint.createdAt.toString().split('.')[0], isDark),
                const SizedBox(height: 12),
                Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 6),
                Text(complaint.description, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black54, height: 1.5)),
                if (complaint.adminRemark != null && complaint.adminRemark!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: isDark ? Colors.blue[300] : Colors.blue[700]),
                            const SizedBox(width: 6),
                            Text('Admin Remark', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue[300] : Colors.blue[700])),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(complaint.adminRemark!, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Helper for detail rows
  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black54))),
        ],
      ),
    );
  }

  // Dialog to view complaint location on map
  void _showMapDialog(ComplaintModel complaint, bool isDark) {
    if (complaint.latitude == null || complaint.longitude == null) return;
    
    final point = LatLng(complaint.latitude!, complaint.longitude!);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Location', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          contentPadding: const EdgeInsets.all(16),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 300,
              width: double.maxFinite,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.civicfix',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Dialog to update complaint status and add remark
  void _showUpdateStatusDialog(ComplaintModel complaint, bool isDark) {
    String selectedStatus = complaint.status;
    TextEditingController remarkController = TextEditingController(text: complaint.adminRemark ?? '');
    
    // Status options for the dropdown (exclude 'All')
    final List<String> updateOptions = ['Pending', 'In Progress', 'Resolved', 'Rejected'];
    
    if (!updateOptions.contains(selectedStatus)) {
        selectedStatus = updateOptions.first;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text('Update Status', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
                      icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      items: updateOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Status',
                        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: remarkController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Admin Remark (Optional)',
                        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    _updateComplaintAndNotify(complaint, selectedStatus, remarkController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Handle update status and create notification
  Future<void> _updateComplaintAndNotify(ComplaintModel complaint, String newStatus, String remark) async {
    try {
      // 1. Update the complaint in Firestore
      await _firestoreService.updateComplaintStatus(
        complaint.id, 
        newStatus, 
        adminRemark: remark.isEmpty ? null : remark,
      );
      
      // 2. Auto-create a notification for the user
      String msg = 'Your complaint "${complaint.title}" has been updated to $newStatus.';
      if (remark.isNotEmpty) {
        msg += ' Admin remark: $remark';
      }
      
      final notification = NotificationModel(
        id: '', // Will be set by Firestore (or handled internally)
        userId: complaint.userId,
        title: 'Complaint Updated',
        message: msg,
        complaintId: complaint.id,
        newStatus: newStatus,
        createdAt: DateTime.now(),
        isRead: false,
      );
      
      await _firestoreService.addNotification(notification);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating complaint: $e')),
        );
      }
    }
  }

  // Dialog to confirm deletion
  void _showDeleteConfirmation(ComplaintModel complaint, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 8),
              Text('Delete Complaint', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${complaint.title}"? This action cannot be undone.',
            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                try {
                  await _firestoreService.deleteComplaint(complaint.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Complaint deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting complaint: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}