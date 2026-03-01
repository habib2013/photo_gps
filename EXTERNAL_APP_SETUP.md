# External App Integration Guide

Complete guide for integrating CDL Photo GPS SDK into your Flutter app.

---

## 📋 Prerequisites

- Flutter SDK 3.0+
- Dart 3.9.2+
- Android: Min SDK 21 (Android 5.0)
- iOS: Min version 12.0
- Physical device with camera and GPS

---

## 🚀 Step 1: Add SDK to Your Project

### Option A: Local Path (Development)
```yaml
# pubspec.yaml
dependencies:
  cdl_photo_gps:
    path: ../path/to/cdl_photo_gps
```

### Option B: Git Repository
```yaml
# pubspec.yaml
dependencies:
  cdl_photo_gps:
    git:
      url: https://github.com/yourusername/cdl_photo_gps.git
      ref: main
```

### Option C: Pub.dev (When Published)
```yaml
# pubspec.yaml
dependencies:
  cdl_photo_gps: ^0.0.1
```

Then run:
```bash
flutter pub get
```

---

## ⚙️ Step 2: Platform Configuration

### Android Setup

#### 2.1 Update AndroidManifest.xml
File: `android/app/src/main/AndroidManifest.xml`

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
    
    <application
        android:label="Your App Name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Your existing activities -->
        
    </application>
</manifest>
```

#### 2.2 Update build.gradle
File: `android/app/build.gradle`

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Must be at least 21
        targetSdkVersion 34
    }
}
```

### iOS Setup

#### 2.3 Update Info.plist
File: `ios/Runner/Info.plist`

```xml
<dict>
    <!-- Add these permission descriptions -->
    
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to capture photos of clients and locations</string>
    
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need location access to verify visit authenticity and embed GPS coordinates</string>
    
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need photo library access to save captured photos</string>
    
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>We need permission to save photos to your photo library</string>
    
    <!-- Your existing keys -->
    
</dict>
```

#### 2.4 Update Podfile
File: `ios/Podfile`

```ruby
platform :ios, '12.0'  # Must be at least 12.0

# Rest of your Podfile
```

Then run:
```bash
cd ios
pod install
cd ..
```

---

## 💻 Step 3: Basic Implementation

### 3.1 Import the SDK

```dart
import 'package:cdl_photo_gps/cdl_photo_gps.dart';
```

### 3.2 Create a Camera Screen

```dart
import 'package:flutter/material.dart';
import 'package:cdl_photo_gps/cdl_photo_gps.dart';

class MyCameraScreen extends StatefulWidget {
  @override
  State<MyCameraScreen> createState() => _MyCameraScreenState();
}

class _MyCameraScreenState extends State<MyCameraScreen> {
  late final CdlPhotoGpsSDK _sdk;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize SDK with your configuration
    _sdk = CdlPhotoGpsSDK(
      config: const SDKConfig(
        outputFormat: OutputFormat.base64, // or bytes, or file
        detectMockGPS: true,
        gpsTimeout: Duration(seconds: 15),
      ),
    );
    
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
      // Capture photo with GPS
      final result = await _sdk.capturePhotoWithLocation();
      
      // Check for fake GPS
      if (result.isMockLocation) {
        // Show warning or reject
        print('Warning: Mock GPS detected!');
      }
      
      // Use the result
      final base64Image = result.photoBase64!;
      final location = result.locationData;
      
      // Send to your backend
      await _uploadToBackend(base64Image, location);
      
    } catch (e) {
      print('Capture error: $e');
    }
  }

  Future<void> _uploadToBackend(String base64Image, LocationData location) async {
    // Your upload logic here
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_sdk.cameraController!),
          
          // Capture button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _capturePhoto,
                child: Icon(Icons.camera),
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
```

---

## 🎛️ Step 4: Configuration Options

### Choose Output Format

