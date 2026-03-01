import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cdl_photo_gps/cdl_photo_gps.dart';
import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final CdlPhotoGpsSDK _sdk;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize SDK with configuration
    _sdk = CdlPhotoGpsSDK(
      config: const SDKConfig(
        outputFormat: OutputFormat.bytes, // Can be changed to base64 or file
        detectMockGPS: true, // Enable mock GPS detection
        gpsTimeout: Duration(seconds: 15),
        showPermissionRationale: true,
      ),
    );
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    try {
      // Check permissions
      if (!await _sdk.hasPermissions()) {
        // Show rationale before requesting
        if (_sdk.config.showPermissionRationale) {
          await _showPermissionRationale();
        }
        
        final granted = await _sdk.requestPermissions();
        if (!granted) {
          setState(() {
            _errorMessage = 'Camera and location permissions are required';
          });
          return;
        }
      }

      // Initialize camera
      await _sdk.initialize(preset: ResolutionPreset.high);
      
      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _showPermissionRationale() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Camera access is needed to capture client photos',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Location access is needed to verify visit authenticity',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Capture photo with location
      final result = await _sdk.capturePhotoWithLocation();

      if (!mounted) return;

      // Check for mock GPS
      if (result.isMockLocation) {
        final proceed = await _showMockGPSWarning(result.locationConfidence);
        if (!proceed) {
          setState(() {
            _isCapturing = false;
          });
          return;
        }
      }

      if (!mounted) return;

      // Navigate to preview screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(result: result),
        ),
      );
    } on TimeoutException catch (e) {
      _showErrorDialog('GPS Timeout', e.toString(), canRetry: true);
    } on LocationServiceDisabledException catch (e) {
      _showErrorDialog('Location Services Disabled', e.toString());
    } on PermissionDeniedException catch (e) {
      _showErrorDialog('Permission Denied', e.toString());
    } catch (e) {
      _showErrorDialog('Capture Failed', e.toString(), canRetry: true);
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<bool> _showMockGPSWarning(double confidence) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Mock GPS Detected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The location appears to be from a fake GPS app.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Location confidence: ${(confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: confidence < 0.5 ? Colors.red : Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Do you want to proceed anyway?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Proceed Anyway'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _switchCamera() async {
    if (!_sdk.hasMultipleCameras) return;

    try {
      await _sdk.switchCamera();
      setState(() {});
    } catch (e) {
      _showErrorDialog('Camera Switch Failed', e.toString());
    }
  }

  void _showErrorDialog(String title, String message, {bool canRetry = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (canRetry)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _capturePhoto();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(canRetry ? 'Cancel' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('GPS Photo Capture')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _initializeSDK,
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _sdk.openAppSettings(),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          SizedBox.expand(
            child: CameraPreview(_sdk.cameraController!),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GPS Photo Capture',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.verified_user, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Mock GPS Detection: ON',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_sdk.hasMultipleCameras)
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.flip_camera_ios),
                      color: Colors.white,
                      iconSize: 32,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Capture button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isCapturing ? null : _capturePhoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: _isCapturing
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.blue,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: Colors.blue,
                        ),
                ),
              ),
            ),
          ),

          // Capturing overlay
          if (_isCapturing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Capturing photo...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Getting GPS location and verifying...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sdk.dispose();
    super.dispose();
  }
}
