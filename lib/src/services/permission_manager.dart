import 'package:permission_handler/permission_handler.dart' as ph;

/// Manages permission requests for camera and location access
class PermissionManager {
  /// Request camera permission
  /// 
  /// Returns the permission status after the request.
  /// Handles all permission states: granted, denied, permanentlyDenied, restricted
  Future<PermissionStatus> requestCameraPermission() async {
    final status = await ph.Permission.camera.request();
    return _convertPermissionStatus(status);
  }

  /// Request location permission
  /// 
  /// Returns the permission status after the request.
  /// Handles all permission states: granted, denied, permanentlyDenied, restricted
  Future<PermissionStatus> requestLocationPermission() async {
    final status = await ph.Permission.location.request();
    return _convertPermissionStatus(status);
  }

  /// Check if all required permissions (camera and location) are granted
  /// 
  /// Returns true only if both camera and location permissions are granted
  Future<bool> hasAllPermissions() async {
    final cameraStatus = await ph.Permission.camera.status;
    final locationStatus = await ph.Permission.location.status;
    
    return cameraStatus.isGranted && locationStatus.isGranted;
  }

  /// Open app settings for manual permission grant
  /// 
  /// This is useful when permissions are permanently denied and
  /// the user needs to manually enable them in system settings
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  /// Convert permission_handler status to our custom PermissionStatus enum
  PermissionStatus _convertPermissionStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return PermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionStatus.restricted;
      case ph.PermissionStatus.limited:
        // Treat limited as granted (iOS 14+ photo library limited access)
        return PermissionStatus.granted;
      case ph.PermissionStatus.provisional:
        // Treat provisional as granted (iOS notification provisional access)
        return PermissionStatus.granted;
    }
  }
}

/// Permission status enum matching the design document
enum PermissionStatus {
  /// Permission is granted
  granted,
  
  /// Permission is denied but can be requested again
  denied,
  
  /// Permission is permanently denied and requires manual settings change
  permanentlyDenied,
  
  /// Permission is restricted (e.g., parental controls on iOS)
  restricted,
}
