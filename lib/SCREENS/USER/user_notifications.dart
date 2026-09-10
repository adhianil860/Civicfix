// user_notifications.dart
// This screen shows all notifications for the current user.
// It uses StreamBuilder so the list updates in REAL TIME — no page refresh needed!

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/models/notification_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class UserNotificationsScreen extends StatelessWidget {
  const UserNotificationsScreen({super.key});

  // Helper: get color based on the status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange; // Pending
    }
  }

  // Helper: get icon based on the status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Resolved':
        return Icons.check_circle;
      case 'In Progress':
        return Icons.sync;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  // Format date to readable format: "14 Aug 2026, 2:30 PM"
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    String hour = date.hour > 12
        ? (date.hour - 12).toString()
        : date.hour.toString();
    String minute = date.minute.toString().padLeft(2, '0');
    String period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    // If user is not logged in, show message
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      backgroundColor:
          settings.isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            settings.isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor:
            settings.isDarkMode ? Colors.white : Colors.blue.shade700,
        elevation: 0,
        // "Mark all as read" button in the top-right corner
        actions: [
          TextButton(
            onPressed: () async {
              // Mark all unread notifications as read
              await firestoreService.markAllNotificationsRead(user.uid);
            },
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: settings.isDarkMode
                    ? Colors.blue.shade200
                    : Colors.blue,
              ),
            ),
          ),
        ],
      ),
      // StreamBuilder listens to the Firestore stream
      // Whenever a new notification is added, the UI rebuilds automatically!
      body: StreamBuilder<List<NotificationModel>>(
        stream: firestoreService.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          // Still loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error occurred
          if (snapshot.hasError) {
            print(snapshot.error);
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // No notifications yet
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 70,
                    color: settings.isDarkMode
                        ? Colors.grey[600]
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: settings.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll get notified when admin\nupdates your complaint status',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: settings.isDarkMode
                          ? Colors.grey[600]
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          // We have notifications — show them in a list
          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(
                notification,
                settings,
                firestoreService,
              );
            },
          );
        },
      ),
    );
  }

  // Build a single notification card
  Widget _buildNotificationCard(
    NotificationModel notification,
    SettingsProvider settings,
    FirestoreService firestoreService,
  ) {
    final statusColor = _getStatusColor(notification.newStatus);
    final statusIcon = _getStatusIcon(notification.newStatus);
    final isUnread = !notification.isRead;

    return GestureDetector(
      key: ValueKey(notification.id),
      behavior: HitTestBehavior.opaque,
      // When user taps the card, mark it as read
      onTap: () {
        if (isUnread) {
          firestoreService.markNotificationRead(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          // Unread notifications have a colored left border
          border: Border(
            left: BorderSide(
              color: isUnread ? statusColor : Colors.transparent,
              width: 4,
            ),
          ),
          color: isUnread
              ? (settings.isDarkMode
                  ? statusColor.withOpacity(0.15)
                  : statusColor.withOpacity(0.08))
              : (settings.isDarkMode ? Colors.grey[850] : Colors.white),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status icon circle
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Notification text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with unread dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 15,
                              color: settings.isDarkMode
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                        // Blue dot for unread
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: settings.isDarkMode
                            ? Colors.grey[300]
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Timestamp
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: settings.isDarkMode
                            ? Colors.grey[500]
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
