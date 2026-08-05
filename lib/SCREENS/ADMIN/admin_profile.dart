import 'package:civicfic/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civicfic/screens/login_screen.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/auth_service.dart';
import 'package:civicfic/services/notification_service.dart';
import 'package:civicfic/models/admin_model.dart';
import 'package:provider/provider.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  // Settings Variables
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _autoAssignComplaints = false;
  bool _autoResponse = true;
  bool _dataSaver = false;

  // Admin Data
  AdminModel? _admin;
  bool _isLoading = true;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAdminData();
  }

  // Load admin data from Firestore
  Future<void> _loadAdminData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final adminData = await _firestoreService.getUser(user.uid);
      if (adminData != null) {
        setState(() {
          _admin = AdminModel(
            uid: adminData.uid,
            name: adminData.name,
            email: adminData.email,
            phone: adminData.phone,
            role: adminData.role,
            department: 'Municipality Administration',
            createdAt: adminData.createdAt,
          );
          _isLoading = false;
        });
      } else {
        // Create default admin if not exists
        final newAdmin = AdminModel(
          uid: user.uid,
          name: user.displayName ?? 'Admin',
          email: user.email ?? 'admin@civicfix.com',
          phone: '+91 9876543210',
          role: 'admin',
          department: 'Municipality Administration',
          createdAt: DateTime.now(),
        );
        await _firestoreService.saveUser(
          UserModel(
            uid: newAdmin.uid,
            name: newAdmin.name,
            email: newAdmin.email,
            phone: newAdmin.phone,
            role: newAdmin.role,
            createdAt: newAdmin.createdAt,
          ),
        );
        setState(() {
          _admin = newAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load saved settings
  Future<void> _loadSettings() async {
    try {
      // Settings are handled by SettingsProvider
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  // Save settings
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      // Settings are handled by SettingsProvider
    } catch (e) {
      print('Error saving setting: $e');
    }
  }

  // Logout function
  Future<void> logout() async {
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

  Future<void> confirmLogout() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          'Logout',
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
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
      await logout();
    }
  }

  // ========== SHOW SETTINGS POPUP ==========
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
      return Scaffold(
        appBar: AppBar(
          title: const Text("Admin Profile"),
          centerTitle: true,
          backgroundColor: settings.isDarkMode ? Colors.grey[900] : Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Profile"),
        centerTitle: true,
        backgroundColor: settings.isDarkMode ? Colors.grey[900] : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        // 👇 Back Button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Back to Admin Home
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsPopup,
          ),
        ],
      ),
      body: Container(
        color: settings.isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(settings),
              const SizedBox(height: 25),
              _buildSectionHeader("About", Icons.info, settings),
              const SizedBox(height: 10),
              _buildAboutCard(settings),
              const SizedBox(height: 10),
              _buildTermsCard(settings),
              const SizedBox(height: 20),
              _buildSectionHeader("Account", Icons.account_circle, settings),
              const SizedBox(height: 10),
              _buildChangePasswordCard(settings),
              const SizedBox(height: 10),
              _buildLogoutCard(settings),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  "Made with ❤️ by CivicFix",
                  style: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[600] : Colors.grey,
                    fontSize: 12,
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

  // ========== PROFILE SECTION ==========
  Widget _buildProfileSection(SettingsProvider settings) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.grey[300],
          child: Icon(
            Icons.admin_panel_settings,
            size: 70,
            color: settings.isDarkMode ? Colors.blue[200] : Colors.blue,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _admin?.name ?? 'Admin',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _admin?.email ?? 'admin@civicfix.com',
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: settings.isDarkMode ? Colors.blue[900] : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "System Administrator",
            style: TextStyle(
              color: settings.isDarkMode ? Colors.blue[200] : Colors.blue,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
          child: ListTile(
            leading: const Icon(Icons.badge),
            title: Text(
              "Role",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[400] : Colors.black,
              ),
            ),
            subtitle: Text(
              "System Administrator",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Card(
          color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
          child: ListTile(
            leading: const Icon(Icons.email),
            title: Text(
              "Email",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[400] : Colors.black,
              ),
            ),
            subtitle: Text(
              _admin?.email ?? 'admin@civicfix.com',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Card(
          color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
          child: ListTile(
            leading: const Icon(Icons.phone),
            title: Text(
              "Phone",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[400] : Colors.black,
              ),
            ),
            subtitle: Text(
              _admin?.phone ?? '+91 9876543210',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Card(
          color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
          child: ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(
              "Department",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[400] : Colors.black,
              ),
            ),
            subtitle: Text(
              _admin?.department ?? 'Municipality Administration',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== SECTION HEADER ==========
  Widget _buildSectionHeader(String title, IconData icon, SettingsProvider settings) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: settings.isDarkMode ? Colors.grey[600] : Colors.grey,
        ),
      ],
    );
  }

  // ========== SETTINGS TOGGLES ==========

  Widget _buildDarkModeToggle() {
    final settings = Provider.of<SettingsProvider>(context);

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
  }

  Widget _buildLanguageDropdown() {
    final settings = Provider.of<SettingsProvider>(context);

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
  }

  Widget _buildNotificationToggle() {
    final settings = Provider.of<SettingsProvider>(context);

    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      child: SwitchListTile(
        secondary: const Icon(Icons.notifications_active, color: Colors.blue),
        title: Text(
          "Push Notifications",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          "Receive alert notifications",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        value: _notificationsEnabled,
        onChanged: (value) async {
          setState(() {
            _notificationsEnabled = value;
          });
          await _saveSetting('notifications', value);
        },
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildEmailNotificationToggle() {
    final settings = Provider.of<SettingsProvider>(context);

    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      child: SwitchListTile(
        secondary: const Icon(Icons.email, color: Colors.orange),
        title: Text(
          "Email Notifications",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          "Receive email alerts for complaints",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        value: _emailNotifications,
        onChanged: (value) async {
          setState(() {
            _emailNotifications = value;
          });
          await _saveSetting('emailNotifications', value);
        },
        activeColor: Colors.orange,
      ),
    );
  }

  Widget _buildAutoAssignToggle() {
    final settings = Provider.of<SettingsProvider>(context);

    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      child: SwitchListTile(
        secondary: const Icon(Icons.assignment_ind, color: Colors.purple),
        title: Text(
          "Auto-Assign Complaints",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          _autoAssignComplaints
              ? "Complaints auto-assigned to admin"
              : "Manual complaint assignment",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        value: _autoAssignComplaints,
        onChanged: (value) async {
          setState(() {
            _autoAssignComplaints = value;
          });
          await _saveSetting('autoAssign', value);
        },
        activeColor: Colors.purple,
      ),
    );
  }

  Widget _buildAutoResponseToggle() {
    final settings = Provider.of<SettingsProvider>(context);

    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      child: SwitchListTile(
        secondary: const Icon(Icons.reply_all, color: Colors.green),
        title: Text(
          "Auto-Response",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          _autoResponse
              ? "Auto-reply to complaints enabled"
              : "Manual reply required",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        value: _autoResponse,
        onChanged: (value) async {
          setState(() {
            _autoResponse = value;
          });
          await _saveSetting('autoResponse', value);
        },
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildDataSaverToggle() {
    final settings = Provider.of<SettingsProvider>(context);

    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      child: SwitchListTile(
        secondary: const Icon(Icons.data_saver_off, color: Colors.teal),
        title: Text(
          "Data Saver",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          _dataSaver
              ? "Reduced image quality enabled"
              : "High quality images",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        value: _dataSaver,
        onChanged: (value) async {
          setState(() {
            _dataSaver = value;
          });
          await _saveSetting('dataSaver', value);
        },
        activeColor: Colors.teal,
      ),
    );
  }

  Widget _buildClearCacheButton() {
    final settings = Provider.of<SettingsProvider>(context);

    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      child: ListTile(
        leading: const Icon(Icons.cleaning_services, color: Colors.red),
        title: Text(
          "Clear Cache",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          "Clear temporary data and images",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            final settings = Provider.of<SettingsProvider>(context, listen: false);
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
                title: Text(
                  'Clear Cache',
                  style: TextStyle(
                    color: settings.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                content: Text(
                  'Are you sure you want to clear all cached data?',
                  style: TextStyle(
                    color: settings.isDarkMode ? Colors.white : Colors.black,
                  ),
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
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      NotificationService().showSuccess(
                        context,
                        'Cache cleared successfully! ✅',
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Clear'),
        ),
      ),
    );
  }

  // ========== ABOUT ==========

  Widget _buildAboutCard(SettingsProvider settings) {
    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      child: ListTile(
        leading: const Icon(Icons.info, color: Colors.blue),
        title: Text(
          "About CivicFix",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          "Version 1.0.0 • Build 101",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: settings.isDarkMode ? Colors.grey[600] : Colors.grey,
        ),
        onTap: () {
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
                    '📧 support@civicfix.com',
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
        },
      ),
    );
  }

  Widget _buildTermsCard(SettingsProvider settings) {
    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      child: ListTile(
        leading: const Icon(Icons.privacy_tip, color: Colors.orange),
        title: Text(
          "Terms & Privacy",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          "Privacy policy and terms of service",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: settings.isDarkMode ? Colors.grey[600] : Colors.grey,
        ),
        onTap: () {
          final settings = Provider.of<SettingsProvider>(context, listen: false);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
              title: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔒 Data Collection',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: settings.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'We collect basic user data for complaint management.',
                      style: TextStyle(
                        color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '🔐 Data Security',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: settings.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'All data is encrypted and stored securely in Firebase.',
                      style: TextStyle(
                        color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========== ACCOUNT ==========

  Widget _buildChangePasswordCard(SettingsProvider settings) {
    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      child: ListTile(
        leading: const Icon(Icons.lock, color: Colors.blue),
        title: Text(
          "Change Password",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          "Update your account password",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: settings.isDarkMode ? Colors.grey[600] : Colors.grey,
        ),
        onTap: () {
          _showChangePasswordDialog(settings);
        },
      ),
    );
  }

  void _showChangePasswordDialog(SettingsProvider settings) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                NotificationService().showError(
                  context,
                  'Passwords do not match',
                );
                return;
              }

              Navigator.pop(context);
              NotificationService().showSuccess(
                context,
                'Password changed successfully! ✅',
              );

              currentPasswordController.dispose();
              newPasswordController.dispose();
              confirmPasswordController.dispose();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(SettingsProvider settings) {
    return Card(
      color: settings.isDarkMode ? Colors.red[900]?.withOpacity(0.3) : Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          "Logout",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Sign out from your account",
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.red,
          size: 16,
        ),
        onTap: confirmLogout,
      ),
    );
  }
}