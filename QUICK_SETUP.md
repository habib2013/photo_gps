# Quick Setup for External Apps

**SDK Repository:** https://github.com/habib2013/photo_gps.git

## What You Need to Do

### 1. Add SDK to pubspec.yaml

```yaml
dependencies:
  cdl_photo_gps:
    git:
      url: https://github.com/habib2013/photo_gps.git
      ref: main
```

Run: `flutter pub get`

---

### 2. Android Permissions (AndroidManifest.xml)

Add inside `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />

<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

Update `android/app/build.gradle`:
```gradle
minSdkVersion 21
```

---

### 3. iOS Permissions (Info.plist)

Add inside `<dict>` tag:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture photos</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location access to verify visit authenticity</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to save photos</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need permission to save photos</string>
```

Update `ios/Podfile`:
```ruby
platform :ios, '12.0'
```

Run: `cd ios && pod install && cd ..`

---

### 4. Basic Usage

```dart
import 'package:cdl_photo_gps/cdl_photo_gps.dart';

// Initialize SDK
final sdk = CdlPhotoGpsSDK(
  config: const SDKConfig(
    outputFormat: OutputFormat.base64,  // or bytes, or file
    detectMockGPS: true,                // Detect fake GPS
    gpsTimeout: Duration(seconds: 15),
  ),
);

// Request permissions
if (!await sdk.hasPermissions()) {
  await sdk.requestPermissions();
}

// Initialize camera
await sdk.initialize();

// Show camera preview
CameraPreview(sdk.cameraController!)

// Capture photo with GPS
final result = await sdk.capturePhotoWithLocation();

// Check for fake GPS
if (result.isMockLocation) {
  print('Warning: Fake GPS detected!');
  print('Confidence: ${result.locationConfidence}');
}

// Get data
final image = result.photoBase64;           // Base64 string
final lat = result.locationData.latitude;   // GPS latitude
final lng = result.locationData.longitude;  // GPS longitude
final address = result.locationData.address; // Human-readable address
final timestamp = result.captureTimestamp;  // Local time (not UTC)

// Upload to your backend
await uploadToYourAPI(image, lat, lng, address, timestamp);

// Cleanup
await sdk.dispose();
```

---

### 5. Upload to Your Backend

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> uploadToYourAPI(
  String image,
  double lat,
  double lng,
  String? address,
  DateTime timestamp,
) async {
  final response = await http.post(
    Uri.parse('https://your-api.com/photos'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'image': image,
      'latitude': lat,
      'longitude': lng,
      'address': address,
      'timestamp': timestamp.toIso8601String(), // Local time
    }),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Upload failed');
  }
}
```

---

## Important Notes

### Timestamps are in Local Time
- The SDK now returns timestamps in the user's local timezone (not UTC)
- `result.captureTimestamp` is local time
- `result.locationData.timestamp` is local time
- Photo overlay shows timezone (e.g., "Monday, 01/03/2026 14:30 WAT")

### Output Formats
- `OutputFormat.bytes` - Returns `Uint8List` (memory efficient)
- `OutputFormat.base64` - Returns base64 string (easy for APIs)
- `OutputFormat.file` - Returns file path (temporary file)

### Mock GPS Detection
- `result.isMockLocation` - Boolean flag (true if fake GPS detected)
- `result.locationConfidence` - Score from 0.0 to 1.0
  - 1.0 = High confidence (real GPS, good accuracy)
  - 0.8 = Good confidence (real GPS, medium accuracy)
  - 0.6 = Medium confidence (real GPS, poor accuracy)
  - 0.2 = Low confidence (fake GPS detected)

### Error Handling
```dart
try {
  final result = await sdk.capturePhotoWithLocation();
} on TimeoutException {
  // GPS timeout - user might be indoors
} on LocationServiceDisabledException {
  // Location services disabled
} on PermissionDeniedException {
  // Permissions not granted
} catch (e) {
  // Other errors
}
```

---

## Testing

**Must test on physical device** (camera and GPS required)

```bash
flutter run --release -d <device-id>
```

---

## Full Documentation

For complete examples and advanced usage, see:
- `EXTERNAL_APP_SETUP.md` - Complete integration guide
- `API_DOCUMENTATION.md` - Full API reference
- `TROUBLESHOOTING.md` - Common issues and solutions
- `example_new/` - Working example app

---

## That's It!

You now have:
- ✅ Photos with embedded GPS location
- ✅ Fake GPS detection
- ✅ Local timezone timestamps
- ✅ Multiple output formats
- ✅ Ready to upload to your backend
