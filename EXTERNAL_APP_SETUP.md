# External App Integration Guide

Complete guide for integrating CDL Photo GPS SDK into your Flutter app.

**SDK Repository:** https://github.com/habib2013/photo_gps.git

---

## 📋 Prerequisites

- Flutter SDK 3.0+
- Dart 3.9.2+
- Android: Min SDK 21 (Android 5.0)
- iOS: Min version 12.0
- Physical device with camera and GPS

---

## 🚀 Step 1: Add SDK to Your Project

### Add to pubspec.yaml

```yaml
# pubspec.yaml
dependencies:
  cdl_photo_gps:
    git:
      url: https://github.com/habib2013/photo_gps.git
      ref: main
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

Add these permissions inside the `<manifest>` tag (before `<application>`):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Required permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    
    <!-- Required features -->
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

Ensure minimum SDK version is at least 21:

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

Add these permission descriptions inside the `<dict>` tag:

```xml
<dict>
    <!-- Required permission descriptions -->
    
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

Ensure minimum iOS version is at least 12.0:

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

Create a new file: `lib/screens/camera_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cdl_photo_gps/cdl_photo_gps.dart';

class MyCameraScreen extends StatefulWidget {
  const MyCameraScreen({super.key});

  @override
  State<MyCameraScreen> createState() => _MyCameraScreenState();
}

class _MyCameraScreenState extends State<MyCameraScreen> {
  late final CdlPhotoGpsSDK _sdk;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize SDK with your configuration
    _sdk = CdlPhotoGpsSDK(
      config: const SDKConfig(
        outputFormat: OutputFormat.base64, // Choose: bytes, base64, or file
        detectMockGPS: true,                // Enable fake GPS detection
        gpsTimeout: Duration(seconds: 15),  // GPS timeout
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
          setState(() {
            _isInitialized = false;
          });
          _showError('Camera and location permissions are required');
          return;
        }
      }

      // Initialize camera
      await _sdk.initialize();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _showError('Initialization error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Capture photo with GPS
      final result = await _sdk.capturePhotoWithLocation();
      
      // Check for fake GPS
      if (result.isMockLocation) {
        final proceed = await _showMockGPSWarning(result.locationConfidence);
        if (!proceed) {
          setState(() {
            _isCapturing = false;
          });
          return;
        }
      }
      
      // Use the result based on your output format
      final base64Image = result.photoBase64!; // if using base64
      // final bytes = result.photoBytes!;      // if using bytes
      // final path = result.filePath!;         // if using file
      
      final location = result.locationData;
      
      // Send to your backend
      await _uploadToBackend(
        image: base64Image,
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        isMockLocation: result.isMockLocation,
        confidence: result.locationConfidence,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } on TimeoutException catch (e) {
      _showError('GPS timeout: ${e.toString()}');
    } on LocationServiceDisabledException catch (e) {
      _showError('Location services disabled: ${e.toString()}');
    } on PermissionDeniedException catch (e) {
      _showError('Permission denied: ${e.toString()}');
    } catch (e) {
      _showError('Capture error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _uploadToBackend({
    required String image,
    required double latitude,
    required double longitude,
    String? address,
    required bool isMockLocation,
    required double confidence,
  }) async {
    // TODO: Replace with your actual API endpoint
    // Example:
    // await http.post(
    //   Uri.parse('https://your-api.com/photos'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'image': image,
    //     'latitude': latitude,
    //     'longitude': longitude,
    //     'address': address,
    //     'isMockLocation': isMockLocation,
    //     'locationConfidence': confidence,
    //   }),
    // );
    
    print('Uploading to backend...');
    await Future.delayed(const Duration(seconds: 1)); // Simulate upload
    print('Upload complete!');
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
            const Text('Do you want to proceed anyway?'),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'GPS Photo Capture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    border: Border.all(color: Colors.white, width: 4),
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
```

### 3.3 Add to Your App

In your main app file or navigation:

```dart
// Navigate to camera screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MyCameraScreen(),
  ),
);
```

---

## 🎛️ Step 4: Configuration Options

### Choose Output Format

```dart
// Option 1: Bytes (default, memory efficient)
CdlPhotoGpsSDK(
  config: const SDKConfig(outputFormat: OutputFormat.bytes),
);
// Access: result.photoBytes

// Option 2: Base64 (easy for API uploads)
CdlPhotoGpsSDK(
  config: const SDKConfig(outputFormat: OutputFormat.base64),
);
// Access: result.photoBase64

// Option 3: File (temporary file path)
CdlPhotoGpsSDK(
  config: const SDKConfig(outputFormat: OutputFormat.file),
);
// Access: result.filePath
```

### Full Configuration Options

```dart
CdlPhotoGpsSDK(
  config: const SDKConfig(
    outputFormat: OutputFormat.base64,      // Output format
    detectMockGPS: true,                    // Enable fake GPS detection
    gpsTimeout: Duration(seconds: 15),      // GPS timeout
    showPermissionRationale: true,          // Show permission explanations
    imageQuality: 85,                       // JPEG quality (0-100)
    maxImageSize: 2 * 1024 * 1024,         // Max 2MB
  ),
);
```

