import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ExternalImageUploadService {
  static const String _uploadEndpoint =
      'https://app.boostlykw.com/api/upload.php';

  /// Upload a single image file to the external API
  /// Returns the uploaded image URL on success
  Future<String> uploadImage(XFile imageFile) async {
    try {
      // Validate file size (5MB limit)
      final fileSize = await imageFile.length();
      const maxSize = 5 * 1024 * 1024; // 5MB in bytes

      if (fileSize > maxSize) {
        throw Exception('File too large. Maximum size is 5MB.');
      }

      // Validate file type
      final fileName = imageFile.name.toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      final hasValidExtension = allowedExtensions.any(
        (ext) => fileName.endsWith(ext),
      );

      if (!hasValidExtension) {
        throw Exception(
          'Invalid file type. Only JPEG, PNG, GIF, and WebP are allowed.',
        );
      }

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));

      if (kIsWeb) {
        // للويب: استخدم bytes
        Uint8List bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: imageFile.name),
        );
      } else {
        // للموبايل: استخدم المسار
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      }

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return responseData['url'];
        } else {
          throw Exception(
            'Upload failed: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Upload failed: ${errorData['error'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images and return their URLs
  Future<List<String>> uploadImages(List<XFile> images) async {
    List<String> imageUrls = [];

    for (var image in images) {
      try {
        final url = await uploadImage(image);
        imageUrls.add(url);
      } catch (e) {
        debugPrint('Failed to upload image ${image.name}: $e');
      }
    }

    return imageUrls;
  }

  /// Upload images with progress callback
  Future<List<String>> uploadImagesWithProgress(
    List<XFile> images,
    Function(int current, int total)? onProgress,
  ) async {
    List<String> imageUrls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        final url = await uploadImage(images[i]);
        imageUrls.add(url);
        onProgress?.call(i + 1, images.length);
      } catch (e) {
        debugPrint('Failed to upload image ${images[i].name}: $e');
      }
    }

    return imageUrls;
  }
}
