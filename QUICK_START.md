# Quick Start Guide

## Installation

Add to your `pubspec.yaml`:
```yaml
dependencies:
  cdl_photo_gps:
    path: ../cdl_photo_gps  # or your path
```

## Basic Usage

```dart
import 'package:cdl_photo_gps/cdl_photo_gps.dart';

// 1. Create SDK instance
final sdk = CdlPhotoGpsSDK();

// 2. Initialize
await sdk.initialize();

// 3. Request permissions
if (!await sdk.hasPermissions()) {
  await sdk.requestPermissions();
}

// 4. Capture photo with GPS
final result = await sdk.capturePhotoWithLocation();

// 5. Save photo
final path = await sdk.savePhoto(result.photoBytes);

// 6. Access location data
print('Coordinates: ${result.locationData.formattedCoordinates}');
print('Address: ${result.locationData.address}');

// 7. Cleanup
await sdk.dispose();
```

## Camera Preview

```dart
// In your widget
CameraPreview(sdk.cameraController!)
```

## Error Handling

```dart
try {
  final result = await sdk.capturePhotoWithLocation();
} on TimeoutException {
  // GPS timeout
} on LocationServiceDisabledException {
  // Location disabled
} on PermissionDeniedException {
  // Permission denied
}
```

## Run Example

```bash
cd example
flutter run
```

## Platform Setup

### Android
- Min SDK: 21
- Add permissions to AndroidManifest.xml (see example)

### iOS  
- Min version: 12.0
- Add permission descriptions to Info.plist (see example)

## Documentation

- Full API: `API_DOCUMENTATION.md`
- Integration: `INTEGRATION_GUIDE.md`
- Example: `example/`
