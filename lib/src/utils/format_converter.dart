import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Utility class for converting photo data between different formats
class FormatConverter {
  /// Convert bytes to base64 string
  static String bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Convert base64 string to bytes
  static Uint8List base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }

  /// Save bytes to a temporary file and return the file path
  ///
  /// The file will be saved in the app's temporary directory.
  /// The caller is responsible for deleting the file when done.
  static Future<String> bytesToFile(
    Uint8List bytes, {
    String? filename,
  }) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();

      // Generate filename if not provided
      final name = filename ?? _generateFilename();

      // Create file path
      final filePath = '${tempDir.path}/$name';

      // Write bytes to file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save photo to file: $e');
    }
  }

  /// Read bytes from a file
  static Future<Uint8List> fileToBytes(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read photo from file: $e');
    }
  }

  /// Delete a temporary file
  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently fail - file might already be deleted
    }
  }

  /// Generate a unique filename with timestamp
  static String _generateFilename() {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'gps_photo_$timestamp.jpg';
  }

  /// Get the size of data in bytes
  static int getSize(dynamic data) {
    if (data is Uint8List) {
      return data.length;
    } else if (data is String) {
      // Approximate size of base64 string
      return (data.length * 0.75).round();
    }
    return 0;
  }

  /// Format bytes to human-readable size
  static String formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
