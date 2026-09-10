import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String? _userRole;

  User? get user => _user;
  String? get userRole => _userRole;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _userRole == 'admin' || _userRole == 'sub_admin' || _userRole == 'super_admin';

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserRole(user.uid);
      } else {
        _userRole = null;
      }
      notifyListeners();
    });
  }

  // Load user role from Firestore
  Future<void> _loadUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      _userRole = doc['role'] ?? 'user';
    } catch (e) {
      _userRole = 'user';
    }
  }

  // Ensure sub-admin accounts are provisioned in Firestore with appropriate role and municipality
  Future<void> _ensureSubAdminProvisioned(User user, String cleanEmail) async {
    String lowerEmail = cleanEmail.toLowerCase();
    String? assignedMuni;
    String? adminName;

    if (lowerEmail.contains('thrikkakara') || lowerEmail.contains('hrikkakara')) {
      assignedMuni = 'Thrikkakara Municipality';
      adminName = 'Thrikkakara Sub-Admin';
    } else if (lowerEmail.contains('kalamassery')) {
      assignedMuni = 'Kalamassery Municipality';
      adminName = 'Kalamassery Sub-Admin';
    } else if (lowerEmail == 'admin@gmail.com') {
      adminName = 'Super Admin';
    }

    if (assignedMuni != null || lowerEmail == 'admin@gmail.com') {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      String role = lowerEmail == 'admin@gmail.com' ? 'super_admin' : 'sub_admin';

      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'name': adminName ?? 'Sub-Admin',
          'email': user.email ?? cleanEmail,
          'role': role,
          'assignedMunicipality': assignedMuni,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        Map<String, dynamic> updates = {};
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          if (data['role'] != role && data['role'] != 'admin') updates['role'] = role;
          if (assignedMuni != null && data['assignedMunicipality'] != assignedMuni) {
            updates['assignedMunicipality'] = assignedMuni;
          }
        }
        if (updates.isNotEmpty) {
          await docRef.update(updates);
        }
      }
    }
  }

  // Login with sub-admin auto-provisioning
  Future<UserCredential> login(String email, String password) async {
    String cleanEmail = email.trim();
    String lowerEmail = cleanEmail.toLowerCase();

    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      await _ensureSubAdminProvisioned(cred.user!, cleanEmail);
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        if (lowerEmail.contains('thrikkakara') || lowerEmail.contains('hrikkakara') || lowerEmail.contains('kalamassery') || lowerEmail == 'admin@gmail.com') {
          try {
            UserCredential cred = await _auth.createUserWithEmailAndPassword(
              email: cleanEmail,
              password: password,
            );
            await _ensureSubAdminProvisioned(cred.user!, cleanEmail);
            return cred;
          } catch (_) {
            throw _getAuthErrorMessage(e.code);
          }
        }
      }
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      throw 'Login failed. Please try again.';
    }
  }

  // Register
  Future<UserCredential> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      throw 'Registration failed. Please try again.';
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get user role
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) return 'user';
      return doc['role'] ?? 'user';
    } catch (e) {
      return 'user';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      throw 'Password reset failed. Please try again.';
    }
  }

  // Error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password or email.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}