import 'package:flutter/material.dart';
import 'package:civicfic/screens/admin/admin_complaintchecking.dart';
import 'package:civicfic/screens/admin/admin_announcements.dart';
import 'package:civicfic/screens/admin/admin_profile.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int selectedPage = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: settings.isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 15,
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
            const SizedBox(width: 10),
            Text(
              "CivicFix",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Gradient Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Admin Panel",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "4.9",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTabItem("Dashboard", 0, Icons.dashboard_outlined, Icons.dashboard, settings),
                  _buildTabItem("Complaints", 1, Icons.list_alt_outlined, Icons.list_alt, settings),
                  _buildTabItem("Announcements", 2, Icons.campaign_outlined, Icons.campaign, settings),
                  _buildTabItem("Profile", 3, Icons.person_outline, Icons.person, settings),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: IndexedStack(
              index: selectedPage,
              children: [
                AdminDashboardContent(),
                AdminComplaints(),
                AdminAnnouncements(),
                AdminProfile(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index, IconData icon, IconData activeIcon, SettingsProvider settings) {
    bool isSelected = selectedPage == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPage = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.blue.shade700 : (settings.isDarkMode ? Colors.grey[400] : Colors.grey.shade600),
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue.shade700 : (settings.isDarkMode ? Colors.grey[400] : Colors.grey.shade600),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "👋 Welcome Admin",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: settings.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Manage complaints, monitor reports and keep your community updated.",
            style: TextStyle(
              fontSize: 16,
              color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
            ),
          ),
          const SizedBox(height: 25),

          // Search
          TextField(
            style: TextStyle(
              color: settings.isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: "Search complaints...",
              hintStyle: TextStyle(
                color: settings.isDarkMode ? Colors.grey[500] : Colors.grey[400],
              ),
              prefixIcon: Icon(
                Icons.search,
                color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
              labelStyle: TextStyle(
                color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Dashboard Statistics - Live Data
          Text(
            "Dashboard Statistics",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: settings.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 15),

          StreamBuilder<List<ComplaintModel>>(
            stream: firestoreService.getAllComplaints(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildStatsPlaceholder(settings);
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _buildStatsPlaceholder(settings);
              }

              final complaints = snapshot.data!;
              int total = complaints.length;
              int pending = complaints.where((c) => c.status == 'Pending').length;
              int inProgress = complaints.where((c) => c.status == 'In Progress').length;
              int resolved = complaints.where((c) => c.status == 'Resolved').length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: statisticCard(
                          "Total",
                          total.toString(),
                          Icons.assignment,
                          Colors.blue,
                          settings,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: statisticCard(
                          "Pending",
                          pending.toString(),
                          Icons.pending_actions,
                          Colors.orange,
                          settings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: statisticCard(
                          "Progress",
                          inProgress.toString(),
                          Icons.sync,
                          Colors.purple,
                          settings,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: statisticCard(
                          "Resolved",
                          resolved.toString(),
                          Icons.check_circle,
                          Colors.green,
                          settings,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 30),

          // Quick Actions
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: settings.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 15),

          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.blue),
            title: Text(
              "View Complaints",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.campaign, color: Colors.orange),
            title: Text(
              "Create Announcement",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.green),
            title: Text(
              "View Reports",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
            ),
            onTap: () {},
          ),

          const SizedBox(height: 30),

          // Recent Complaints - Live Data
          Text(
            "Recent Complaints",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: settings.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 15),

          StreamBuilder<List<ComplaintModel>>(
            stream: firestoreService.getAllComplaints(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Card(
                  color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No complaints yet',
                        style: TextStyle(
                          color: settings.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final complaints = snapshot.data!.take(3).toList();
              return Column(
                children: complaints.map((complaint) {
                  return Card(
                    color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: complaint.statusColor.withOpacity(0.2),
                        child: Icon(
                          complaint.statusIcon,
                          color: complaint.statusColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        complaint.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: settings.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        '${complaint.status} • ${complaint.location}',
                        style: TextStyle(
                          color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 30),

          // System Status
          Text(
            "System Status",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: settings.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 15),

          _buildStatusCard(
            Icons.cloud_done,
            "Firestore Connected",
            Colors.green,
            settings,
          ),
          const SizedBox(height: 10),
          _buildStatusCard(
            Icons.verified_user,
            "Authentication Active",
            Colors.green,
            settings,
          ),
          const SizedBox(height: 10),
          _buildStatusCard(
            Icons.check_circle,
            "Complaint System Running",
            Colors.green,
            settings,
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              "Made with ❤️ by CivicFix",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[600] : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatsPlaceholder(SettingsProvider settings) {
    return Row(
      children: [
        Expanded(
          child: statisticCard("Total", "...", Icons.assignment, Colors.blue, settings),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: statisticCard("Pending", "...", Icons.pending_actions, Colors.orange, settings),
        ),
      ],
    );
  }

  Widget statisticCard(String title, String value, IconData icon, Color color, SettingsProvider settings) {
    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: settings.isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(IconData icon, String title, Color color, SettingsProvider settings) {
    return Card(
      color: settings.isDarkMode ? Colors.grey[850] : color.withOpacity(0.08),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        trailing: Icon(
          Icons.check_circle,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}trf