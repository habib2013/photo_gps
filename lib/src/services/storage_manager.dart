import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Manages saving photos to device storage.
///
/// Handles file system operations with proper error handling
/// and directory management.
class StorageManager {
  /// Save a photo to device storage
  ///
  /// Parameters:
  /// - [photoBytes]: Image data as Uint8List
  /// - [filename]: Custom filename (default: auto-generated with timestamp)
  ///
  /// Returns: Full path to saved file
  ///
  /// Throws: [StorageException] if save fails
  Future<String> savePhoto(
    Uint8List photoBytes, {
    String? filename,
  }) async {
    try {
      // Get photos directory
      final directory = await getPhotosDirectory();
      final dir = Directory(directory);

      // Create directory if it doesn't exist
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Generate filename if not provided
      final name = filename ?? _generateFilename();

      // Create full path
      final filePath = '$directory/$name';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(photoBytes);

      return filePath;
    } catch (e) {
      throw StorageException('Failed to save photo: $e');
    }
  }

  /// Get the directory path where photos are stored
  ///
  /// Returns: Directory path as string
  ///
  /// Throws: [StorageException] if directory access fails
  Future<String> getPhotosDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/gps_photos';
    } catch (e) {
      throw StorageException('Failed to get photos directory: $e');
    }
  }

  /// Get available storage space in bytes
  ///
  /// Returns: Available space in bytes
  Future<int> getAvailableSpace() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = await directory.stat();
      // Note: This is a simplified implementation
      // For accurate storage info, consider using a platform-specific plugin
      return stat.size;
    } catch (e) {
      // Return a large number if we can't determine space
      return 1024 * 1024 * 1024; // 1GB
    }
  }

  /// Generate a unique filename with timestamp
  String _generateFilename() {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'gps_photo_$timestamp.jpg';
  }
}

/// Exception thrown when storage operations fail
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => message;
}
