# Quick Integration Guide

**SDK Repository:** https://github.com/habib2013/photo_gps.git

## 🚀 5-Minute Setup

### 1. Add Dependency
```yaml
# pubspec.yaml
dependencies:
  cdl_photo_gps:
    git:
      url: https://github.com/habib2013/photo_gps.git
      ref: main
```

Run: `flutter pub get`

### 2. Android Permissions
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 3. iOS Permissions
```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture photos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location access to verify visits</string>
```

### 4. Basic Code
```dart
import 'package:cdl_photo_gps/cdl_photo_gps.dart';

// Initialize
final sdk = CdlPhotoGpsSDK(
  config: SDKConfig(outputFormat: OutputFormat.base64),
);
await sdk.initialize();

// Capture
final result = await sdk.capturePhotoWithLocation();

// Check fake GPS
if (result.isMockLocation) {
  print('Fake GPS detected!');
}

// Use result
final base64 = result.photoBase64;
await uploadToAPI(base64);
```

---

## 📋 Complete Minimal Example

```dart
import 'package:flutter/material.dart';
import 'package:cdl_photo_gps/cdl_photo_gps.dart';

class CameraPage extends StatefulWidget {
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final _sdk = CdlPhotoGpsSDK(
    config: SDKConfig(
      outputFormat: OutputFormat.base64,
      detectMockGPS: true,
    ),
  );
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!await _sdk.hasPermissions()) {
      await _sdk.requestPermissions();
    }
    await _sdk.initialize();
    setState(() => _ready = true);
  }

  Future<void> _capture() async {
    final result = await _sdk.capturePhotoWithLocation();
    
    if (result.isMockLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fake GPS detected!')),
      );
      return;
    }

    // Upload to your API
    await _uploadToAPI(result.photoBase64!);
  }

  Future<void> _uploadToAPI(String base64) async {
    // Your upload logic
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return CircularProgressIndicator();

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_sdk.cameraController!),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _capture,
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

## 🎯 Output Format Options

### Bytes (Default)
```dart
config: SDKConfig(outputFormat: OutputFormat.bytes)
// Use: result.photoBytes
```

### Base64 (For APIs)
```dart
config: SDKConfig(outputFormat: OutputFormat.base64)
// Use: result.photoBase64
```

### File (Temporary)
```dart
config: SDKConfig(outputFormat: OutputFormat.file)
// Use: result.filePath
```

---

## 🛡️ Mock GPS Detection

```dart
final result = await sdk.capturePhotoWithLocation();

// Simple check
if (result.isMockLocation) {
  // Reject or warn
}

// With confidence
if (result.locationConfidence < 0.7) {
  // Low confidence, might be fake
}
```

---

## 📤 Upload Examples

### JSON API
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

await http.post(
  Uri.parse('https://api.example.com/photos'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'image': result.photoBase64,
    'latitude': result.locationData.latitude,
    'longitude': result.locationData.longitude,
    'isMockLocation': result.isMockLocation,
  }),
);
```

### Multipart
```dart
var request = http.MultipartRequest(
  'POST',
  Uri.parse('https://api.example.com/photos'),
);

request.files.add(
  http.MultipartFile.fromBytes(
    'photo',
    result.photoBytes!,
    filename: 'photo.jpg',
  ),
);

request.fields['latitude'] = result.locationData.latitude.toString();
request.fields['longitude'] = result.locationData.longitude.toString();

await request.send();
```

---

## ⚠️ Error Handling

```dart
try {
  final result = await sdk.capturePhotoWithLocation();
  await upload(result);
} on TimeoutException {
  showError('GPS timeout');
} on LocationServiceDisabledException {
  showError('Enable location services');
} on PermissionDeniedException {
  showError('Permission required');
} catch (e) {
  showError('Failed: $e');
}
```

---

## ✅ Checklist

### Setup
- [ ] Add dependency
- [ ] Android permissions in AndroidManifest.xml
- [ ] iOS permissions in Info.plist
- [ ] Min SDK: Android 21, iOS 12.0

### Code
- [ ] Import SDK
- [ ] Initialize with config
- [ ] Request permissions
- [ ] Show camera preview
- [ ] Capture photo
- [ ] Check mock GPS
- [ ] Upload to backend

### Test
- [ ] Test on physical device
- [ ] Test permissions
- [ ] Test GPS timeout
- [ ] Test mock GPS detection
- [ ] Test upload

---

## 🎓 Full Documentation

- `EXTERNAL_APP_SETUP.md` - Complete setup guide
- `API_DOCUMENTATION.md` - Full API reference
- `FEATURES.md` - Feature details
- `example/` - Working example app

---

## 🆘 Common Issues

**Camera not showing?**
- Test on physical device (not emulator)
- Check permissions granted

**GPS timeout?**
- Move to open area
- Increase timeout in config

**Build errors?**
- Run `flutter clean && flutter pub get`
- iOS: `cd ios && pod install`

---

That's it! You're ready to integrate. 🎉
