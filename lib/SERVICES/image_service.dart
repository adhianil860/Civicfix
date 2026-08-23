import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<Uint8List?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );
    if (image == null) return null;
    return await image.readAsBytes();
  }

  // Pick image from camera
  Future<Uint8List?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
    );
    if (image == null) return null;
    return await image.readAsBytes();
  }

  // Encode image to Base64
  String encodeImage(Uint8List bytes) {
    return base64Encode(bytes);
  }

  // Safely decode Base64 string to Uint8List bytes
  Uint8List? safeDecodeImage(String? base64String) {
    if (base64String == null || base64String.trim().isEmpty) return null;
    try {
      String clean = base64String.trim();
      if (clean.contains(',')) {
        clean = clean.split(',').last;
      }
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      while (clean.length % 4 != 0) {
        clean += '=';
      }
      final bytes = base64Decode(clean);
      return bytes.isNotEmpty ? bytes : null;
    } catch (e) {
      return null;
    }
  }

  // Decode Base64 to image
  Uint8List decodeImage(String base64String) {
    return safeDecodeImage(base64String) ?? Uint8List(0);
  }

  // Check if image is valid
  bool isValidImage(Uint8List bytes) {
    try {
      return bytes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Build safe image widget for UI
  static Widget buildImageWidget(
    String? base64String, {
    double? height,
    double? width = double.infinity,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    if (base64String == null || base64String.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      String clean = base64String.trim();
      if (clean.contains(',')) {
        clean = clean.split(',').last;
      }
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      while (clean.length % 4 != 0) {
        clean += '=';
      }
      final bytes = base64Decode(clean);
      if (bytes.isEmpty) return const SizedBox.shrink();

      Widget imageWidget = Image.memory(
        bytes,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 120,
          width: width,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey),
                SizedBox(width: 8),
                Text('Image loading error', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      );

      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: imageWidget,
        );
      }
      return imageWidget;
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}