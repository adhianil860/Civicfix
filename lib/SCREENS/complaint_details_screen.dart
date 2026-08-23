import 'package:flutter/material.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/models/notification_model.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/image_service.dart';
import 'package:civicfic/services/notification_service.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final ComplaintModel complaint;
  final bool isAdmin;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaint,
    this.isAdmin = false,
  });

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  late ComplaintModel _complaint;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
  }

  // Full-screen image viewer dialog with interactive zoom
  void _openFullScreenImage() {
    if (_complaint.imageBase64 == null || _complaint.imageBase64!.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(_complaint.title, style: const TextStyle(fontSize: 16)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ImageService.buildImageWidget(
                _complaint.imageBase64,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // View Location Map modal
  void _showMapDialog() {
    if (_complaint.latitude == null || _complaint.longitude == null) return;
    final point = LatLng(_complaint.latitude!, _complaint.longitude!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _complaint.location,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          height: 320,
          width: double.maxFinite,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Admin: Update Status Dialog
  void _showUpdateStatusDialog(bool isDark) {
    String selectedStatus = _complaint.status;
    final remarkController = TextEditingController(text: _complaint.adminRemark ?? '');
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
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Update Status', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      dropdownColor: isDark ? Colors.grey[850] : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                      icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      items: updateOptions.map((status) {
                        return DropdownMenuItem(value: status, child: Text(status));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedStatus = val);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: remarkController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Admin Remark (Optional)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateStatus(selectedStatus, remarkController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Update', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateStatus(String newStatus, String remark) async {
    try {
      await _firestoreService.updateComplaintStatus(
        _complaint.id,
        newStatus,
        adminRemark: remark.isEmpty ? null : remark,
      );

      String msg = 'Your complaint "${_complaint.title}" status changed to $newStatus.';
      if (remark.isNotEmpty) msg += ' Remark: $remark';

      final notification = NotificationModel(
        id: '',
        userId: _complaint.userId,
        title: 'Complaint Status Updated',
        message: msg,
        complaintId: _complaint.id,
        newStatus: newStatus,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _firestoreService.addNotification(notification);

      setState(() {
        _complaint = ComplaintModel(
          id: _complaint.id,
          title: _complaint.title,
          description: _complaint.description,
          category: _complaint.category,
          priority: _complaint.priority,
          location: _complaint.location,
          imageBase64: _complaint.imageBase64,
          userId: _complaint.userId,
          userName: _complaint.userName,
          userEmail: _complaint.userEmail,
          status: newStatus,
          createdAt: _complaint.createdAt,
          updatedAt: DateTime.now(),
          latitude: _complaint.latitude,
          longitude: _complaint.longitude,
          adminRemark: remark.isEmpty ? null : remark,
        );
      });

      if (mounted) {
        NotificationService().showSuccess(context, 'Complaint status updated!');
      }
    } catch (e) {
      if (mounted) {
        NotificationService().showError(context, 'Error updating complaint: $e');
      }
    }
  }

  // Confirm Delete
  void _confirmDelete(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Complaint'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_complaint.title}"?\nThis action cannot be undone.',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteComplaint(_complaint.id);
                if (mounted) {
                  NotificationService().showSuccess(context, 'Complaint deleted');
                  Navigator.pop(context); // Go back after delete
                }
              } catch (e) {
                if (mounted) {
                  NotificationService().showError(context, 'Failed to delete: $e');
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String hour = date.hour > 12 ? (date.hour - 12).toString() : (date.hour == 0 ? '12' : date.hour.toString());
    String minute = date.minute.toString().padLeft(2, '0');
    String period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final hasImage = _complaint.imageBase64 != null && _complaint.imageBase64!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Collapsible Header Bar with Image Preview
          SliverAppBar(
            expandedHeight: hasImage ? 280 : 160,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage
                  ? GestureDetector(
                      onTap: _openFullScreenImage,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ImageService.buildImageWidget(
                            _complaint.imageBase64,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.4),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tap to Zoom',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(_complaint.categoryIcon, size: 60, color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
            ),
          ),

          // Main Body Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _complaint.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _complaint.statusColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _complaint.statusColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_complaint.statusIcon, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _complaint.status,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category, Priority, Date Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(_complaint.category, const Color(0xFF2563EB).withOpacity(0.1), const Color(0xFF2563EB)),
                      _buildChip('${_complaint.priority} Priority', _getPriorityColor(_complaint.priority).withOpacity(0.1), _getPriorityColor(_complaint.priority)),
                      _buildChip(_formatDate(_complaint.createdAt), isDark ? Colors.grey[800]! : Colors.grey[200]!, isDark ? Colors.grey[300]! : Colors.grey[700]!),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description Card
                  _buildSectionCard(
                    title: 'Description',
                    icon: Icons.description_outlined,
                    isDark: isDark,
                    child: Text(
                      _complaint.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Card
                  _buildSectionCard(
                    title: 'Location',
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _complaint.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                        ),
                        if (_complaint.latitude != null && _complaint.longitude != null) ...[
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _showMapDialog,
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('Map View'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reporter Info Card (Shown to Admin)
                  if (widget.isAdmin) ...[
                    _buildSectionCard(
                      title: 'Reporter Details',
                      icon: Icons.person_outline,
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailText('Name', _complaint.userName, isDark),
                          const SizedBox(height: 6),
                          _buildDetailText('Email', _complaint.userEmail, isDark),
                          const SizedBox(height: 6),
                          _buildDetailText('User ID', _complaint.userId, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Admin Remark Card (If present)
                  if (_complaint.adminRemark != null && _complaint.adminRemark!.trim().isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Admin Remark',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _complaint.adminRemark!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bottom Action Buttons
                  if (widget.isAdmin)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showUpdateStatusDialog(isDark),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Update Status'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _confirmDelete(isDark),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    )
                  else if (_complaint.status == 'Pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDelete(isDark),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete Complaint'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

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

  Widget _buildDetailText(String label, String value, bool isDark) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.black87),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
