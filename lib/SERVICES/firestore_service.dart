import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/complaint_model.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';

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

  // Add complaint
  Future<void> addComplaint(ComplaintModel complaint) async {
    await _firestore.collection('complaints').add(complaint.toMap());
  }

  // Get user complaints (Stream)
  Stream<List<ComplaintModel>> getUserComplaints(String userId) {
    return _firestore
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  // Get all complaints (Stream)
  Stream<List<ComplaintModel>> getAllComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromMap(
                  doc.data() as Map<String, dynamic>,
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  // Update complaint status
  Future<void> updateComplaintStatus(String docId, String status) async {
    await _firestore.collection('complaints').doc(docId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // Delete complaint
  Future<void> deleteComplaint(String docId) async {
    await _firestore.collection('complaints').doc(docId).delete();
  }

  // Get complaint statistics
  Future<Map<String, int>> getComplaintStats(String userId) async {
    QuerySnapshot query = await _firestore
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .get();

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
                  doc.data() as Map<String, dynamic>,
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
    // This is a simple search by title (exact match)
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .where((complaint) =>
                complaint.title.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }
}