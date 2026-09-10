// notification_model.dart
// This file defines the data structure for a notification stored in Firestore.

class NotificationModel {
  final String id; // Firestore document ID
  final String userId; // Which user gets this notification
  final String title; // Short title e.g. "Complaint Updated"
  final String message; // Full message e.g. "Your complaint 'Road Damage' is now Resolved"
  final String complaintId; // Which complaint this is about
  final String newStatus; // The new status set by admin
  final bool isRead; // Has the user read this?
  final DateTime createdAt; // When was this created

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.complaintId,
    required this.newStatus,
    this.isRead = false,
    required this.createdAt,
  });

  // Convert NotificationModel to a Map to save in Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'complaintId': complaintId,
      'newStatus': newStatus,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  // Create a NotificationModel from a Firestore document
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      complaintId: map['complaintId'] ?? '',
      newStatus: map['newStatus'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as dynamic).toDate(),
    );
  }
}