---

## 📤 Step 5: Upload to Your Backend

### Example: JSON API Upload

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> uploadPhoto(PhotoCaptureResult result) async {
  final response = await http.post(
    Uri.parse('https://your-api.com/api/photos'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_TOKEN',
    },
    body: jsonEncode({
      'image': result.photoBase64,
      'latitude': result.locationData.latitude,
      'longitude': result.locationData.longitude,
      'address': result.locationData.address,
      'timestamp': result.captureTimestamp.toIso8601String(),
      'isMockLocation': result.isMockLocation,
      'locationConfidence': result.locationConfidence,
      'accuracy': result.locationData.accuracy,
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('Upload successful');
  } else {
    throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
  }
}
```

### Example: Multipart Upload

```dart
import 'package:http/http.dart' as http;

Future<void> uploadPhotoMultipart(PhotoCaptureResult result) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('https://your-api.com/api/photos'),
  );

  // Add authorization header
  request.headers['Authorization'] = 'Bearer YOUR_TOKEN';

  // Add image file
  request.files.add(
    http.MultipartFile.fromBytes(
      'photo',
      result.photoBytes!,
      filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
    ),
  );

  // Add metadata fields
  request.fields['latitude'] = result.locationData.latitude.toString();
  request.fields['longitude'] = result.locationData.longitude.toString();
  request.fields['address'] = result.locationData.address ?? '';
  request.fields['timestamp'] = result.captureTimestamp.toIso8601String();
  request.fields['isMockLocation'] = result.isMockLocation.toString();
  request.fields['locationConfidence'] = result.locationConfidence.toString();

  var response = await request.send();
  
  if (response.statusCode == 200 || response.statusCode == 201) {
    print('Upload successful');
  } else {
    throw Exception('Upload failed: ${response.statusCode}');
  }
}
```

---

## 🛡️ Step 6: Handle Mock GPS Detection

### Basic Check (Reject Fake GPS)

```dart
final result = await sdk.capturePhotoWithLocation();

if (result.isMockLocation) {
  // Reject the photo
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Fake GPS Detected'),
      content: const Text(
        'Please disable mock GPS apps and try again. '
        'Location verification is required for authenticity.'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  return; // Don't proceed with upload
}

// Proceed with upload
await uploadPhoto(result);
```

### With Confidence Score (Warn User)

```dart
final result = await sdk.capturePhotoWithLocation();

// Check both mock flag and confidence score
if (result.isMockLocation || result.locationConfidence < 0.7) {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Location Warning'),
      content: Text(
        'Location confidence: ${(result.locationConfidence * 100).toInt()}%\n\n'
        '${result.isMockLocation ? "Mock GPS detected. " : ""}'
        'This location may not be accurate. Proceed anyway?'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Proceed'),
        ),
      ],
    ),
  );

  if (proceed != true) return; // User cancelled
}

// Upload with warning flag
await uploadPhoto(result);
```

---

## 🔧 Step 7: Error Handling

### Complete Error Handling Example

```dart
Future<void> captureWithErrorHandling() async {
  try {
    final result = await sdk.capturePhotoWithLocation();
    
    // Check mock GPS
    if (result.isMockLocation) {
      throw Exception('Mock GPS detected');
    }
    
    // Upload
    await uploadPhoto(result);
    
    // Success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo uploaded successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
  } on TimeoutException catch (e) {
    // GPS timeout
    _showErrorDialog(
      'GPS Timeout',
      'Unable to get GPS location. Please try again in an open area.',
      canRetry: true,
    );
    
  } on LocationServiceDisabledException catch (e) {
    // Location services disabled
    _showErrorDialog(
      'Location Services Disabled',
      'Please enable location services in your device settings.',
      showSettings: true,
    );
    
  } on PermissionDeniedException catch (e) {
    // Permission denied
    _showErrorDialog(
      'Permission Required',
      'Camera and location permissions are required to continue.',
      showSettings: true,
    );
    
  } catch (e) {
    // Other errors
    _showErrorDialog(
      'Error',
      'Failed to capture photo: $e',
      canRetry: true,
    );
  }
}

void _showErrorDialog(
  String title,
  String message, {
  bool canRetry = false,
  bool showSettings = false,
}) {
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
              captureWithErrorHandling(); // Retry
            },
            child: const Text('Retry'),
          ),
        if (showSettings)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              sdk.openAppSettings(); // Open settings
            },
            child: const Text('Open Settings'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(canRetry || showSettings ? 'Cancel' : 'OK'),
        ),
      ],
    ),
  );
}
```

---

## 📱 Step 8: Test on Real Device

**Important:** The SDK requires actual hardware (camera and GPS). It won't work properly on emulators/simulators.

```bash
# Connect your physical device
flutter devices

