import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/complaint_model.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import 'location_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== Get current user ==========
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // ========== USER OPERATIONS ==========

  // Save user
  Future<void> saveUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  // Get user
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    } catch (e) {
      return null;
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      final doc = query.docs.first;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ========== COMPLAINT OPERATIONS ==========

  // Add complaint (with strict duplicate prevention within 50 meters)
  Future<void> addComplaint(ComplaintModel complaint) async {
    if (complaint.latitude != null && complaint.longitude != null) {
      final nearby = await getNearbyComplaints(
        complaint.latitude!,
        complaint.longitude!,
        maxDistanceMeters: 50.0,
      );

      for (var existing in nearby) {
        if (existing.status == 'Rejected' || existing.status == 'Resolved') continue;

        if (existing.id.isNotEmpty) {
          // Automatic Deduplication: Increment support count on existing complaint
          await supportComplaint(existing.id, complaint.userId);
          return;
        }
      }
    }

    await _firestore.collection('complaints').add(complaint.toMap());
  }

  // Get user complaints (Stream) - Includes authored & supported complaints
  Stream<List<ComplaintModel>> getUserComplaints(String userId) {
    return _firestore
        .collection('complaints')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(
                doc.data(),
                doc.id,
              ))
          .where((complaint) =>
              complaint.userId == userId ||
              complaint.supportedUserIds.contains(userId))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get all complaints (Stream)
  Stream<List<ComplaintModel>> getAllComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList());
  }

  // Get filtered complaints (Stream)
  Stream<List<ComplaintModel>> getFilteredComplaints(String status) {
    if (status == 'All') {
      return getAllComplaints();
    }
    return _firestore
        .collection('complaints')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(
                doc.data(),
                doc.id,
              ))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Update complaint status (with optional admin remark)
  Future<void> updateComplaintStatus(
    String docId,
    String status, {
    String? adminRemark, // Optional comment from admin
  }) async {
    await _firestore.collection('complaints').doc(docId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
      if (adminRemark != null && adminRemark.isNotEmpty)
        'adminRemark': adminRemark, // Only save if remark is not empty
    });
  }

  // Delete complaint
  Future<void> deleteComplaint(String docId) async {
    await _firestore.collection('complaints').doc(docId).delete();
  }

  // Support / Upvote an existing complaint
  Future<void> supportComplaint(String complaintId, String userId) async {
    await _firestore.collection('complaints').doc(complaintId).update({
      'supportCount': FieldValue.increment(1),
      'supportedUserIds': FieldValue.arrayUnion([userId]),
    });
  }

  // Get active complaints near location (within 50 meters radius)
  Future<List<ComplaintModel>> getNearbyComplaints(
    double latitude,
    double longitude, {
    double maxDistanceMeters = 50.0,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('complaints')
          .get();

      List<ComplaintModel> nearby = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'Pending';
        if (status == 'Rejected' || status == 'Resolved') continue;

        final double? lat = data['latitude']?.toDouble();
        final double? lng = data['longitude']?.toDouble();
        if (lat == null || lng == null) continue;

        double distance = LocationService().calculateDistanceMeters(
          latitude,
          longitude,
          lat,
          lng,
        );

        if (distance <= maxDistanceMeters) {
          nearby.add(ComplaintModel.fromMap(data, doc.id));
        }
      }
      return nearby;
    } catch (e) {
      return [];
    }
  }

  // Get complaint statistics (Authored + Supported)
  Future<Map<String, int>> getComplaintStats(String userId) async {
    QuerySnapshot query = await _firestore.collection('complaints').get();

    final docs = query.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String authorId = data['userId'] ?? '';
      final List<dynamic> supportedIds = data['supportedUserIds'] as List<dynamic>? ?? [];
      return authorId == userId || supportedIds.contains(userId);
    }).toList();

    int total = docs.length;
    int pending = docs.where((doc) => doc['status'] == 'Pending').length;
    int inProgress = docs.where((doc) => doc['status'] == 'In Progress').length;
    int resolved = docs.where((doc) => doc['status'] == 'Resolved').length;
    int rejected = docs.where((doc) => doc['status'] == 'Rejected').length;

    return {
      'total': total,
      'pending': pending,
      'inProgress': inProgress,
      'resolved': resolved,
      'rejected': rejected,
    };
  }

  // Get all complaints stats (Admin)
  Future<Map<String, int>> getAllComplaintStats() async {
    QuerySnapshot query = await _firestore.collection('complaints').get();

    int total = query.docs.length;
    int pending = query.docs.where((doc) => doc['status'] == 'Pending').length;
    int inProgress = query.docs.where((doc) => doc['status'] == 'In Progress').length;
    int resolved = query.docs.where((doc) => doc['status'] == 'Resolved').length;
    int rejected = query.docs.where((doc) => doc['status'] == 'Rejected').length;

    return {
      'total': total,
      'pending': pending,
      'inProgress': inProgress,
      'resolved': resolved,
      'rejected': rejected,
    };
  }

  // ========== ANNOUNCEMENT OPERATIONS ==========

  // Add announcement
  Future<void> addAnnouncement(String text) async {
    await _firestore.collection('announcements').add({
      'text': text,
      'adminId': currentUser!.uid,
      'adminName': 'Admin',
      'createdAt': Timestamp.now(),
    });
  }

  // Get announcements (Stream)
  Stream<List<AnnouncementModel>> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList());
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String docId) async {
    await _firestore.collection('announcements').doc(docId).delete();
  }

  // ========== SEARCH OPERATIONS ==========

  // Search complaints by title
  Stream<List<ComplaintModel>> searchComplaints(String query) {
    // Note: Firestore doesn't support full-text search natively
    // This is a simple search by title (case-insensitive)
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .where((complaint) =>
                complaint.title.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }

  // ========== NOTIFICATION OPERATIONS ==========

  // Add a new notification for a user
  // This is called by admin when they update a complaint status
  Future<void> addNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').add(notification.toMap());
  }

  // Get all notifications for a specific user (Stream - real-time updates)
  // This is used with StreamBuilder to show live notification updates
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId) // Only get THIS user's notifications
        .snapshots() // This gives us a real-time stream!
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(
                doc.data(),
                doc.id,
              ))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get count of UNREAD notifications (used for the badge on the bell icon)
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['isRead'] == false)
            .length); // Return count of unread notifications
  }

  // Mark a single notification as read
  Future<void> markNotificationRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark ALL notifications as read for a user
  Future<void> markAllNotificationsRead(String userId) async {
    // Get all notifications for this user
    final querySnapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    // Update each unread one to isRead: true
    for (var doc in querySnapshot.docs) {
      if (doc.data()['isRead'] == false) {
        await doc.reference.update({'isRead': true});
      }
    }
  }

  // Automatically find and merge existing duplicate complaints in Firestore
  Future<int> cleanupDuplicateComplaints() async {
    try {
      final snapshot = await _firestore.collection('complaints').get();
      List<DocumentSnapshot> docs = snapshot.docs;
      int removedCount = 0;

      for (int i = 0; i < docs.length; i++) {
        if (!docs[i].exists) continue;
        final dataA = docs[i].data() as Map<String, dynamic>;
        final String idA = docs[i].id;
        final double? latA = dataA['latitude']?.toDouble();
        final double? lngA = dataA['longitude']?.toDouble();
        final String statusA = dataA['status'] ?? 'Pending';

        if (latA == null || lngA == null || statusA == 'Rejected' || statusA == 'Resolved') continue;

        for (int j = i + 1; j < docs.length; j++) {
          if (!docs[j].exists) continue;
          final dataB = docs[j].data() as Map<String, dynamic>;
          final String idB = docs[j].id;
          final double? latB = dataB['latitude']?.toDouble();
          final double? lngB = dataB['longitude']?.toDouble();
          final String statusB = dataB['status'] ?? 'Pending';

          if (latB == null || lngB == null || statusB == 'Rejected' || statusB == 'Resolved') continue;

          double distance = LocationService().calculateDistanceMeters(latA, lngA, latB, lngB);

          if (distance <= 50.0) {
            int supportB = (dataB['supportCount'] as num?)?.toInt() ?? 1;
            List<dynamic> usersB = dataB['supportedUserIds'] as List<dynamic>? ?? [];

            await _firestore.collection('complaints').doc(idA).update({
              'supportCount': FieldValue.increment(supportB),
              if (usersB.isNotEmpty) 'supportedUserIds': FieldValue.arrayUnion(usersB),
            });

            await _firestore.collection('complaints').doc(idB).delete();
            removedCount++;
          }
        }
      }
      return removedCount;
    } catch (e) {
      return 0;
    }
  }
}