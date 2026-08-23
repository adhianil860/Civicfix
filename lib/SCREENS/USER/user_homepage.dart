import 'package:civicfic/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:civicfic/screens/user/user_complaintregistration.dart';
import 'package:civicfic/screens/user/user_complaintstatus.dart';
import 'package:civicfic/screens/user/user_profile.dart';
import 'package:civicfic/screens/user/user_notifications.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/notification_service.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/models/announcement_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class UserHomepage extends StatefulWidget {
  const UserHomepage({super.key});

  @override
  State<UserHomepage> createState() => _UserHomepageState();
}

class _UserHomepageState extends State<UserHomepage> {
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
        expand: false,
        builder: (context, scrollController) {
          final isDark = Provider.of<SettingsProvider>(context).isDarkMode;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.campaign, color: Color(0xFF4F46E5), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Announcements",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: StreamBuilder<List<AnnouncementModel>>(
                    stream: _firestoreService.getAnnouncements(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: isDark ? Colors.white : Colors.black)));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off, size: 60, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                "No announcements yet",
                                style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }
                      final announcements = snapshot.data!;
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = announcements[index];
                          return Container(
                            key: ValueKey(announcement.id),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active,
                                    color: Color(0xFF4F46E5),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        announcement.text,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        announcement.formattedDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
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
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => _navigateToPage(3),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
              child: FutureBuilder<UserModel?>(
                future: user != null ? _firestoreService.getUser(user.uid) : null,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Icon(Icons.person, size: 20, color: Color(0xFF4F46E5));
                  }
                  return Text(
                    snapshot.data!.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                "assets/images/CivicFix_logo.png",
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.build, color: Color(0xFF4F46E5), size: 24),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "CivicFix",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          StreamBuilder<int>(
            stream: user != null
                ? _firestoreService.getUnreadNotificationCount(user.uid)
                : const Stream.empty(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 24,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 2),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => _navigateToPage(4),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedPage,
        children: [
          HomeContent(
            navigateToPage: _navigateToPage,
            showAnnouncements: _showAnnouncements,
          ),
          const UserComplaintregistration(),
          const UserComplaintstatus(),
          const UserProfile(),
          const UserNotificationsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,
        onDestinationSelected: _navigateToPage,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        indicatorColor: const Color(0xFF4F46E5).withOpacity(0.2),
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF4F46E5)),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: Color(0xFF4F46E5)),
            label: 'Report',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: Color(0xFF4F46E5)),
            label: 'History',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF4F46E5)),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: StreamBuilder<int>(
              stream: user != null ? _firestoreService.getUnreadNotificationCount(user.uid) : const Stream.empty(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count > 0) {
                  return Badge(
                    label: Text('$count'),
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.notifications_outlined),
                  );
                }
                return const Icon(Icons.notifications_outlined);
              },
            ),
            selectedIcon: const Icon(Icons.notifications, color: Color(0xFF4F46E5)),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final Function(int)? navigateToPage;
  final VoidCallback? showAnnouncements;
  final FirestoreService _firestoreService = FirestoreService();

  HomeContent({super.key, this.navigateToPage, this.showAnnouncements});

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final isDark = settings.isDarkMode;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_getGreeting()} 👋",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FutureBuilder<UserModel?>(
                        future: user != null ? _firestoreService.getUser(user.uid) : null,
                        builder: (context, snapshot) {
                          String name = "User";
                          if (snapshot.hasData && snapshot.data != null) {
                            name = snapshot.data!.name;
                          }
                          return Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => navigateToPage?.call(1),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("New Report"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F46E5),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: showAnnouncements,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Live Stats
          Text(
            "Overview",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<ComplaintModel>>(
            stream: user != null
                ? _firestoreService.getUserComplaints(user.uid)
                : Stream.value([]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError) {
                return _buildStatsShimmer(isDark);
              }
              final complaints = snapshot.data ?? [];
              int total = complaints.length;
              int pending = complaints.where((c) => c.status == 'Pending').length;
              int inProgress = complaints.where((c) => c.status == 'In Progress').length;
              int resolved = complaints.where((c) => c.status == 'Resolved').length;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard("Total", total.toString(), Icons.analytics, const Color(0xFF4F46E5), isDark),
                  _buildStatCard("Pending", pending.toString(), Icons.pending_actions, Colors.orange, isDark),
                  _buildStatCard("In Progress", inProgress.toString(), Icons.sync, Colors.purple, isDark),
                  _buildStatCard("Resolved", resolved.toString(), Icons.check_circle_outline, Colors.green, isDark),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Categories Grid
          Text(
            "Quick Categories",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              _buildCategoryCard(Icons.construction, "Road", Colors.orange, isDark),
              _buildCategoryCard(Icons.lightbulb, "Light", Colors.amber, isDark),
              _buildCategoryCard(Icons.delete_outline, "Garbage", Colors.green, isDark),
              _buildCategoryCard(Icons.water_drop, "Water", Colors.blue, isDark),
              _buildCategoryCard(Icons.traffic, "Traffic", Colors.redAccent, isDark),
              _buildCategoryCard(Icons.park, "Tree", Colors.teal, isDark),
            ],
          ),
          const SizedBox(height: 24),

          // Civic Tip
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb_outline, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Community Tip",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Add clear photos and exact locations for faster resolution.",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.green.shade700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Emergency Contacts
          Text(
            "Emergency Contacts",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildEmergencyCard(Icons.local_police, "Police", "100", Colors.blue, context, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildEmergencyCard(Icons.local_hospital, "Medical", "108", Colors.redAccent, context, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildEmergencyCard(Icons.fire_truck, "Fire", "101", Colors.orange, context, isDark)),
            ],
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              "Made with ❤️ by CivicFix",
              style: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatsShimmer(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard("Total", "-", Icons.analytics, const Color(0xFF4F46E5), isDark),
        _buildStatCard("Pending", "-", Icons.pending_actions, Colors.orange, isDark),
        _buildStatCard("In Progress", "-", Icons.sync, Colors.purple, isDark),
        _buildStatCard("Resolved", "-", Icons.check_circle_outline, Colors.green, isDark),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String label, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(
    IconData icon,
    String title,
    String number,
    Color color,
    BuildContext context,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        NotificationService().showInfo(context, 'Calling $title: $number...');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              number,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}