# CDL Photo GPS SDK - Example App

Complete working example demonstrating how to use the CDL Photo GPS SDK.

## Features Demonstrated

- SDK initialization
- Permission handling
- Camera preview
- Photo capture with GPS location
- Location embedding
- Photo storage
- Error handling
- Camera switching
- Loading states
- Preview screen with location details

## Running the Example

1. Navigate to the example directory:
```bash
cd example
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run on a physical device (required for camera and GPS):
```bash
flutter run
```

Note: This app requires a physical device with camera and GPS. It won't work properly on emulators/simulators.

## Project Structure

```
example/
├── lib/
│   ├── main.dart                    # App entry point
│   └── screens/
│       ├── camera_screen.dart       # Camera capture screen
│       └── preview_screen.dart      # Photo preview screen
├── android/                         # Android configuration
├── ios/                            # iOS configuration
└── pubspec.yaml                    # Dependencies
```

## How It Works

### 1. Initialization (camera_screen.dart)

```dart
final CdlPhotoGpsSDK _sdk = CdlPhotoGpsSDK();

Future<void> _initializeSDK() async {
  // Check and request permissions
  if (!await _sdk.hasPermissions()) {
    await _sdk.requestPermissions();
  }
  
  // Initialize camera
  await _sdk.initialize(preset: ResolutionPreset.high);
}
```

### 2. Capture Photo with Location

```dart
Future<void> _capturePhoto() async {
  try {
    final result = await _sdk.capturePhotoWithLocation(
      locationTimeout: Duration(seconds: 15),
    );
    
    // Navigate to preview
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(result: result),
      ),
    );
  } catch (e) {
    // Handle errors
  }
}
```

### 3. Save Photo (preview_screen.dart)

```dart
Future<void> _savePhoto() async {
  final path = await _sdk.savePhoto(widget.result.photoBytes);
  print('Photo saved to: $path');
}
```

## Testing the SDK

This example app tests all major SDK features:

✅ Permission management
✅ Camera initialization
✅ Photo capture
✅ GPS location retrieval
✅ Address geocoding
✅ Location embedding on photos
✅ Photo storage
✅ Error handling
✅ Camera switching
✅ UI feedback and loading states

## Platform Configuration

### Android

The example includes proper Android configuration in:
- `android/app/src/main/AndroidManifest.xml` - Permissions
- `android/app/build.gradle` - Min SDK 21

### iOS

The example includes proper iOS configuration in:
- `ios/Runner/Info.plist` - Permission descriptions

## Common Issues

**Camera not showing:**
- Ensure you're running on a physical device
- Check camera permissions are granted

**Location timeout:**
- Move to an area with clear sky view
- Check location services are enabled

**Build errors:**
- Run `flutter clean && flutter pub get`
- For iOS: `cd ios && pod install`

## Next Steps

Use this example as a reference for integrating the SDK into your own app. The code is well-commented and demonstrates best practices.
