// CDL Photo GPS SDK
//
// A Flutter SDK for capturing photos with embedded GPS location information.
// Automatically overlays coordinates, address, and timestamp directly onto images.

// Core SDK
export 'src/cdl_photo_gps_sdk.dart';

// Models
export 'src/models/location_data.dart';
export 'src/models/photo_capture_result.dart';

// Services (for advanced usage)
export 'src/services/camera_module.dart';
export 'src/services/image_processor.dart';
export 'src/services/location_service.dart';
export 'src/services/permission_manager.dart';
export 'src/services/storage_manager.dart';

// Re-export camera package for ResolutionPreset
export 'package:camera/camera.dart' show ResolutionPreset, CameraController;
