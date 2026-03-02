import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'models/location_data.dart';
import 'models/photo_capture_result.dart';
import 'models/sdk_config.dart';
import 'services/camera_module.dart';
import 'services/image_processor.dart';
import 'services/location_service.dart';
import 'services/permission_manager.dart';
import 'services/storage_manager.dart';
import 'utils/format_converter.dart';

/// Main SDK class for GPS Photo Capture functionality.
///
/// Provides a high-level interface for capturing photos with embedded
/// GPS location information. Handles all the complexity of camera,
/// location, and image processing operations.
///
/// Example usage:
/// ```dart
/// final sdk = CdlPhotoGpsSDK(
///   config: SDKConfig(
///     outputFormat: OutputFormat.base64,
///     detectMockGPS: true,
///   ),
/// );
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
/// // Check if location is fake
/// if (result.isMockLocation) {
///   print('Warning: Mock GPS detected!');
/// }
///
/// // Use the result (format depends on config)
/// final base64 = result.photoBase64; // if OutputFormat.base64
/// final bytes = result.photoBytes;   // if OutputFormat.bytes
/// final path = result.filePath;      // if OutputFormat.file
///
/// // Cleanup
/// await sdk.dispose();
/// ```
class CdlPhotoGpsSDK {
  final SDKConfig config;
  
  final CameraModule _cameraModule = CameraModule();
  final LocationService _locationService = LocationService();
  final ImageProcessor _imageProcessor = ImageProcessor();
  final PermissionManager _permissionManager = PermissionManager();
  final StorageManager _storageManager = StorageManager();

  CdlPhotoGpsSDK({
    this.config = const SDKConfig(),
  });

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
  /// 3. Detects mock GPS (if enabled in config)
  /// 4. Embeds location information on the photo
  /// 5. Returns result in configured format (bytes/base64/file)
  ///
  /// Parameters:
  /// - [locationTimeout]: Timeout for GPS retrieval (uses config default if not specified)
  ///
  /// Returns: [PhotoCaptureResult] with photo and location data
  ///
  /// Throws: Various exceptions if capture, location, or processing fails
  Future<PhotoCaptureResult> capturePhotoWithLocation({
    Duration? locationTimeout,
  }) async {
    final timeout = locationTimeout ?? config.gpsTimeout;

    // Capture photo
    final photoBytes = await _cameraModule.capturePhoto();

    // Get location
    final locationData = await _locationService.getCurrentLocation(
      timeout: timeout,
    );

    // Detect mock GPS if enabled
    bool isMockLocation = false;
    double locationConfidence = 1.0;
    
    if (config.detectMockGPS) {
      isMockLocation = locationData.isMocked;
      // Calculate confidence score based on location data
      // This is a simple implementation - can be enhanced
      if (isMockLocation) {
        locationConfidence = 0.2; // Low confidence for mock locations
      } else if (locationData.accuracy > 100) {
        locationConfidence = 0.6; // Medium confidence for poor accuracy
      } else if (locationData.accuracy > 50) {
        locationConfidence = 0.8; // Good confidence
      } else {
        locationConfidence = 1.0; // High confidence
      }
    }

    // Embed location on photo with configured opacity
    final embeddedPhoto = await _imageProcessor.embedLocationOnPhoto(
      photoBytes: photoBytes,
      locationData: locationData,
      opacity: config.overlayOpacity,
    );

    // Convert to requested format
    Uint8List? resultBytes;
    String? resultBase64;
    String? resultFilePath;
    
    switch (config.outputFormat) {
      case OutputFormat.bytes:
        resultBytes = embeddedPhoto;
        break;
      case OutputFormat.base64:
        resultBase64 = FormatConverter.bytesToBase64(embeddedPhoto);
        break;
      case OutputFormat.file:
        resultFilePath = await FormatConverter.bytesToFile(embeddedPhoto);
        resultBytes = embeddedPhoto; // Also include bytes for convenience
        break;
    }

    return PhotoCaptureResult(
      photoBytes: resultBytes,
      photoBase64: resultBase64,
      filePath: resultFilePath,
      locationData: locationData,
      isMockLocation: isMockLocation,
      locationConfidence: locationConfidence,
      captureTimestamp: DateTime.now(),
      photoSize: embeddedPhoto.length,
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
      opacity: config.overlayOpacity,
    );
  }

  /// Get current zoom level
  double get currentZoom => _cameraModule.currentZoom;

  /// Get minimum zoom level
  double get minZoom => _cameraModule.minZoom;

  /// Get maximum zoom level
  double get maxZoom => _cameraModule.maxZoom;

  /// Set camera zoom level
  ///
  /// Parameters:
  /// - [zoom]: Zoom level (between minZoom and maxZoom)
  Future<void> setZoom(double zoom) async {
    await _cameraModule.setZoom(zoom);
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
