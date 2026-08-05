import 'package:civicfic/WIDGETS/empty_state_widget.dart';
import 'package:civicfic/WIDGETS/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/notification_service.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class UserComplaintstatus extends StatefulWidget {
  const UserComplaintstatus({super.key});

  @override
  State<UserComplaintstatus> createState() => _UserComplaintstatusState();
}

class _UserComplaintstatusState extends State<UserComplaintstatus> {
  final FirestoreService _firestoreService = FirestoreService();

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
                    onPressed: () {
                      setState(() {});
                    },
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
              onAction: () {
                // Navigate to report complaint
              },
              actionText: 'Report Complaint',
            );
          }

          // Data
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
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint, SettingsProvider settings) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: settings.isDarkMode ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                      Icon(
                        complaint.statusIcon,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        complaint.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Category & Priority
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: settings.isDarkMode ? Colors.grey[700] : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    complaint.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: settings.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(complaint.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    complaint.priority,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
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

            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    complaint.location,
                    style: TextStyle(
                      fontSize: 14,
                      color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
                const SizedBox(width: 5),
                Text(
                  _formatDate(complaint.createdAt),
                  style: TextStyle(
                    fontSize: 14,
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
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