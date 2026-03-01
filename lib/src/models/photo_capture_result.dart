import 'dart:typed_data';
import 'location_data.dart';

/// Model class representing the result of a photo capture operation.
///
/// Contains the embedded photo in various formats, location data,
/// and metadata about the capture.
class PhotoCaptureResult {
  /// The photo bytes with embedded location information
  final Uint8List? photoBytes;

  /// The photo as base64 encoded string (if requested)
  final String? photoBase64;

  /// The file path where photo is temporarily saved (if requested)
  final String? filePath;

  /// The location data that was embedded on the photo
  final LocationData locationData;

  /// Whether the location was detected as mock/fake GPS
  final bool isMockLocation;

  /// Confidence score for location authenticity (0.0 - 1.0)
  /// 1.0 = highly confident real location
  /// 0.0 = highly confident fake location
  final double locationConfidence;

  /// Timestamp when the photo was captured
  final DateTime captureTimestamp;

  /// Size of the photo in bytes
  final int photoSize;

  PhotoCaptureResult({
    this.photoBytes,
    this.photoBase64,
    this.filePath,
    required this.locationData,
    this.isMockLocation = false,
    this.locationConfidence = 1.0,
    DateTime? captureTimestamp,
    this.photoSize = 0,
  }) : captureTimestamp = captureTimestamp ?? DateTime.now();

  /// Create a copy with updated fields
  PhotoCaptureResult copyWith({
    Uint8List? photoBytes,
    String? photoBase64,
    String? filePath,
    LocationData? locationData,
    bool? isMockLocation,
    double? locationConfidence,
    DateTime? captureTimestamp,
    int? photoSize,
  }) {
    return PhotoCaptureResult(
      photoBytes: photoBytes ?? this.photoBytes,
      photoBase64: photoBase64 ?? this.photoBase64,
      filePath: filePath ?? this.filePath,
      locationData: locationData ?? this.locationData,
      isMockLocation: isMockLocation ?? this.isMockLocation,
      locationConfidence: locationConfidence ?? this.locationConfidence,
      captureTimestamp: captureTimestamp ?? this.captureTimestamp,
      photoSize: photoSize ?? this.photoSize,
    );
  }
}
