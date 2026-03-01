# CDL Photo GPS SDK - Features

## ✅ Implemented Features

### 1. Mock GPS Detection
- Detects fake GPS apps automatically
- Provides confidence score (0.0 - 1.0)
- Warns users when mock location detected
- Configurable via `SDKConfig.detectMockGPS`

### 2. Flexible Output Formats
- **Bytes** (Uint8List) - Default, memory efficient
- **Base64** (String) - Easy for API uploads
- **File** (String path) - Temporary file storage

Configure via `SDKConfig.outputFormat`

### 3. Enhanced Result Model
```dart
PhotoCaptureResult {
  photoBytes?       // Uint8List
  photoBase64?      // String
  filePath?         // String
  locationData      // GPS + address
  isMockLocation    // bool
  locationConfidence // 0.0-1.0
  captureTimestamp  // DateTime
  photoSize         // int (bytes)
}
```

### 4. Better UX
- Permission rationale dialogs (explains why permissions needed)
- Loading indicators during GPS wait
- Clear error messages with retry options
- Mock GPS warnings with confidence display

### 5. Configurable SDK
```dart
SDKConfig(
  outputFormat: OutputFormat.base64,
  detectMockGPS: true,
  gpsTimeout: Duration(seconds: 15),
  showPermissionRationale: true,
  showLoadingIndicators: true,
  maxImageSize: 2 * 1024 * 1024,
  imageQuality: 85,
)
```

## 📦 Usage Examples

### Basic Usage (Bytes)
```dart
final sdk = CdlPhotoGpsSDK();
await sdk.initialize();

final result = await sdk.capturePhotoWithLocation();

// Check for fake GPS
if (result.isMockLocation) {
  print('Warning: Mock GPS detected!');
  print('Confidence: ${result.locationConfidence}');
}

// Use photo bytes
final bytes = result.photoBytes;
```

### Base64 Output (API Upload)
```dart
final sdk = CdlPhotoGpsSDK(
  config: SDKConfig(
    outputFormat: OutputFormat.base64,
  ),
);

final result = await sdk.capturePhotoWithLocation();

// Upload to API
await uploadToServer(
  base64Image: result.photoBase64!,
  latitude: result.locationData.latitude,
  longitude: result.locationData.longitude,
  isMockLocation: result.isMockLocation,
);
```

### File Output (Temporary Storage)
```dart
final sdk = CdlPhotoGpsSDK(
  config: SDKConfig(
    outputFormat: OutputFormat.file,
  ),
);

final result = await sdk.capturePhotoWithLocation();

// Use file path
final path = result.filePath!;
print('Photo saved to: $path');

// Clean up when done
await FormatConverter.deleteFile(path);
```

### Custom Configuration
```dart
final sdk = CdlPhotoGpsSDK(
  config: SDKConfig(
    outputFormat: OutputFormat.base64,
    detectMockGPS: true,
    gpsTimeout: Duration(seconds: 30), // Longer timeout
    imageQuality: 70, // Lower quality for smaller files
  ),
);
```

## 🎯 Key Improvements

### Security
- ✅ Mock GPS detection prevents location spoofing
- ✅ Confidence scoring helps identify suspicious locations
- ✅ Timestamp validation (capture time recorded)

### UX
- ✅ Permission education before requesting
- ✅ Loading states during GPS acquisition
- ✅ Clear error messages with actionable steps
- ✅ Retry functionality on failures
- ✅ Mock GPS warnings with user choice

### Flexibility
- ✅ Multiple output formats (bytes/base64/file)
- ✅ Configurable timeouts and quality
- ✅ Optional features (mock detection, rationale dialogs)

### Performance
- ✅ Efficient format conversion
- ✅ Configurable image quality
- ✅ Size tracking and formatting

## 🚀 What's NOT Included (Intentionally)

### Removed Complexity
- ❌ Upload queue (host app handles this)
- ❌ Sync engine (host app handles this)
- ❌ Background processing (not needed for single captures)
- ❌ Encryption (host app can add if needed)
- ❌ Device attestation (overkill for sales use case)
- ❌ Digital signatures (unnecessary complexity)

### Why?
The SDK is focused on being a **camera widget** that:
1. Captures photos
2. Gets GPS location
3. Detects fake GPS
4. Returns result to host app

The host app decides what to do with the result (upload, save, display, etc.)

## 📊 Comparison

### Before
```dart
final sdk = CdlPhotoGpsSDK();
final result = await sdk.capturePhotoWithLocation();
final bytes = result.photoBytes; // Only bytes
// No mock GPS detection
// No confidence scoring
// No output format options
```

### After
```dart
final sdk = CdlPhotoGpsSDK(
  config: SDKConfig(
    outputFormat: OutputFormat.base64,
    detectMockGPS: true,
  ),
);

final result = await sdk.capturePhotoWithLocation();

// Multiple formats available
final base64 = result.photoBase64;
final bytes = result.photoBytes;
final path = result.filePath;

// Security features
if (result.isMockLocation) {
  print('Fake GPS detected!');
  print('Confidence: ${result.locationConfidence}');
}

// Metadata
print('Size: ${FormatConverter.formatSize(result.photoSize)}');
print('Captured: ${result.captureTimestamp}');
```

## 🎓 Example App Features

The example app demonstrates:
1. SDK configuration
2. Permission rationale dialogs
3. Mock GPS detection and warnings
4. Loading states
5. Error handling with retry
6. Preview with location details
7. Confidence scoring display
8. Multiple output format support

Run the example:
```bash
cd example
flutter run
```

## 📝 Notes

- Mock GPS detection works best on Android (uses system flag)
- iOS detection is limited (checks for simulator)
- Confidence scoring is basic but effective
- Host app should validate location server-side for critical use cases
