import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civicfic/services/firestore_service.dart';
import 'package:civicfic/services/image_service.dart';
import 'package:civicfic/services/validation_service.dart';
import 'package:civicfic/services/notification_service.dart';
import 'package:civicfic/models/complaint_model.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:provider/provider.dart';

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
      );

      await _firestoreService.addComplaint(complaint);

      NotificationService().showSuccess(
        context,
        'Complaint Submitted Successfully!',
      );

      titleController.clear();
      descriptionController.clear();
      locationController.clear();
      setState(() {
        selectedCategory = null;
        selectedPriority = null;
        selectedImage = null;
        imageString = null;
        _isLoading = false;
      });

    } catch (e) {
      NotificationService().showError(context, e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return Container(
      color: settings.isDarkMode ? Colors.grey[900] : Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Complaint Title",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                style: TextStyle(
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: "Enter complaint title",
                  hintStyle: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[500] : Colors.grey[400],
                  ),
                  border: border,
                  prefixIcon: Icon(
                    Icons.title,
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                  labelStyle: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Complaint Description",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                style: TextStyle(
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: "Describe your complaint",
                  hintStyle: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[500] : Colors.grey[400],
                  ),
                  border: border,
                  prefixIcon: Icon(
                    Icons.description,
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                  labelStyle: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Category",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
                style: TextStyle(
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  border: border,
                  prefixIcon: Icon(
                    Icons.category,
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                  labelStyle: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                hint: Text(
                  "Select Category",
                  style: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: settings.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              Text(
                "Priority",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                dropdownColor: settings.isDarkMode ? Colors.grey[800] : Colors.white,
                style: TextStyle(
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  border: border,
                  prefixIcon: Icon(
                    Icons.priority_high,
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                  labelStyle: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                hint: Text(
                  "Select Priority",
                  style: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
                items: priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(
                      priority,
                      style: TextStyle(
                        color: settings.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPriority = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              Text(
                "Location",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationController,
                style: TextStyle(
                  color: settings.isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: "Enter complaint location",
                  hintStyle: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[500] : Colors.grey[400],
                  ),
                  border: border,
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: settings.isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                  labelStyle: TextStyle(
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Upload Image
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: pickImage,
                  icon: Icon(
                    Icons.image,
                    color: settings.isDarkMode ? Colors.grey[400] : Colors.blue.shade300,
                  ),
                  label: Text(
                    "Upload Image",
                    style: TextStyle(
                      fontSize: 16,
                      color: settings.isDarkMode ? Colors.grey[400] : Colors.black,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: settings.isDarkMode ? Colors.grey[600] ?? Colors.grey : Colors.blue.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Image Preview
              if (selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        selectedImage!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.red.withOpacity(0.8),
                        radius: 16,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          onPressed: () {
                            setState(() {
                              selectedImage = null;
                              imageString = null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Submit Complaint",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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