import 'dart:convert';
import 'dart:typed_data';
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

  // Decode Base64 to image
  Uint8List decodeImage(String base64String) {
    return base64Decode(base64String);
  }

  // Check if image is valid
  bool isValidImage(Uint8List bytes) {
    try {
      // Check if it's a valid image by trying to decode as JPEG/PNG
      // Simple check: size should be > 0
      return bytes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}