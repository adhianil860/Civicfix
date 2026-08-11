// admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:civicfic/screens/admin/admin_complaintchecking.dart';
import 'package:civicfic/screens/admin/admin_announcements.dart';
import 'package:civicfic/screens/admin/admin_profile.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/models/announcement_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int selectedPage = 0;
  final FirestoreService _firestoreService = FirestoreService();

  void _navigateToPage(int index) {
    setState(() {
      selectedPage = index;
    });
  }

  void _showAnnouncements() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Announcements",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: StreamBuilder<List<AnnouncementModel>>(
                stream: _firestoreService.getAnnouncements(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            "No announcements yet",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  final announcements = snapshot.data!;
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.purple.shade50],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    announcement.text,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    announcement.formattedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: settings.isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: settings.isDarkMode ? Colors.grey[700] : Colors.blue.shade100,
            child: const Icon(Icons.admin_panel_settings, size: 18, color: Colors.blue),
          ),
          onPressed: () => _navigateToPage(3),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                "assets/images/CivicFix_logo.png",
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "CivicFix",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1,
                color: settings.isDarkMode ? Colors.white : Colors.blue,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: settings.isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: settings.isDarkMode ? Colors.white : Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: settings.isDarkMode ? Colors.white : Colors.blue.shade700,
            ),
            onPressed: _showAnnouncements,
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedPage,
        children: const [
          AdminDashboardContent(),
          AdminComplaints(),
          AdminAnnouncements(),
          AdminProfile(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedPage,
        onTap: _navigateToPage,
        backgroundColor: settings.isDarkMode ? Colors.grey[850] : Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ========== ADMIN DASHBOARD CONTENT ==========
class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final firestoreService = FirestoreService();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Admin Panel",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        "Manage • Monitor • Control",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        "4.9",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dashboard Statistics
          StreamBuilder<List<ComplaintModel>>(
            stream: firestoreService.getAllComplaints(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildStatsShimmer(settings);
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _buildStatsShimmer(settings);
              }

              final complaints = snapshot.data!;
              int total = complaints.length;
              int pending = complaints.where((c) => c.status == 'Pending').length;
              int inProgress = complaints.where((c) => c.status == 'In Progress').length;
              int resolved = complaints.where((c) => c.status == 'Resolved').length;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard("Total", total.toString(), Icons.assignment, Colors.blue, settings),
                  _buildStatCard("Pending", pending.toString(), Icons.pending, Colors.orange, settings),
                  _buildStatCard("Progress", inProgress.toString(), Icons.sync, Colors.purple, settings),
                  _buildStatCard("Resolved", resolved.toString(), Icons.check_circle, Colors.green, settings),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(settings),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: settings.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        Icons.list_alt,
                        "Complaints",
                        Colors.blue,
                        () {
                          // 👇 Navigate to complaints page
                          final adminHome = context.findAncestorStateOfType<_AdminHomeScreenState>();
                          if (adminHome != null) {
                            adminHome._navigateToPage(1);
                          }
                        },
                        settings,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionCard(
                        Icons.campaign,
                        "Announce",
                        Colors.orange,
                        () {
                          // 👇 Navigate to announcements page
                          final adminHome = context.findAncestorStateOfType<_AdminHomeScreenState>();
                          if (adminHome != null) {
                            adminHome._navigateToPage(2);
                          }
                        },
                        settings,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionCard(
                        Icons.analytics,
                        "Reports",
                        Colors.green,
                        () {
                          // Show reports dialog
                          _showReportsDialog(context, settings);
                        },
                        settings,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // System Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(settings),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "System Status",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: settings.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusTile(
                  Icons.cloud_done,
                  "Firestore Connected",
                  Colors.green,
                  settings,
                ),
                const Divider(height: 16),
                _buildStatusTile(
                  Icons.verified_user,
                  "Authentication Active",
                  Colors.green,
                  settings,
                ),
                const Divider(height: 16),
                _buildStatusTile(
                  Icons.check_circle,
                  "Complaint System Running",
                  Colors.green,
                  settings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Recent Complaints
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(settings),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Complaints",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: settings.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // 👇 Navigate to complaints page
                        final adminHome = context.findAncestorStateOfType<_AdminHomeScreenState>();
                        if (adminHome != null) {
                          adminHome._navigateToPage(1);
                        }
                      },
                      child: Text(
                        "View All",
                        style: TextStyle(
                          fontSize: 11,
                          color: settings.isDarkMode ? Colors.blue[200] : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<ComplaintModel>>(
                  stream: firestoreService.getAllComplaints(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox, size: 32, color: Colors.grey),
                              const SizedBox(height: 4),
                              Text(
                                "No complaints yet",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final complaints = snapshot.data!.take(3).toList();
                    return Column(
                      children: complaints.map((complaint) {
                        return _buildRecentComplaintTile(complaint, settings);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Civic Tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.purple.shade50],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "💡 Admin Tip",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: settings.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Regularly update announcements to keep citizens informed",
                        style: TextStyle(
                          fontSize: 11,
                          color: settings.isDarkMode ? Colors.grey[400] : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: Text(
              "Made with ❤️ by CivicFix",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[600] : Colors.grey,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(SettingsProvider settings) {
    return BoxDecoration(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildStatsShimmer(SettingsProvider settings) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard("Total", "...", Icons.assignment, Colors.blue, settings),
        _buildStatCard("Pending", "...", Icons.pending, Colors.orange, settings),
        _buildStatCard("Progress", "...", Icons.sync, Colors.purple, settings),
        _buildStatCard("Resolved", "...", Icons.check_circle, Colors.green, settings),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: settings.isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, VoidCallback onTap, SettingsProvider settings) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTile(IconData icon, String title, Color color, SettingsProvider settings) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: settings.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        Icon(
          Icons.check_circle,
          color: color,
          size: 18,
        ),
      ],
    );
  }

  Widget _buildRecentComplaintTile(ComplaintModel complaint, SettingsProvider settings) {
    return GestureDetector(
      onTap: () {
        // 👇 Navigate to complaint details
        // You can add navigation to complaint details page here
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: complaint.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(complaint.statusIcon, color: complaint.statusColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: settings.isDarkMode ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: settings.isDarkMode ? Colors.grey[400] : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: complaint.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                complaint.status,
                style: TextStyle(
                  fontSize: 10,
                  color: complaint.statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== REPORTS DIALOG ==========
  void _showReportsDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '📊 Reports',
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportItem(
              Icons.pending,
              "Pending Reports",
              "45 complaints pending",
              Colors.orange,
              settings,
            ),
            const SizedBox(height: 8),
            _buildReportItem(
              Icons.sync,
              "In Progress",
              "22 complaints in progress",
              Colors.purple,
              settings,
            ),
            const SizedBox(height: 8),
            _buildReportItem(
              Icons.check_circle,
              "Resolved Reports",
              "89 complaints resolved",
              Colors.green,
              settings,
            ),
            const SizedBox(height: 8),
            _buildReportItem(
              Icons.assignment,
              "Total Reports",
              "156 complaints total",
              Colors.blue,
              settings,
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

  Widget _buildReportItem(IconData icon, String title, String subtitle, Color color, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: settings.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}