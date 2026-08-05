import 'dart:convert' show base64Decode;

import 'package:civicfic/WIDGETS/empty_state_widget.dart';
import 'package:civicfic/WIDGETS/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/notification_service.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class AdminComplaints extends StatefulWidget {
  const AdminComplaints({super.key});

  @override
  State<AdminComplaints> createState() => _AdminComplaintsState();
}

class _AdminComplaintsState extends State<AdminComplaints> {
  String _selectedFilter = 'All';
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Container(
      color: settings.isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
      child: Column(
        children: [
          // Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'All', settings),
                  _buildFilterChip('Pending', 'Pending', settings),
                  _buildFilterChip('In Progress', 'In Progress', settings),
                  _buildFilterChip('Resolved', 'Resolved', settings),
                  _buildFilterChip('Rejected', 'Rejected', settings),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ComplaintModel>>(
              stream: _getComplaintsStream(),
              builder: (context, snapshot) {
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
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.inbox,
                    title: 'No complaints found',
                    subtitle: 'Complaints will appear here',
                  );
                }

                final complaints = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    return _buildComplaintCard(complaint, settings);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<ComplaintModel>> _getComplaintsStream() {
    if (_selectedFilter == 'All') {
      return _firestoreService.getAllComplaints();
    } else {
      return _firestoreService.getFilteredComplaints(_selectedFilter);
    }
  }

  Widget _buildFilterChip(String label, String value, SettingsProvider settings) {
    bool isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'All';
          });
        },
        selectedColor: settings.isDarkMode ? Colors.blue[900] : Colors.blue.shade100,
        checkmarkColor: Colors.blue,
        backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint, SettingsProvider settings) {
    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: complaint.statusColor.withOpacity(0.2),
                  child: Icon(
                    complaint.categoryIcon,
                    color: complaint.statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    complaint.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: settings.isDarkMode ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: complaint.statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    complaint.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Category & Priority & Date
            Wrap(
              spacing: 8,
              children: [
                _buildInfoChip(complaint.category, Colors.grey, settings),
                _buildPriorityChip(complaint.priority, settings),
                _buildInfoChip(
                  '${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
                  Colors.grey,
                  settings,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              complaint.description,
              style: TextStyle(
                fontSize: 14,
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // User & Location
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    complaint.userName,
                    style: TextStyle(
                      fontSize: 13,
                      color: settings.isDarkMode ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    complaint.location,
                    style: TextStyle(
                      fontSize: 13,
                      color: settings.isDarkMode ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showComplaintDetails(complaint, settings);
                    },
                    icon: Icon(
                      Icons.visibility,
                      size: 18,
                      color: settings.isDarkMode ? Colors.white : Colors.blue,
                    ),
                    label: Text(
                      "View",
                      style: TextStyle(
                        color: settings.isDarkMode ? Colors.white : Colors.blue,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: settings.isDarkMode ? Colors.white : Colors.blue,
                      side: BorderSide(
                        color: settings.isDarkMode ? Colors.grey.shade600 : Colors.blue,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showUpdateStatusDialog(complaint.id, complaint.status, settings);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Update"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: settings.isDarkMode ? Colors.grey[700] : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: settings.isDarkMode ? Colors.white : color,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority, SettingsProvider settings) {
    Color color;
    switch (priority) {
      case "High":
        color = Colors.red;
        break;
      case "Medium":
        color = Colors.orange;
        break;
      case "Low":
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: settings.isDarkMode ? Colors.grey[700] : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 12,
          color: settings.isDarkMode ? Colors.white : color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ========== VIEW COMPLAINT DETAILS ==========
  void _showComplaintDetails(ComplaintModel complaint, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          complaint.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow("Category", complaint.category, settings),
                _detailRow("Priority", complaint.priority, settings),
                _detailRow("Location", complaint.location, settings),
                _detailRow("User", complaint.userName, settings),
                _detailRow("Email", complaint.userEmail, settings),
                _detailRow("Status", complaint.status, settings),
                const SizedBox(height: 12),
                Divider(color: settings.isDarkMode ? Colors.grey[700] : Colors.grey.shade200),
                const SizedBox(height: 12),
                Text(
                  "Description:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: settings.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  complaint.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: settings.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                if (complaint.imageBase64 != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Image:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: settings.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(complaint.imageBase64!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== UPDATE STATUS DIALOG ==========
  void _showUpdateStatusDialog(String docId, String currentStatus, SettingsProvider settings) {
    String selectedStatus = currentStatus;
    List<String> statuses = ['Pending', 'In Progress', 'Resolved', 'Rejected'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          'Update Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: selectedStatus,
              dropdownColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
              items: statuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status,
                    style: TextStyle(
                      color: settings.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'Select Status',
                labelStyle: TextStyle(
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.edit_note,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.updateComplaintStatus(docId, selectedStatus);

                NotificationService().showSuccess(
                  context,
                  'Status updated to $selectedStatus',
                );
              } catch (e) {
                NotificationService().showError(
                  context,
                  'Error: $e',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}