# Run the app
flutter run --release
```

### Testing Checklist

- [ ] Test on physical Android device
- [ ] Test on physical iOS device
- [ ] Test permission request flow
- [ ] Test GPS timeout (go indoors)
- [ ] Test mock GPS detection (use fake GPS app)
- [ ] Test offline scenario
- [ ] Test upload to your backend
- [ ] Test error handling

---

## ✅ Integration Checklist

### Setup
- [ ] Add SDK dependency from GitHub to pubspec.yaml
- [ ] Run `flutter pub get`
- [ ] Update AndroidManifest.xml with permissions
- [ ] Update build.gradle with minSdkVersion 21
- [ ] Update Info.plist with permission descriptions
- [ ] Update Podfile with iOS 12.0
- [ ] Run `pod install` (iOS only)

### Implementation
- [ ] Import SDK in your Dart file
- [ ] Create camera screen widget
- [ ] Initialize SDK with configuration
- [ ] Request permissions
- [ ] Show camera preview
- [ ] Implement capture button
- [ ] Handle mock GPS detection
- [ ] Implement upload to backend
- [ ] Add error handling
- [ ] Dispose SDK when done

### Testing
- [ ] Test on physical devices
- [ ] Test all error scenarios
- [ ] Test mock GPS detection
- [ ] Verify backend upload works

---

## 🎯 Common Use Cases

### Use Case 1: Sales Agent Visit Verification

```dart
final sdk = CdlPhotoGpsSDK(
  config: const SDKConfig(
    outputFormat: OutputFormat.base64,
    detectMockGPS: true, // Prevent cheating
  ),
);

final result = await sdk.capturePhotoWithLocation();

// Reject if fake GPS
if (result.isMockLocation) {
  throw Exception('Fake GPS detected - visit not verified');
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
    'address': result.locationData.address,
    'timestamp': result.captureTimestamp.toIso8601String(),
  }),
);
```

### Use Case 2: Delivery Proof of Delivery

```dart
final sdk = CdlPhotoGpsSDK(
  config: const SDKConfig(
    outputFormat: OutputFormat.bytes,
    detectMockGPS: true,
  ),
);

final result = await sdk.capturePhotoWithLocation();

// Store locally first (offline support)
await localDatabase.insert({
  'orderId': orderId,
  'photoBytes': result.photoBytes,
  'latitude': result.locationData.latitude,
  'longitude': result.locationData.longitude,
  'timestamp': result.captureTimestamp,
  'synced': false,
});

// Upload when online
if (await isOnline()) {
  await uploadToServer(result);
}
```

---

## 🆘 Troubleshooting

### Camera not showing
**Problem:** Black screen or no camera preview
**Solution:**
- Ensure you're testing on a physical device (not emulator)
- Check camera permissions are granted in device settings
- Verify no other app is using the camera
- Try restarting the app

### GPS timeout
**Problem:** "GPS timeout" error
**Solution:**
- Move to an area with clear sky view
- Increase timeout: `gpsTimeout: Duration(seconds: 30)`
- Check location services are enabled in device settings
- Try outdoors instead of indoors

### Permission denied
**Problem:** Permissions not granted
**Solution:**
- Check AndroidManifest.xml has all required permissions
- Check Info.plist has all permission descriptions
- Guide user to app settings: `sdk.openAppSettings()`
- Explain why permissions are needed before requesting

### Build errors
**Problem:** Compilation errors
**Solution:**
- Run `flutter clean && flutter pub get`
- For iOS: `cd ios && pod install && cd ..`
- Check minimum SDK versions (Android 21, iOS 12.0)
- Update Flutter: `flutter upgrade`

### Mock GPS not detected
**Problem:** Fake GPS not being caught
**Solution:**
- Ensure `detectMockGPS: true` in config
- Note: Detection works better on Android than iOS
- Consider server-side validation as backup
- Check `result.locationConfidence` score

---

## 📞 Support & Resources

### Documentation
- **API Reference:** See `API_DOCUMENTATION.md` in the repo
- **Features Guide:** See `FEATURES.md` in the repo
- **Example App:** Check `example/` directory in the repo

### Repository
- **GitHub:** https://github.com/habib2013/photo_gps.git
- **Issues:** Report bugs or request features on GitHub Issues

### Quick Links
- Example implementation: `example/lib/screens/camera_screen.dart`
- Configuration options: `lib/src/models/sdk_config.dart`
- API documentation: `API_DOCUMENTATION.md`

---

## 🎉 You're Ready!

Your app can now:
- ✅ Capture photos with embedded GPS location
- ✅ Detect fake GPS and prevent cheating
- ✅ Get location confidence scores
- ✅ Output in multiple formats (bytes/base64/file)
- ✅ Upload to your backend with metadata
- ✅ Handle errors gracefully

**Next Steps:**
1. Copy the camera screen code above
2. Replace the `_uploadToBackend` method with your API
3. Test on a physical device
4. Deploy to your users!

Good luck! 🚀

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
