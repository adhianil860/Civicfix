import 'package:flutter/material.dart';

class ComplaintModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String location;
  final String? imageBase64;
  final String userId;
  final String userName;
  final String userEmail;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 👇 ADD THESE TWO FIELDS
  final double? latitude;
  final double? longitude;

  ComplaintModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.location,
    this.imageBase64,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.status = 'Pending',
    required this.createdAt,
    required this.updatedAt,
    // 👇 Add here
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'location': location,
      'imageBase64': imageBase64,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      // 👇 Add here
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? 'Medium',
      location: map['location'] ?? '',
      imageBase64: map['imageBase64'],
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as dynamic).toDate(),
      updatedAt: (map['updatedAt'] as dynamic).toDate(),
      // 👇 Add here
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  // Status color
  Color get statusColor {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Status icon
  IconData get statusIcon {
    switch (status) {
      case 'Pending':
        return Icons.pending;
      case 'In Progress':
        return Icons.sync;
      case 'Resolved':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // Category icon
  IconData get categoryIcon {
    switch (category) {
      case 'Road Damage':
        return Icons.construction;
      case 'Street Light':
        return Icons.lightbulb;
      case 'Garbage':
        return Icons.delete;
      case 'Water Leakage':
        return Icons.water_damage;
      case 'Traffic Signal':
        return Icons.traffic;
      case 'Fallen Tree':
        return Icons.park;
      default:
        return Icons.report_problem;
    }
  }
}