# CDL Photo GPS SDK - API Documentation

Complete API reference for the CDL Photo GPS SDK.

## Table of Contents

- [Core SDK](#core-sdk)
  - [CdlPhotoGpsSDK](#cdlphotogpssdk)
- [Models](#models)
  - [LocationData](#locationdata)
  - [PhotoCaptureResult](#photocaptureresult)
- [Services](#services)
  - [CameraModule](#cameramodule)
  - [LocationService](#locationservice)
  - [ImageProcessor](#imageprocessor)
  - [PermissionManager](#permissionmanager)
  - [StorageManager](#storagemanager)
- [Enums](#enums)
  - [PermissionStatus](#permissionstatus)
- [Exceptions](#exceptions)

---

## Core SDK

### CdlPhotoGpsSDK

Main SDK class providing a high-level interface for GPS photo capture.

#### Properties

##### `cameraController`
```dart
CameraController? get cameraController
```
Gets the camera controller for use in preview widgets.

##### `isCameraInitialized`
```dart
bool get isCameraInitialized
```
Checks if the camera is initialized and ready to use.

##### `hasMultipleCameras`
```dart
bool get hasMultipleCameras
```
Checks if the device has multiple cameras (front and rear).

#### Methods

##### `initialize`
```dart
Future<void> initialize({ResolutionPreset preset = ResolutionPreset.high})
```
Initialize the SDK and camera. Must be called before using camera features.

**Parameters:**
- `preset`: Camera resolution preset (default: `ResolutionPreset.high`)

**Throws:** `Exception` if initialization fails

**Example:**
```dart
await sdk.initialize(preset: ResolutionPreset.high);
```

##### `hasPermissions`
```dart
Future<bool> hasPermissions()
```
Check if all required permissions (camera and location) are granted.

**Returns:** `true` if both permissions are granted

**Example:**
```dart
if (!await sdk.hasPermissions()) {
  await sdk.requestPermissions();
}
```

##### `requestPermissions`
```dart
Future<bool> requestPermissions()
```
Request camera and location permissions from the user.

**Returns:** `true` if both permissions are granted

**Example:**
```dart
final granted = await sdk.requestPermissions();
```

##### `openAppSettings`
```dart
Future<void> openAppSettings()
```
Open device app settings for manual permission management.

**Example:**
```dart
await sdk.openAppSettings();
```

##### `capturePhotoWithLocation`
```dart
Future<PhotoCaptureResult> capturePhotoWithLocation({
  Duration locationTimeout = const Duration(seconds: 15),
})
```
Capture a photo with embedded GPS location. This is the main SDK method.

**Parameters:**
- `locationTimeout`: Timeout for GPS retrieval (default: 15 seconds)

**Returns:** `PhotoCaptureResult` with embedded photo and location data

**Throws:**
- `TimeoutException` - GPS retrieval timed out
- `LocationServiceDisabledException` - Location services disabled
- `PermissionDeniedException` - Permission denied
- `Exception` - Other capture/processing errors

**Example:**
```dart
final result = await sdk.capturePhotoWithLocation(
  locationTimeout: Duration(seconds: 15),
);
```

##### `capturePhoto`
```dart
Future<Uint8List> capturePhoto()
```
Capture a photo without location (camera only).

**Returns:** Photo bytes as `Uint8List`

**Example:**
```dart
final photoBytes = await sdk.capturePhoto();
```

##### `getCurrentLocation`
```dart
Future<LocationData> getCurrentLocation({
  Duration timeout = const Duration(seconds: 15),
})
```
Get current GPS location.

**Parameters:**
- `timeout`: Timeout for GPS retrieval (default: 15 seconds)

**Returns:** `LocationData` with coordinates and optional address

**Example:**
```dart
final location = await sdk.getCurrentLocation();
```

##### `embedLocation`
```dart
Future<Uint8List> embedLocation({
  required Uint8List photoBytes,
  required LocationData locationData,
})
```
Embed location information on an existing photo.

**Parameters:**
- `photoBytes`: Raw photo data
- `locationData`: Location information to embed

**Returns:** Processed photo bytes with embedded location

**Example:**
```dart
final embedded = await sdk.embedLocation(
  photoBytes: photoBytes,
  locationData: location,
);
```

##### `savePhoto`
```dart
Future<String> savePhoto(Uint8List photoBytes, {String? filename})
```
Save a photo to device storage.

**Parameters:**
- `photoBytes`: Photo data to save
- `filename`: Optional custom filename

**Returns:** Full path to saved file

**Example:**
```dart
final path = await sdk.savePhoto(result.photoBytes);
```

##### `switchCamera`
```dart
Future<void> switchCamera()
```
Switch between front and rear cameras.

**Throws:** `Exception` if only one camera is available

**Example:**
```dart
await sdk.switchCamera();
```

##### `isLocationServiceEnabled`
```dart
Future<bool> isLocationServiceEnabled()
```
Check if location services are enabled on the device.

**Returns:** `true` if location services are enabled

##### `getPhotosDirectory`
```dart
Future<String> getPhotosDirectory()
```
Get the directory where photos are stored.

**Returns:** Directory path as string

##### `dispose`
```dart
Future<void> dispose()
```
Dispose SDK resources. Must be called when done using the SDK.

**Example:**
```dart
@override
void dispose() {
  sdk.dispose();
  super.dispose();
}
```

---

## Models

### LocationData

Represents GPS location information with timestamp and optional address.

#### Constructor
```dart
LocationData({
  required double latitude,
  required double longitude,
  required double accuracy,
  required DateTime timestamp,
  String? address,
})
```

#### Properties

- `latitude` (double): Latitude in degrees (-90 to 90)
- `longitude` (double): Longitude in degrees (-180 to 180)
- `accuracy` (double): GPS accuracy in meters
- `timestamp` (DateTime): When the location was captured
- `address` (String?): Human-readable address (null if unavailable)

#### Getters

##### `formattedCoordinates`
```dart
String get formattedCoordinates
```
Returns coordinates formatted as "latitude, longitude" with 6 decimal places.

**Example:** `"37.774900, -122.419400"`

##### `formattedTimestamp`
```dart
String get formattedTimestamp
```
Returns timestamp formatted as "YYYY-MM-DD HH:MM:SS".

**Example:** `"2024-01-15 14:30:45"`

#### Methods

##### `getOverlayText`
```dart
String getOverlayText()
```
Returns formatted text for image overlay including location name, address, coordinates, and timestamp.

**Example:**
```dart
final overlayText = location.getOverlayText();
// Output:
// San Francisco, CA, USA
// 123 Main St, San Francisco, CA, USA
// Lat 37.77490° Long -122.419400°
// Monday, 15/01/2024 14:30 PST
```

---

### PhotoCaptureResult

Represents the result of a photo capture operation.

#### Constructor
```dart
PhotoCaptureResult({
  required Uint8List photoBytes,
  required LocationData locationData,
  String? savedPath,
})
```

#### Properties

- `photoBytes` (Uint8List): Embedded photo data
- `locationData` (LocationData): Location information used in embedding
- `savedPath` (String?): File path if photo has been saved

#### Methods

##### `copyWith`
```dart
PhotoCaptureResult copyWith({
  Uint8List? photoBytes,
  LocationData? locationData,
  String? savedPath,
})
```
Create a copy with updated fields.

---

## Services

### CameraModule

Manages camera initialization, preview, and photo capture.

#### Properties

- `controller` (CameraController?): Camera controller for preview widgets
- `isInitialized` (bool): Whether camera is initialized
- `hasMultipleCameras` (bool): Whether device has multiple cameras

#### Methods

##### `initialize`
```dart
Future<void> initialize({ResolutionPreset preset = ResolutionPreset.high})
```
Initialize the camera with specified resolution.

##### `capturePhoto`
```dart
Future<Uint8List> capturePhoto()
```
Capture a photo and return as bytes.

##### `switchCamera`
```dart
Future<void> switchCamera()
```
Switch between front and rear cameras.

##### `dispose`
```dart
Future<void> dispose()
```
Dispose camera resources.

---

### LocationService

Retrieves GPS location and converts to addresses.

#### Methods

##### `getCurrentLocation`
```dart
Future<LocationData> getCurrentLocation({
  Duration timeout = const Duration(seconds: 15),
})
```
Get current GPS location with timeout.

**Throws:**
- `TimeoutException`
- `LocationServiceDisabledException`
- `PermissionDeniedException`

##### `getAddressFromCoordinates`
```dart
Future<String?> getAddressFromCoordinates(
  double latitude,
  double longitude, {
  Duration timeout = const Duration(seconds: 10),
})
```
Convert GPS coordinates to human-readable address.

##### `isLocationServiceEnabled`
```dart
Future<bool> isLocationServiceEnabled()
```
Check if location services are enabled.

##### `requestLocationPermission`
```dart
Future<bool> requestLocationPermission()
```
Request location permission from user.

---

### ImageProcessor

Processes images and embeds location information.

#### Methods

##### `embedLocationOnPhoto`
```dart
Future<Uint8List> embedLocationOnPhoto({
  required Uint8List photoBytes,
  required LocationData locationData,
})
```
Embed location information onto a photo.

**Details:**
- Overlays GPS coordinates, address, and timestamp
- Semi-transparent black background (85% opacity)
- White text for maximum contrast
- Positioned at bottom-left with padding
- JPEG quality: 85% (70% if over 2MB)

---

### PermissionManager

Manages camera and location permissions.

#### Methods

##### `requestCameraPermission`
```dart
Future<PermissionStatus> requestCameraPermission()
```
Request camera permission.

##### `requestLocationPermission`
```dart
Future<PermissionStatus> requestLocationPermission()
```
Request location permission.

##### `hasAllPermissions`
```dart
Future<bool> hasAllPermissions()
```
Check if all permissions are granted.

##### `openAppSettings`
```dart
Future<void> openAppSettings()
```
Open app settings for manual permission management.

---

### StorageManager

Manages saving photos to device storage.

#### Methods

##### `savePhoto`
```dart
Future<String> savePhoto(Uint8List photoBytes, {String? filename})
```
Save photo to device storage.

##### `getPhotosDirectory`
```dart
Future<String> getPhotosDirectory()
```
Get directory path where photos are stored.

##### `getAvailableSpace`
```dart
Future<int> getAvailableSpace()
```
Get available storage space in bytes.

---

## Enums

### PermissionStatus

Permission status values.

```dart
enum PermissionStatus {
  granted,              // Permission is granted
  denied,               // Permission denied but can request again
  permanentlyDenied,    // Permission permanently denied
  restricted,           // Permission restricted (e.g., parental controls)
}
```

---

## Exceptions

### TimeoutException
```dart
class TimeoutException implements Exception {
  final String message;
}
```
Thrown when an operation exceeds its timeout duration.

### LocationServiceDisabledException
```dart
class LocationServiceDisabledException implements Exception {
  final String message;
}
```
Thrown when location services are disabled on the device.

### PermissionDeniedException
```dart
class PermissionDeniedException implements Exception {
  final String message;
}
```
Thrown when required permissions are denied.

### StorageException
```dart
class StorageException implements Exception {
  final String message;
}
```
Thrown when storage operations fail.

---

## Constants

### Timeouts
- GPS acquisition: 15 seconds (default)
- Address lookup: 10 seconds (default)

### Image Settings
- Resolution: 1920x1080 (ResolutionPreset.high)
- JPEG quality: 85% (70% if over 2MB)
- Target file size: < 2MB
- Font: arial24
- Overlay position: Bottom-left with 20px padding
- Background opacity: 85%

### Required Permissions

#### Android
- `android.permission.CAMERA`
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`
- `android.permission.INTERNET`
- `android.permission.WRITE_EXTERNAL_STORAGE` (Android 12 and below)

#### iOS
- `NSCameraUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
