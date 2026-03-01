# CDL Photo GPS SDK - Integration Guide

Step-by-step guide to integrate the CDL Photo GPS SDK into your Flutter application.

## Prerequisites

- Flutter SDK 3.0 or higher
- Dart 3.9.2 or higher
- Android SDK 21+ or iOS 12.0+
- Device with camera and GPS capabilities

## Step 1: Add Dependency

Add the SDK to your `pubspec.yaml`:

```yaml
dependencies:
  cdl_photo_gps: ^0.0.1
```

Run:
```bash
flutter pub get
```

## Step 2: Configure Android

### AndroidManifest.xml

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    
    <!-- Add these features -->
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
    
    <application>
        <!-- Your existing configuration -->
    </application>
</manifest>
```

### build.gradle

Edit `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Ensure this is at least 21
        targetSdkVersion 34
    }
}
```

## Step 3: Configure iOS

### Info.plist

Edit `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- Add these permission descriptions -->
    <key>NSCameraUsageDescription</key>
    <string>This app requires camera access to capture photos.</string>
    
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app requires location access to embed GPS coordinates on photos.</string>
    
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app requires photo library access to save photos.</string>
    
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>This app requires permission to save photos to your photo library.</string>
    
    <!-- Your existing configuration -->
</dict>
```

### Podfile

Edit `ios/Podfile`:

```ruby
platform :ios, '12.0'  # Ensure this is at least 12.0
```

Run:
```bash
cd ios
pod install
cd ..
```

## Step 4: Import the SDK

In your Dart file:

```dart
import 'package:cdl_photo_gps/cdl_photo_gps.dart';
```

## Step 5: Initialize the SDK

```dart
class MyPhotoScreen extends StatefulWidget {
  @override
  _MyPhotoScreenState createState() => _MyPhotoScreenState();
}

class _MyPhotoScreenState extends State<MyPhotoScreen> {
  final CdlPhotoGpsSDK _sdk = CdlPhotoGpsSDK();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    try {
      // Check permissions
      if (!await _sdk.hasPermissions()) {
        final granted = await _sdk.requestPermissions();
        if (!granted) {
          // Handle permission denial
          print('Permissions not granted');
          return;
        }
      }

      // Initialize camera
      await _sdk.initialize(preset: ResolutionPreset.high);
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  @override
  void dispose() {
    _sdk.dispose();
    super.dispose();
  }

  // ... rest of your widget
}
```

## Step 6: Display Camera Preview

```dart
@override
Widget build(BuildContext context) {
  if (!_isInitialized) {
    return Center(child: CircularProgressIndicator());
  }

  return Scaffold(
    body: CameraPreview(_sdk.cameraController!),
    floatingActionButton: FloatingActionButton(
      onPressed: _capturePhoto,
      child: Icon(Icons.camera),
    ),
  );
}
```

## Step 7: Capture Photo with Location

```dart
Future<void> _capturePhoto() async {
  try {
    // Capture photo with location
    final result = await _sdk.capturePhotoWithLocation(
      locationTimeout: Duration(seconds: 15),
    );
    
    // Save photo
    final path = await _sdk.savePhoto(result.photoBytes);
    
    print('Photo saved to: $path');
    print('Location: ${result.locationData.formattedCoordinates}');
    print('Address: ${result.locationData.address ?? "Not available"}');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Photo saved successfully!')),
    );
  } on TimeoutException catch (e) {
    print('GPS timeout: $e');
    // Handle timeout
  } on LocationServiceDisabledException catch (e) {
    print('Location services disabled: $e');
    // Prompt user to enable location
  } on PermissionDeniedException catch (e) {
    print('Permission denied: $e');
    // Prompt user to grant permission
  } catch (e) {
    print('Capture error: $e');
    // Handle other errors
  }
}
```

## Step 8: Handle Errors Gracefully

```dart
void _showErrorDialog(String title, String message, {VoidCallback? onRetry}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    ),
  );
}

Future<void> _capturePhotoWithErrorHandling() async {
  try {
    final result = await _sdk.capturePhotoWithLocation();
    final path = await _sdk.savePhoto(result.photoBytes);
    _showSuccessMessage(path);
  } on TimeoutException {
    _showErrorDialog(
      'GPS Timeout',
      'Unable to get GPS location. Try again?',
      onRetry: _capturePhotoWithErrorHandling,
    );
  } on LocationServiceDisabledException {
    _showErrorDialog(
      'Location Services Disabled',
      'Please enable location services in your device settings.',
      onRetry: () => _sdk.openAppSettings(),
    );
  } on PermissionDeniedException {
    _showErrorDialog(
      'Permission Denied',
      'Camera or location permission is required. Grant permission in settings?',
      onRetry: () => _sdk.openAppSettings(),
    );
  } catch (e) {
    _showErrorDialog(
      'Error',
      'Failed to capture photo: $e',
      onRetry: _capturePhotoWithErrorHandling,
    );
  }
}
```

## Step 9: Add Camera Switching (Optional)

```dart
IconButton(
  icon: Icon(Icons.flip_camera_ios),
  onPressed: _sdk.hasMultipleCameras
      ? () async {
          try {
            await _sdk.switchCamera();
            setState(() {});
          } catch (e) {
            print('Failed to switch camera: $e');
          }
        }
      : null,
)
```

## Step 10: Test on Real Device

The SDK requires actual hardware (camera and GPS), so testing must be done on a physical device:

```bash
# Connect your device and run
flutter run --release
```

## Common Issues and Solutions

### Issue: Camera not initializing
**Solution:** Ensure camera permissions are granted and no other app is using the camera.

### Issue: Location timeout
**Solution:** 
- Move to an area with clear sky view
- Increase timeout duration
- Check if location services are enabled

### Issue: Address not available
**Solution:** 
- Ensure internet connectivity for geocoding
- The SDK will fall back to coordinates only if geocoding fails

### Issue: Photos not saving
**Solution:**
- Check storage permissions
- Verify available storage space
- Check file system access

### Issue: Build errors on iOS
**Solution:**
- Run `pod install` in the ios directory
- Clean build: `flutter clean && flutter pub get`

## Advanced Configuration

### Custom Resolution

```dart
await sdk.initialize(preset: ResolutionPreset.veryHigh);
```

Available presets:
- `ResolutionPreset.low` (352x288)
- `ResolutionPreset.medium` (720x480)
- `ResolutionPreset.high` (1280x720)
- `ResolutionPreset.veryHigh` (1920x1080)
- `ResolutionPreset.ultraHigh` (3840x2160)
- `ResolutionPreset.max` (highest available)

### Custom Timeout

```dart
final result = await sdk.capturePhotoWithLocation(
  locationTimeout: Duration(seconds: 30),
);
```

### Using Individual Services

For advanced use cases, you can use individual services:

```dart
// Just location
final locationService = LocationService();
final location = await locationService.getCurrentLocation();

// Just image processing
final imageProcessor = ImageProcessor();
final embedded = await imageProcessor.embedLocationOnPhoto(
  photoBytes: existingPhoto,
  locationData: location,
);
```

## Next Steps

- Review the [API Documentation](API_DOCUMENTATION.md)
- Check the [Example App](example/README.md)
- Explore the [Working Prototype](working_proto/)

## Support

For issues and questions:
- Check the [README](README.md)
- Review the [API Documentation](API_DOCUMENTATION.md)
- See the working prototype for reference implementation
