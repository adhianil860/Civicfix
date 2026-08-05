import 'package:civicfic/WIDGETS/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/auth_service.dart';
import 'package:civicfic/services/notification_service.dart';
import 'package:civicfic/models/user_model.dart';
import 'package:civicfic/screens/login_screen.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  UserModel? _user;
  bool _isLoading = true;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userData = await _firestoreService.getUser(user.uid);
      if (userData != null) {
        setState(() {
          _user = userData;
          _isLoading = false;
        });
      } else {
        final newUser = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          phone: 'Not provided',
          role: 'user',
          createdAt: DateTime.now(),
        );
        await _firestoreService.saveUser(newUser);
        setState(() {
          _user = newUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      NotificationService().showError(context, 'Error loading user data');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await FirebaseAuth.instance.signOut();

      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      NotificationService().showError(context, 'Logout failed: $e');
    }
  }

  Future<void> _confirmLogout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _logout();
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final settings = Provider.of<SettingsProvider>(context);
        return AlertDialog(
          backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          'Change Password',
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(
                  Icons.lock,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(
                  Icons.lock_open,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: TextStyle(
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
              ),
            ),
          ],
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
              if (newPasswordController.text != confirmPasswordController.text) {
                NotificationService().showError(context, 'Passwords do not match');
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && currentPasswordController.text.isNotEmpty) {
                  await user.updatePassword(newPasswordController.text);
                  Navigator.pop(context);
                  NotificationService().showSuccess(
                    context,
                    'Password changed successfully!',
                  );
                } else {
                  Navigator.pop(context);
                  NotificationService().showError(
                    context,
                    'Please enter current password',
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                NotificationService().showError(context, e.toString());
              }

              currentPasswordController.dispose();
              newPasswordController.dispose();
              confirmPasswordController.dispose();
            },
            child: const Text('Update'),
          ),
        ],
      );
    },
  );
}

  void _showSettingsPopup() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.settings, color: Colors.blue, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    "Settings",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // Dark Mode
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return Card(
                    color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
                    child: SwitchListTile(
                      secondary: Icon(
                        settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: settings.isDarkMode ? Colors.grey : Colors.orange,
                      ),
                      title: Text(
                        "Dark Mode",
                        style: TextStyle(
                          color: settings.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        settings.isDarkMode ? "Dark theme enabled 🌙" : "Light theme enabled ☀️",
                        style: TextStyle(
                          color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      value: settings.isDarkMode,
                      onChanged: (value) async {
                        await settings.toggleDarkMode(value);
                        setState(() {});
                        NotificationService().showInfo(
                          context,
                          value ? '🌙 Dark Mode Enabled' : '☀️ Light Mode Enabled',
                        );
                      },
                      activeColor: Colors.blue,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Language
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return Card(
                    color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
                    child: ListTile(
                      leading: const Icon(Icons.language, color: Colors.blue),
                      title: Text(
                        "Language",
                        style: TextStyle(
                          color: settings.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        settings.getLanguageName(settings.languageCode),
                        style: TextStyle(
                          color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      trailing: DropdownButton<String>(
                        value: settings.languageCode,
                        dropdownColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
                        underline: const SizedBox(),
                        items: settings.supportedLanguages.map((lang) {
                          return DropdownMenuItem(
                            value: lang['code'],
                            child: Text(
                              lang['name']!,
                              style: TextStyle(
                                color: settings.isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value != null) {
                            await settings.changeLanguage(value);
                            setState(() {});
                            NotificationService().showInfo(
                              context,
                              'Language changed to ${settings.getLanguageName(value)}',
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    if (_isLoading) {
      return const LoadingWidget();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: settings.isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: settings.isDarkMode ? Colors.white : Colors.blue.shade700,
        // 👇 Back Button
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: settings.isDarkMode ? Colors.white : Colors.blue.shade700,
          ),
          onPressed: () {
            Navigator.pop(context); // Back to Home
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: settings.isDarkMode ? Colors.white : Colors.blue.shade700,
            ),
            onPressed: _showSettingsPopup,
          ),
        ],
      ),
      body: Container(
        color: settings.isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.blue.shade100,
                  child: Text(
                    _user?.name[0].toUpperCase() ?? 'U',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: settings.isDarkMode ? Colors.blue[200] : Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _user?.name ?? 'User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _user?.email ?? '',
                style: TextStyle(
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: _user?.role == 'admin'
                      ? (settings.isDarkMode ? Colors.purple[900] : Colors.purple.shade100)
                      : (settings.isDarkMode ? Colors.blue[900] : Colors.blue.shade100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _user?.role == 'admin' ? '👑 Admin' : '👤 User',
                  style: TextStyle(
                    color: _user?.role == 'admin'
                        ? (settings.isDarkMode ? Colors.purple[200] : Colors.purple)
                        : (settings.isDarkMode ? Colors.blue[200] : Colors.blue),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Card(
                color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.person,
                        "Full Name",
                        _user?.name ?? '',
                        settings,
                      ),
                      Divider(
                        color: settings.isDarkMode ? Colors.grey[700] : Colors.grey.shade200,
                      ),
                      _buildDetailRow(
                        Icons.email,
                        "Email",
                        _user?.email ?? '',
                        settings,
                      ),
                      Divider(
                        color: settings.isDarkMode ? Colors.grey[700] : Colors.grey.shade200,
                      ),
                      _buildDetailRow(
                        Icons.phone,
                        "Phone",
                        _user?.phone ?? 'Not provided',
                        settings,
                      ),
                      Divider(
                        color: settings.isDarkMode ? Colors.grey[700] : Colors.grey.shade200,
                      ),
                      _buildDetailRow(
                        Icons.calendar_today,
                        "Joined",
                        _formatDate(_user?.createdAt ?? DateTime.now()),
                        settings,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.info, color: Colors.blue),
                  title: Text(
                    "About CivicFix",
                    style: TextStyle(
                      color: settings.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                  ),
                  onTap: _showAboutDialog,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.lock, color: Colors.orange),
                  title: Text(
                    "Change Password",
                    style: TextStyle(
                      color: settings.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                  ),
                  onTap: _showChangePasswordDialog,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: settings.isDarkMode
                    ? Colors.red[900]?.withOpacity(0.2)
                    : Colors.red.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.red,
                    size: 16,
                  ),
                  onTap: _confirmLogout,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Made with ❤️ by CivicFix",
                  style: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[600] : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAboutDialog() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          'About CivicFix',
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📱 CivicFix v1.0.0',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '📅 Released: July 2026',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '👨‍💻 Developer: CivicFix Team',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '🔹 Smart civic issue reporting',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              '🔹 Real-time complaint tracking',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}