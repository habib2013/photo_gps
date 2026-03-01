/// Configuration options for the CDL Photo GPS SDK
class SDKConfig {
  /// Output format for captured photos
  final OutputFormat outputFormat;

  /// Whether to detect mock/fake GPS locations
  final bool detectMockGPS;

  /// Timeout duration for GPS location retrieval
  final Duration gpsTimeout;

  /// Whether to show permission rationale dialogs before requesting
  final bool showPermissionRationale;

  /// Whether to show loading indicators during operations
  final bool showLoadingIndicators;

  /// Maximum image file size in bytes (default: 2MB)
  final int maxImageSize;

  /// JPEG quality (0-100, default: 85)
  final int imageQuality;

  const SDKConfig({
    this.outputFormat = OutputFormat.bytes,
    this.detectMockGPS = true,
    this.gpsTimeout = const Duration(seconds: 15),
    this.showPermissionRationale = true,
    this.showLoadingIndicators = true,
    this.maxImageSize = 2 * 1024 * 1024, // 2MB
    this.imageQuality = 85,
  });

  /// Create a copy with updated fields
  SDKConfig copyWith({
    OutputFormat? outputFormat,
    bool? detectMockGPS,
    Duration? gpsTimeout,
    bool? showPermissionRationale,
    bool? showLoadingIndicators,
    int? maxImageSize,
    int? imageQuality,
  }) {
    return SDKConfig(
      outputFormat: outputFormat ?? this.outputFormat,
      detectMockGPS: detectMockGPS ?? this.detectMockGPS,
      gpsTimeout: gpsTimeout ?? this.gpsTimeout,
      showPermissionRationale: showPermissionRationale ?? this.showPermissionRationale,
      showLoadingIndicators: showLoadingIndicators ?? this.showLoadingIndicators,
      maxImageSize: maxImageSize ?? this.maxImageSize,
      imageQuality: imageQuality ?? this.imageQuality,
    );
  }
}

/// Output format options for captured photos
enum OutputFormat {
  /// Return photo as Uint8List bytes (default)
  bytes,

  /// Return photo as base64 encoded string
  base64,

  /// Save to temporary file and return file path
  file,
}
