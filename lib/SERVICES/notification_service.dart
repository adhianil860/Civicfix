import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Show snackbar
  void showSnackBar(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // Show success snackbar
  void showSuccess(BuildContext context, String message) {
    showSnackBar(context, '✅ $message', color: Colors.green);
  }

  // Show error snackbar
  void showError(BuildContext context, String message) {
    showSnackBar(context, '❌ $message', color: Colors.red);
  }

  // Show info snackbar
  void showInfo(BuildContext context, String message) {
    showSnackBar(context, 'ℹ️ $message', color: Colors.blue);
  }
}