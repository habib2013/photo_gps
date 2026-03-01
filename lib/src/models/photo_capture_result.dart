import 'dart:typed_data';
import 'location_data.dart';

/// Model class representing the result of a photo capture operation.
///
/// Contains the embedded photo bytes, location data that was embedded,
/// and optionally the saved file path after the photo is saved to storage.
class PhotoCaptureResult {
  /// The photo bytes with embedded location information
  final Uint8List photoBytes;

  /// The location data that was embedded on the photo
  final LocationData locationData;

  /// The file path where the photo was saved (null if not yet saved)
  final String? savedPath;

  PhotoCaptureResult({
    required this.photoBytes,
    required this.locationData,
    this.savedPath,
  });

  /// Create a copy with updated fields
  PhotoCaptureResult copyWith({
    Uint8List? photoBytes,
    LocationData? locationData,
    String? savedPath,
  }) {
    return PhotoCaptureResult(
      photoBytes: photoBytes ?? this.photoBytes,
      locationData: locationData ?? this.locationData,
      savedPath: savedPath ?? this.savedPath,
    );
  }
}