```dart
// Option 1: Bytes (default, memory efficient)
CdlPhotoGpsSDK(
  config: SDKConfig(outputFormat: OutputFormat.bytes),
);
// Use: result.photoBytes

// Option 2: Base64 (easy for API uploads)
CdlPhotoGpsSDK(
  config: SDKConfig(outputFormat: OutputFormat.base64),
);
// Use: result.photoBase64

// Option 3: File (temporary file path)
CdlPhotoGpsSDK(
  config: SDKConfig(outputFormat: OutputFormat.file),
);
// Use: result.filePath
```

### Full Configuration

```dart
CdlPhotoGpsSDK(
  config: SDKConfig(
    outputFormat: OutputFormat.base64,
    detectMockGPS: true,              // Enable fake GPS detection
    gpsTimeout: Duration(seconds: 15), // GPS timeout
    showPermissionRationale: true,     // Show permission explanations
    imageQuality: 85,                  // JPEG quality (0-100)
    maxImageSize: 2 * 1024 * 1024,    // Max 2MB
  ),
);
```

---

## 📤 Step 5: Upload to Your Backend

### Example: Upload with HTTP

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> uploadPhoto(PhotoCaptureResult result) async {
  final response = await http.post(
    Uri.parse('https://your-api.com/photos'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'image': result.photoBase64,
      'latitude': result.locationData.latitude,
      'longitude': result.locationData.longitude,
      'address': result.locationData.address,
      'timestamp': result.captureTimestamp.toIso8601String(),
      'isMockLocation': result.isMockLocation,
      'locationConfidence': result.locationConfidence,
    }),
  );

  if (response.statusCode == 200) {
    print('Upload successful');
  } else {
    throw Exception('Upload failed: ${response.body}');
  }
}
```

### Example: Upload with Multipart

```dart
import 'package:http/http.dart' as http;

Future<void> uploadPhotoMultipart(PhotoCaptureResult result) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('https://your-api.com/photos'),
  );

  // Add image
  request.files.add(
    http.MultipartFile.fromBytes(
      'photo',
      result.photoBytes!,
      filename: 'photo.jpg',
    ),
  );

  // Add metadata
  request.fields['latitude'] = result.locationData.latitude.toString();
  request.fields['longitude'] = result.locationData.longitude.toString();
  request.fields['address'] = result.locationData.address ?? '';
  request.fields['isMockLocation'] = result.isMockLocation.toString();

  var response = await request.send();
  
  if (response.statusCode == 200) {
    print('Upload successful');
  }
}
```

---

## 🛡️ Step 6: Handle Mock GPS

### Basic Check

```dart
final result = await sdk.capturePhotoWithLocation();

if (result.isMockLocation) {
  // Reject the photo
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Fake GPS Detected'),
      content: Text('Please disable mock GPS apps and try again.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
  return;
}

// Proceed with upload
await uploadPhoto(result);
```

### With Confidence Score

```dart
final result = await sdk.capturePhotoWithLocation();

if (result.isMockLocation || result.locationConfidence < 0.7) {
  // Show warning
  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Location Warning'),
      content: Text(
        'Location confidence: ${(result.locationConfidence * 100).toInt()}%\n'
        'This location may not be accurate. Proceed anyway?'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Proceed'),
        ),
      ],
    ),
  );

  if (proceed != true) return;
}

await uploadPhoto(result);
```

---

## 🔧 Step 7: Error Handling

```dart
Future<void> captureWithErrorHandling() async {
  try {
    final result = await sdk.capturePhotoWithLocation();
    await uploadPhoto(result);
    
  } on TimeoutException catch (e) {
    // GPS timeout
    showError('GPS timeout. Please try again in an open area.');
    
  } on LocationServiceDisabledException catch (e) {
    // Location services disabled
    showError('Please enable location services in settings.');
    
  } on PermissionDeniedException catch (e) {
    // Permission denied
    showError('Camera or location permission is required.');
    
  } catch (e) {
    // Other errors
    showError('Failed to capture photo: $e');
  }
}

void showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

---

## 📱 Step 8: Test on Real Device

```bash
# Connect your physical device
flutter devices

# Run the app
flutter run --release
```

