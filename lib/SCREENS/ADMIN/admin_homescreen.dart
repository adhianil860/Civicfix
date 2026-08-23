import 'package:flutter/material.dart';
import 'package:civicfic/screens/admin/admin_complaintchecking.dart';
import 'package:civicfic/screens/admin/admin_announcements.dart';
import 'package:civicfic/screens/admin/admin_profile.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/models/announcement_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
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
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: settings.isDarkMode ? Colors.grey[900] : const Color(0xFFF3F4F6),
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
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: settings.isDarkMode ? Colors.grey[500] : Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
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
            label: 'Announce',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Municipality Admin",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Active live status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.greenAccent, width: 1),
                            ),
                            child: const Row(
                              children: [
                                CircleAvatar(radius: 3, backgroundColor: Colors.greenAccent),
                                SizedBox(width: 4),
                                Text(
                                  "LIVE",
                                  style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Manage • Monitor • Resolve",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Live Dashboard Stats Grid
          Text(
            "Overview",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: settings.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
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
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard("Total", total.toString(), Icons.assignment_rounded, const Color(0xFF3B82F6), settings),
                  _buildStatCard("Pending", pending.toString(), Icons.pending_actions_rounded, const Color(0xFFF59E0B), settings),
                  _buildStatCard("In Progress", inProgress.toString(), Icons.sync_rounded, const Color(0xFF8B5CF6), settings),
                  _buildStatCard("Resolved", resolved.toString(), Icons.check_circle_rounded, const Color(0xFF10B981), settings),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. Quick Actions Row
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: settings.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  Icons.list_alt_rounded,
                  "Complaints",
                  const Color(0xFF3B82F6),
                  () {
                    final adminHome = context.findAncestorStateOfType<_AdminHomeScreenState>();
                    if (adminHome != null) adminHome._navigateToPage(1);
                  },
                  settings,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  Icons.campaign_rounded,
                  "Announce",
                  const Color(0xFFF59E0B),
                  () {
                    final adminHome = context.findAncestorStateOfType<_AdminHomeScreenState>();
                    if (adminHome != null) adminHome._navigateToPage(2);
                  },
                  settings,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  Icons.analytics_rounded,
                  "Reports",
                  const Color(0xFF10B981),
                  () => _showReportsDialog(context, settings),
                  settings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. System Health Status
          Text(
            "System Health",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: settings.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(settings),
            child: Column(
              children: [
                _buildStatusTile(Icons.cloud_done_rounded, "Firestore Connected", const Color(0xFF10B981), settings),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 1),
                ),
                _buildStatusTile(Icons.verified_user_rounded, "Authentication Active", const Color(0xFF10B981), settings),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 1),
                ),
                _buildStatusTile(Icons.check_circle_rounded, "Complaint System Running", const Color(0xFF10B981), settings),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Recent Complaints List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Complaints",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: settings.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              InkWell(
                onTap: () {
                  final adminHome = context.findAncestorStateOfType<_AdminHomeScreenState>();
                  if (adminHome != null) adminHome._navigateToPage(1);
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: settings.isDarkMode ? Colors.blue[300] : const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<ComplaintModel>>(
            stream: firestoreService.getAllComplaints(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(settings),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("No complaints yet", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              final complaints = snapshot.data!.take(3).toList();
              return Container(
                decoration: _cardDecoration(settings),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: complaints.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    return _buildRecentComplaintTile(complaints[index], settings);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Civic Tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.indigo.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 4)],
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Admin Tip",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: settings.isDarkMode ? Colors.black87 : Colors.black87, // Intentionally kept dark for legibility on light gradient
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Regularly update announcements to keep citizens informed.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              "Made with ❤️ by CivicFix",
              style: TextStyle(
                color: settings.isDarkMode ? Colors.grey[600] : Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(SettingsProvider settings) {
    return BoxDecoration(
      color: settings.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: settings.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
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
      childAspectRatio: 1.4,
      children: [
        _buildStatCard("Total", "...", Icons.assignment_rounded, const Color(0xFF3B82F6), settings),
        _buildStatCard("Pending", "...", Icons.pending_actions_rounded, const Color(0xFFF59E0B), settings),
        _buildStatCard("In Progress", "...", Icons.sync_rounded, const Color(0xFF8B5CF6), settings),
        _buildStatCard("Resolved", "...", Icons.check_circle_rounded, const Color(0xFF10B981), settings),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, SettingsProvider settings) {
    return Container(
      decoration: BoxDecoration(
        color: settings.isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: settings.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: settings.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: settings.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: settings.isDarkMode ? Colors.white : Colors.black87,
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: settings.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Icon(
          Icons.verified_rounded,
          color: color,
          size: 22,
        ),
      ],
    );
  }

  Widget _buildRecentComplaintTile(ComplaintModel complaint, SettingsProvider settings) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: complaint.statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(complaint.statusIcon, color: complaint.statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: settings.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: complaint.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: complaint.statusColor.withOpacity(0.5)),
              ),
              child: Text(
                complaint.status,
                style: TextStyle(
                  fontSize: 11,
                  color: complaint.statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Reports Modal Dialog
  void _showReportsDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: settings.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Detailed Reports',
                    style: TextStyle(
                      fontSize: 18,
                      color: settings.isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<ComplaintModel>>(
                stream: FirestoreService().getAllComplaints(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final complaints = snapshot.data ?? [];
                  int total = complaints.length;
                  int pending = complaints.where((c) => c.status == 'Pending').length;
                  int inProgress = complaints.where((c) => c.status == 'In Progress').length;
                  int resolved = complaints.where((c) => c.status == 'Resolved').length;
                  int rejected = complaints.where((c) => c.status == 'Rejected').length;

                  return Column(
                    children: [
                      _buildReportItem(Icons.pending_actions_rounded, "Pending", "$pending complaints pending", const Color(0xFFF59E0B), settings),
                      const SizedBox(height: 12),
                      _buildReportItem(Icons.sync_rounded, "In Progress", "$inProgress complaints in progress", const Color(0xFF8B5CF6), settings),
                      const SizedBox(height: 12),
                      _buildReportItem(Icons.check_circle_rounded, "Resolved", "$resolved complaints resolved", const Color(0xFF10B981), settings),
                      const SizedBox(height: 12),
                      _buildReportItem(Icons.cancel_rounded, "Rejected", "$rejected complaints rejected", const Color(0xFFEF4444), settings),
                      const Divider(height: 24),
                      _buildReportItem(Icons.assignment_rounded, "Total", "$total complaints total", const Color(0xFF3B82F6), settings),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(IconData icon, String title, String subtitle, Color color, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: settings.isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: settings.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
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