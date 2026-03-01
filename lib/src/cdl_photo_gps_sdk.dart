import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'models/location_data.dart';
import 'models/photo_capture_result.dart';
import 'services/camera_module.dart';
import 'services/image_processor.dart';
import 'services/location_service.dart';
import 'services/permission_manager.dart';
import 'services/storage_manager.dart';

/// Main SDK class for GPS Photo Capture functionality.
///
/// Provides a high-level interface for capturing photos with embedded
/// GPS location information. Handles all the complexity of camera,
/// location, and image processing operations.
///
/// Example usage:
/// ```dart
/// final sdk = CdlPhotoGpsSDK();
///
/// // Initialize
/// await sdk.initialize();
///
/// // Check permissions
/// if (!await sdk.hasPermissions()) {
///   await sdk.requestPermissions();
/// }
///
/// // Capture photo with location
/// final result = await sdk.capturePhotoWithLocation();
///
/// // Save photo
/// final path = await sdk.savePhoto(result.photoBytes);
///
/// // Cleanup
/// await sdk.dispose();
/// ```
class CdlPhotoGpsSDK {
  final CameraModule _cameraModule = CameraModule();
  final LocationService _locationService = LocationService();
  final ImageProcessor _imageProcessor = ImageProcessor();
  final PermissionManager _permissionManager = PermissionManager();
  final StorageManager _storageManager = StorageManager();

  /// Get the camera controller for preview widgets
  CameraController? get cameraController => _cameraModule.controller;

  /// Check if camera is initialized
  bool get isCameraInitialized => _cameraModule.isInitialized;

  /// Check if device has multiple cameras
  bool get hasMultipleCameras => _cameraModule.hasMultipleCameras;

  /// Initialize the SDK and camera
  ///
  /// Must be called before using camera features.
  ///
  /// Parameters:
  /// - [preset]: Camera resolution preset (default: ResolutionPreset.high)
  ///
  /// Throws: Exception if initialization fails
  Future<void> initialize({
    ResolutionPreset preset = ResolutionPreset.high,
  }) async {
    await _cameraModule.initialize(preset: preset);
  }

  /// Check if all required permissions are granted
  Future<bool> hasPermissions() async {
    return await _permissionManager.hasAllPermissions();
  }

  /// Request camera and location permissions
  ///
  /// Returns true if both permissions are granted
  Future<bool> requestPermissions() async {
    final cameraStatus = await _permissionManager.requestCameraPermission();
    final locationStatus = await _permissionManager.requestLocationPermission();

    return cameraStatus == PermissionStatus.granted &&
        locationStatus == PermissionStatus.granted;
  }

  /// Open app settings for manual permission management
  Future<void> openAppSettings() async {
    await _permissionManager.openAppSettings();
  }

  /// Capture a photo with embedded GPS location
  ///
  /// This is the main SDK method that:
  /// 1. Captures a photo using the camera
  /// 2. Retrieves current GPS location
  /// 3. Embeds location information on the photo
  ///
  /// Parameters:
  /// - [locationTimeout]: Timeout for GPS retrieval (default: 15 seconds)
  ///
  /// Returns: [PhotoCaptureResult] with embedded photo and location data
  ///
  /// Throws: Various exceptions if capture, location, or processing fails
  Future<PhotoCaptureResult> capturePhotoWithLocation({
    Duration locationTimeout = const Duration(seconds: 15),
  }) async {
    // Capture photo
    final photoBytes = await _cameraModule.capturePhoto();

    // Get location
    final locationData = await _locationService.getCurrentLocation(
      timeout: locationTimeout,
    );

    // Embed location on photo
    final embeddedPhoto = await _imageProcessor.embedLocationOnPhoto(
      photoBytes: photoBytes,
      locationData: locationData,
    );

    return PhotoCaptureResult(
      photoBytes: embeddedPhoto,
      locationData: locationData,
    );
  }

  /// Capture a photo without location (camera only)
  ///
  /// Useful when location is unavailable or not required.
  ///
  /// Returns: Photo bytes as Uint8List
  Future<Uint8List> capturePhoto() async {
    return await _cameraModule.capturePhoto();
  }

  /// Get current GPS location
  ///
  /// Parameters:
  /// - [timeout]: Timeout for GPS retrieval (default: 15 seconds)
  ///
  /// Returns: [LocationData] with coordinates and optional address
  Future<LocationData> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return await _locationService.getCurrentLocation(timeout: timeout);
  }

  /// Embed location information on an existing photo
  ///
  /// Useful for processing previously captured photos.
  ///
  /// Parameters:
  /// - [photoBytes]: Raw photo data
  /// - [locationData]: Location information to embed
  ///
  /// Returns: Processed photo bytes with embedded location
  Future<Uint8List> embedLocation({
    required Uint8List photoBytes,
    required LocationData locationData,
  }) async {
    return await _imageProcessor.embedLocationOnPhoto(
      photoBytes: photoBytes,
      locationData: locationData,
    );
  }

  /// Save a photo to device storage
  ///
  /// Parameters:
  /// - [photoBytes]: Photo data to save
  /// - [filename]: Optional custom filename
  ///
  /// Returns: Full path to saved file
  Future<String> savePhoto(
    Uint8List photoBytes, {
    String? filename,
  }) async {
    return await _storageManager.savePhoto(photoBytes, filename: filename);
  }

  /// Switch between front and rear cameras
  ///
  /// Throws: Exception if only one camera is available
  Future<void> switchCamera() async {
    await _cameraModule.switchCamera();
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _locationService.isLocationServiceEnabled();
  }

  /// Get the directory where photos are stored
  Future<String> getPhotosDirectory() async {
    return await _storageManager.getPhotosDirectory();
  }

  /// Dispose SDK resources
  ///
  /// Must be called when done using the SDK to prevent memory leaks
  Future<void> dispose() async {
    await _cameraModule.dispose();
  }
}