**Important:** The SDK requires actual hardware (camera and GPS). It won't work properly on emulators/simulators.

---

## ✅ Checklist for External Apps

### Setup
- [ ] Add SDK dependency to pubspec.yaml
- [ ] Run `flutter pub get`
- [ ] Update AndroidManifest.xml with permissions
- [ ] Update build.gradle with minSdkVersion 21
- [ ] Update Info.plist with permission descriptions
- [ ] Update Podfile with iOS 12.0
- [ ] Run `pod install` (iOS)

### Implementation
- [ ] Import SDK in your Dart file
- [ ] Initialize SDK with configuration
- [ ] Request permissions
- [ ] Initialize camera
- [ ] Show camera preview
- [ ] Capture photo with location
- [ ] Handle mock GPS detection
- [ ] Upload to your backend
- [ ] Dispose SDK when done

### Testing
- [ ] Test on physical Android device
- [ ] Test on physical iOS device
- [ ] Test permission flows
- [ ] Test GPS timeout scenarios
- [ ] Test mock GPS detection
- [ ] Test offline scenarios
- [ ] Test upload to backend

---

## 🎯 Common Use Cases

### Use Case 1: Sales Agent Visit Verification

```dart
// Configure for base64 upload
final sdk = CdlPhotoGpsSDK(
  config: SDKConfig(
    outputFormat: OutputFormat.base64,
    detectMockGPS: true, // Prevent cheating
  ),
);

// Capture
final result = await sdk.capturePhotoWithLocation();

// Reject if fake GPS
if (result.isMockLocation) {
  throw Exception('Fake GPS detected');
}

// Upload to backend
await http.post(
  Uri.parse('https://api.company.com/visits'),
  body: jsonEncode({
    'clientId': clientId,
    'agentId': agentId,
    'photo': result.photoBase64,
    'latitude': result.locationData.latitude,
    'longitude': result.locationData.longitude,
    'timestamp': result.captureTimestamp.toIso8601String(),
  }),
);
```

### Use Case 2: Delivery Proof

```dart
// Configure for file storage
final sdk = CdlPhotoGpsSDK(
  config: SDKConfig(
    outputFormat: OutputFormat.file,
    detectMockGPS: true,
  ),
);

// Capture
final result = await sdk.capturePhotoWithLocation();

// Store locally first
await saveToLocalDatabase(
  orderId: orderId,
  photoPath: result.filePath!,
  location: result.locationData,
);

// Upload when online
await uploadWhenOnline();
```

### Use Case 3: Field Inspection

```dart
// Configure for bytes (memory efficient)
final sdk = CdlPhotoGpsSDK(
  config: SDKConfig(
    outputFormat: OutputFormat.bytes,
    imageQuality: 70, // Lower quality for faster upload
  ),
);

// Capture multiple photos
final photos = <PhotoCaptureResult>[];
for (int i = 0; i < 5; i++) {
  final result = await sdk.capturePhotoWithLocation();
  photos.add(result);
}

// Batch upload
await uploadBatch(photos);
```

---

## 🆘 Troubleshooting

### Camera not showing
- Ensure you're testing on a physical device
- Check camera permissions are granted
- Verify no other app is using the camera

### GPS timeout
- Move to an area with clear sky view
- Increase timeout: `gpsTimeout: Duration(seconds: 30)`
- Check location services are enabled

### Permission denied
- Check AndroidManifest.xml has all permissions
- Check Info.plist has all descriptions
- Guide user to app settings

### Build errors
- Run `flutter clean && flutter pub get`
- For iOS: `cd ios && pod install`
- Check minimum SDK versions

---

## 📞 Support

For issues or questions:
1. Check the example app in `example/` directory
2. Review `API_DOCUMENTATION.md`
3. Check `FEATURES.md` for usage examples

---

## 🎉 You're Ready!

Your app can now:
- ✅ Capture photos with GPS
- ✅ Detect fake GPS
- ✅ Get location confidence scores
- ✅ Output in multiple formats
- ✅ Upload to your backend

Start with the basic implementation and add features as needed!
