import 'dart:typed_data';
import 'package:camera/camera.dart';

/// Manages camera initialization, preview, and photo capture.
///
/// Provides a simple interface for camera operations with proper
/// resource management and error handling.
class CameraModule {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  /// Gets the camera controller for use in preview widgets
  CameraController? get controller => _controller;

  /// Checks if the camera is initialized and ready to use
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Checks if the device has multiple cameras (front and rear)
  bool get hasMultipleCameras => (_cameras?.length ?? 0) > 1;

  /// Initialize the camera with the specified resolution preset
  ///
  /// Parameters:
  /// - [preset]: Resolution preset (default: ResolutionPreset.high)
  ///
  /// Throws: Exception if camera initialization fails
  Future<void> initialize({
    ResolutionPreset preset = ResolutionPreset.high,
  }) async {
    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      // Use the first rear camera (or first camera if no rear camera)
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Create and initialize controller
      _controller = CameraController(
        camera,
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
    } catch (e) {
      throw Exception('Failed to initialize camera: $e');
    }
  }

  /// Capture a photo and return it as bytes
  ///
  /// Returns: Photo data as Uint8List
  ///
  /// Throws: Exception if capture fails or camera is not initialized
  Future<Uint8List> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera is not initialized');
    }

    try {
      // Ensure camera is ready
      if (_controller!.value.isTakingPicture) {
        throw Exception('Camera is already capturing');
      }

      final XFile image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      
      return bytes;
    } catch (e) {
      throw Exception('Failed to capture photo: $e');
    }
  }

  /// Get current zoom level
  double get currentZoom => 1.0;

  /// Get minimum zoom level
  double get minZoom => 1.0;

  /// Get maximum zoom level
  double get maxZoom => 8.0;

  /// Set zoom level
  ///
  /// Parameters:
  /// - [zoom]: Zoom level (between minZoom and maxZoom)
  Future<void> setZoom(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera is not initialized');
    }

    try {
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _controller!.setZoomLevel(clampedZoom);
    } catch (e) {
      // Zoom might not be supported on all devices
      // Silently fail
    }
  }

  /// Switch between front and rear cameras
  ///
  /// Throws: Exception if camera switch fails or only one camera is available
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      throw Exception('Cannot switch camera: only one camera available');
    }

    if (_controller == null) {
      throw Exception('Camera is not initialized');
    }

    try {
      // Get current camera direction
      final currentDirection = _controller!.description.lensDirection;

      // Find camera with opposite direction
      final newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection != currentDirection,
        orElse: () => _cameras!.first,
      );

      // Dispose current controller
      await _controller!.dispose();

      // Create new controller with new camera
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
    } catch (e) {
      throw Exception('Failed to switch camera: $e');
    }
  }

  /// Dispose camera resources
  ///
  /// Must be called when done using the camera to prevent memory leaks
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
