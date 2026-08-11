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
        backgroundColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          'Delete Announcement',
          style: TextStyle(
            color: settings.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete: "$text"?',
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
              _deleteAnnouncement(docId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: settings.isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Announcements"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: settings.isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: settings.isDarkMode ? Colors.white : Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Input Field
            TextField(
              controller: announcementController,
              style: TextStyle(
                color: settings.isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: "Enter Announcement",
                hintStyle: TextStyle(
                  color: settings.isDarkMode ? Colors.grey[500] : Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.campaign,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                labelStyle: TextStyle(
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : null,
              ),
              enabled: !_isLoading,
            ),

            const SizedBox(height: 16),

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addAnnouncement,
                icon: const Icon(Icons.add),
                label: const Text(
                  "Add Announcement",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Announcements List - Live Data
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: settings.isDarkMode ? Colors.white : Colors.blue,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  "Previous Announcements",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: settings.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                StreamBuilder<List<AnnouncementModel>>(
                  stream: _firestoreService.getAnnouncements(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        '${snapshot.data!.length} items',
                        style: TextStyle(
                          fontSize: 12,
                          color: settings.isDarkMode ? Colors.grey[400] : Colors.grey.shade500,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Announcements List
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
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.notifications_off,
                      title: 'No announcements yet',
                      subtitle: 'Add your first announcement',
                    );
                  }

                  final announcements = snapshot.data!;
                  return ListView.builder(
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return Card(
                        color: settings.isDarkMode ? Colors.grey[850] : Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: settings.isDarkMode ? Colors.grey[700] : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.campaign,
                              color: settings.isDarkMode ? Colors.white : Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            announcement.text,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: settings.isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            announcement.formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: settings.isDarkMode ? Colors.grey[400] : Colors.grey.shade500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              _confirmDelete(announcement.id, announcement.text);
                            },
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