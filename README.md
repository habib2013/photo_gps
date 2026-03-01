# CDL Photo GPS SDK

A Flutter SDK for capturing photos with embedded GPS location information. Automatically overlays coordinates, address, and timestamp directly onto images.

## Features

- 📷 **Camera Integration**: High-quality photo capture with device camera
- 📍 **GPS Location**: Automatic GPS coordinate retrieval
- 🗺️ **Address Lookup**: Convert coordinates to human-readable addresses
- 🖼️ **Location Embedding**: Permanently overlay location info on photos
- 💾 **Local Storage**: Save embedded photos to device storage
- 🔐 **Permission Management**: Comprehensive permission handling
- 📡 **Offline Support**: Works without internet (GPS coordinates only)
- ⚡ **Error Recovery**: Graceful handling of timeouts and failures

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  cdl_photo_gps: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Platform Configuration

### Android

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    
    <!-- Features -->
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
    
    <application>
        <!-- Your app configuration -->
    </application>
</manifest>
```

Set minimum SDK version in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS

Edit `ios/Runner/Info.plist`:

```xml
<dict>
    <key>NSCameraUsageDescription</key>
    <string>This app requires camera access to capture photos.</string>
    
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app requires location access to embed GPS coordinates on photos.</string>
    
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app requires photo library access to save photos.</string>
    
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>This app requires permission to save photos to your photo library.</string>
</dict>
```

Set minimum iOS version in `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:cdl_photo_gps/cdl_photo_gps.dart';
import 'package:camera/camera.dart';

class PhotoCaptureScreen extends StatefulWidget {
  @override
  _PhotoCaptureScreenState createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  final CdlPhotoGpsSDK _sdk = CdlPhotoGpsSDK();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    try {
      // Request permissions
      if (!await _sdk.hasPermissions()) {
        final granted = await _sdk.requestPermissions();
        if (!granted) {
          // Handle permission denial
          return;
        }
      }

      // Initialize camera
      await _sdk.initialize();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      // Capture photo with location
      final result = await _sdk.capturePhotoWithLocation();
      
      // Save photo
      final path = await _sdk.savePhoto(result.photoBytes);
      
      print('Photo saved to: $path');
      print('Location: ${result.locationData.formattedCoordinates}');
      print('Address: ${result.locationData.address}');
    } catch (e) {
      print('Capture error: $e');
    }
  }

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

  @override
  void dispose() {
    _sdk.dispose();
    super.dispose();
  }
}
```

## API Reference

### CdlPhotoGpsSDK

Main SDK class providing high-level interface.

#### Methods

##### `initialize({ResolutionPreset preset})`

Initialize the SDK and camera.

```dart
await sdk.initialize(preset: ResolutionPreset.high);
```

##### `hasPermissions()`

Check if all required permissions are granted.

```dart
final hasPerms = await sdk.hasPermissions();
```

##### `requestPermissions()`

Request camera and location permissions.

```dart
final granted = await sdk.requestPermissions();
```

##### `capturePhotoWithLocation({Duration locationTimeout})`

Capture photo with embedded GPS location.

```dart
final result = await sdk.capturePhotoWithLocation(
  locationTimeout: Duration(seconds: 15),
);
```

##### `savePhoto(Uint8List photoBytes, {String? filename})`

Save photo to device storage.

```dart
final path = await sdk.savePhoto(result.photoBytes);
```

##### `dispose()`

Dispose SDK resources.

```dart
await sdk.dispose();
```

### LocationData

Model representing GPS location information.

#### Properties

- `latitude` (double): Latitude in degrees
- `longitude` (double): Longitude in degrees
- `accuracy` (double): GPS accuracy in meters
- `timestamp` (DateTime): When location was captured
- `address` (String?): Human-readable address

#### Getters

- `formattedCoordinates`: Coordinates as "lat, long"
- `formattedTimestamp`: Timestamp as "YYYY-MM-DD HH:MM:SS"

### PhotoCaptureResult

Result of photo capture operation.

#### Properties

- `photoBytes` (Uint8List): Embedded photo data
- `locationData` (LocationData): Location information
- `savedPath` (String?): File path if saved

## Advanced Usage

### Using Individual Services

For more control, you can use individual services:

```dart
import 'package:cdl_photo_gps/cdl_photo_gps.dart';

// Camera only
final cameraModule = CameraModule();
await cameraModule.initialize();
final photoBytes = await cameraModule.capturePhoto();

// Location only
final locationService = LocationService();
final location = await locationService.getCurrentLocation();

// Image processing only
final imageProcessor = ImageProcessor();
final embedded = await imageProcessor.embedLocationOnPhoto(
  photoBytes: photoBytes,
  locationData: location,
);

// Storage only
final storageManager = StorageManager();
final path = await storageManager.savePhoto(embedded);
```

### Error Handling

```dart
try {
  final result = await sdk.capturePhotoWithLocation();
} on TimeoutException catch (e) {
  // GPS timeout
  print('Location timeout: $e');
} on LocationServiceDisabledException catch (e) {
  // Location services disabled
  print('Enable location services: $e');
} on PermissionDeniedException catch (e) {
  // Permission denied
  print('Permission denied: $e');
} catch (e) {
  // Other errors
  print('Error: $e');
}
```

## Example App

See the [working_proto](working_proto/) directory for a complete working application.

## Requirements

- Flutter SDK 3.0 or higher
- Dart 3.9.2 or higher
- Android SDK 21+ (Android 5.0) or iOS 12.0+
- Device with camera and GPS capabilities

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]

## Support

[Add support information here]
