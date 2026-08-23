import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/image_service.dart';
import 'package:civicfic/services/validation_service.dart';
import 'package:civicfic/services/notification_service.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:provider/provider.dart';

import 'package:civicfic/screens/user/map_picker_screen.dart';

class UserComplaintregistration extends StatefulWidget {
  const UserComplaintregistration({super.key});

  @override
  State<UserComplaintregistration> createState() =>
      _UserComplaintregistrationState();
}

class _UserComplaintregistrationState extends State<UserComplaintregistration> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  String? selectedCategory;
  String? selectedPriority;

  double? selectedLatitude;
  double? selectedLongitude;

  final ImagePicker picker = ImagePicker();

  Uint8List? selectedImage;
  String? imageString;

  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();
  final ImageService _imageService = ImageService();

  final List<String> categories = [
    "Road Damage",
    "Street Light",
    "Garbage",
    "Water Leakage",
    "Traffic Signal",
    "Fallen Tree",
    "Others",
  ];

  final List<String> priorities = ["Low", "Medium", "High"];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      selectedImage = bytes;
      imageString = _imageService.encodeImage(bytes);
    });

    NotificationService().showInfo(context, 'Image uploaded successfully!');
  }

  Future<void> _pickLocationFromMap() async {
    try {
      final result = await Navigator.push<MapPickerResult>(
        context,
        MaterialPageRoute(
          builder: (context) => const MapPickerScreen(),
        ),
      );

      if (result != null && mounted) {
        String address = await _getAddressFromCoordinates(
          result.latitude,
          result.longitude,
        );

        setState(() {
          selectedLatitude = result.latitude;
          selectedLongitude = result.longitude;
          locationController.text = address;
        });

        NotificationService().showInfo(
          context,
          '📍 Location selected successfully!',
        );
      }
    } catch (e) {
      NotificationService().showError(
        context,
        'Failed to pick location: $e',
      );
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    return '📍 ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  Future<void> _submitComplaint() async {
    String? titleError = ValidationService.validateTitle(titleController.text.trim());
    if (titleError != null) {
      NotificationService().showError(context, titleError);
      return;
    }

    String? descError = ValidationService.validateDescription(
      descriptionController.text.trim(),
    );
    if (descError != null) {
      NotificationService().showError(context, descError);
      return;
    }

    String? locationError = ValidationService.validateLocation(
      locationController.text.trim(),
    );
    if (locationError != null) {
      NotificationService().showError(context, locationError);
      return;
    }

    if (selectedCategory == null) {
      NotificationService().showError(context, 'Please select a category');
      return;
    }

    if (selectedPriority == null) {
      NotificationService().showError(context, 'Please select a priority');
      return;
    }

    if (imageString == null) {
      NotificationService().showError(context, 'Please upload an image');
      return;
    }

    if (selectedLatitude == null || selectedLongitude == null) {
      NotificationService().showError(
        context,
        'Please select location from map using 📍 button',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final userModel = await _firestoreService.getUser(user.uid);
      String userName = userModel?.name ?? 'User';

      final complaint = ComplaintModel(
        id: '',
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategory!,
        priority: selectedPriority!,
        location: locationController.text.trim(),
        imageBase64: imageString,
        userId: user.uid,
        userName: userName,
        userEmail: user.email ?? '',
        status: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        latitude: selectedLatitude,
        longitude: selectedLongitude,
      );

      await _firestoreService.addComplaint(complaint);

      NotificationService().showSuccess(
        context,
        'Complaint Submitted Successfully! 🎉',
      );

      titleController.clear();
      descriptionController.clear();
      locationController.clear();
      setState(() {
        selectedCategory = null;
        selectedPriority = null;
        selectedImage = null;
        imageString = null;
        selectedLatitude = null;
        selectedLongitude = null;
        _isLoading = false;
      });

    } catch (e) {
      NotificationService().showError(context, e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, SettingsProvider settings) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: settings.isDarkMode ? Colors.grey[500] : Colors.grey[400],
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF4F46E5),
          ),
        ),
      ),
      filled: true,
      fillColor: settings.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: settings.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.edit_document, color: Colors.white, size: 32),
                    SizedBox(height: 12),
                    Text(
                      "Register a Complaint",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Help us improve your community.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Title Field
              Text(
                "Title",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: settings.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                style: TextStyle(color: settings.isDarkMode ? Colors.white : Colors.black),
                decoration: _buildInputDecoration("E.g., Pothole on Main St.", Icons.title, settings),
              ),
              const SizedBox(height: 20),

              // Description Field
              Text(
                "Description",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: settings.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                style: TextStyle(color: settings.isDarkMode ? Colors.white : Colors.black),
                decoration: _buildInputDecoration("Describe the issue in detail", Icons.description, settings),
              ),
              const SizedBox(height: 20),

              // Category & Priority
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Category",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: settings.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          dropdownColor: settings.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                          style: TextStyle(color: settings.isDarkMode ? Colors.white : Colors.black),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4F46E5)),
                          decoration: _buildInputDecoration("Select", Icons.category, settings),
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedCategory = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Priority",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: settings.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedPriority,
                          dropdownColor: settings.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                          style: TextStyle(color: settings.isDarkMode ? Colors.white : Colors.black),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4F46E5)),
                          decoration: _buildInputDecoration("Select", Icons.priority_high, settings),
                          items: priorities.map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Text(priority),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedPriority = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Location Field
              Text(
                "Location",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: settings.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: locationController,
                      readOnly: true,
                      style: TextStyle(color: settings.isDarkMode ? Colors.white : Colors.black),
                      decoration: _buildInputDecoration("Tap map button to select", Icons.location_on, settings),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _pickLocationFromMap,
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.map, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
              if (selectedLatitude != null && selectedLongitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '📍 ${selectedLatitude!.toStringAsFixed(5)}, ${selectedLongitude!.toStringAsFixed(5)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: settings.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Image Upload
              Text(
                "Upload Image",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: settings.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (selectedImage == null)
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: settings.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withOpacity(0.5),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_a_photo, color: Color(0xFF4F46E5), size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap to upload a photo",
                          style: TextStyle(
                            color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        selectedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImage = null;
                            imageString = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              // Submit Button
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Submit Complaint",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.send, color: Colors.white, size: 20),
                          ],
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
}