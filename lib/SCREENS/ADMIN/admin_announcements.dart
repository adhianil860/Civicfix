import 'package:flutter/material.dart';
import 'package:civicfic/WIDGETS/empty_state_widget.dart';
import 'package:civicfic/WIDGETS/loading_widget.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/notification_service.dart';
import 'package:civicfic/models/announcement_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class AdminAnnouncements extends StatefulWidget {
  const AdminAnnouncements({super.key});

  @override
  State<AdminAnnouncements> createState() => _AdminAnnouncementsState();
}

class _AdminAnnouncementsState extends State<AdminAnnouncements> {
  final TextEditingController announcementController = TextEditingController();
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    announcementController.dispose();
    super.dispose();
  }

  Future<void> _addAnnouncement() async {
    String text = announcementController.text.trim();
    if (text.isEmpty) {
      NotificationService().showError(context, 'Please enter an announcement');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.addAnnouncement(text);
      
      announcementController.clear();
      NotificationService().showSuccess(
        context,
        'Announcement added successfully!',
      );
    } catch (e) {
      NotificationService().showError(
        context,
        'Error: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAnnouncement(String docId) async {
    try {
      await _firestoreService.deleteAnnouncement(docId);
      
      NotificationService().showInfo(
        context,
        'Announcement deleted',
      );
    } catch (e) {
      NotificationService().showError(
        context,
        'Error: $e',
      );
    }
  }

  void _confirmDelete(String docId, String text) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: settings.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Announcement',
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete: "$text"?',
          style: TextStyle(
            color: settings.isDarkMode ? Colors.grey[300] : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnnouncement(docId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: settings.isDarkMode ? Colors.grey[900] : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Announcements"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: settings.isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: settings.isDarkMode ? Colors.white : Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: settings.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: settings.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "New Announcement",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: settings.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: announcementController,
                    style: TextStyle(
                      color: settings.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: "What do citizens need to know?",
                      hintStyle: TextStyle(
                        color: settings.isDarkMode ? Colors.grey[500] : Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: Color(0xFF4F46E5),
                            size: 20,
                          ),
                        ),
                      ),
                      filled: true,
                      fillColor: settings.isDarkMode ? Colors.grey[800] : const Color(0xFFF9FAFB),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addAnnouncement,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text(
                        "Add Announcement",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Announcements Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: settings.isDarkMode ? Colors.grey[800] : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: settings.isDarkMode ? Colors.white : const Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Recent Announcements",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: settings.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                StreamBuilder<List<AnnouncementModel>>(
                  stream: _firestoreService.getAnnouncements(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${snapshot.data!.length} Live',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Live Announcements Stream List
            Expanded(
              child: StreamBuilder<List<AnnouncementModel>>(
                stream: _firestoreService.getAnnouncements(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 60, color: Color(0xFFEF4444)),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.notifications_off_rounded,
                      title: 'No announcements yet',
                      subtitle: 'Add your first announcement',
                    );
                  }

                  final announcements = snapshot.data!;
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return Container(
                        key: ValueKey(announcement.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: settings.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: settings.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              // Gradient callout line
                              Container(
                                width: 6,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: settings.isDarkMode ? Colors.grey[800] : const Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: 14,
                                                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  announcement.formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: settings.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => _confirmDelete(announcement.id, announcement.text),
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Color(0xFFEF4444),
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        announcement.text,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                          height: 1.4,
                                          color: settings.isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}