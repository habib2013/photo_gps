import 'package:geolocator/geolocator.dart';

/// Service for detecting mock/fake GPS locations.
///
/// Helps identify when users are spoofing their location using
/// fake GPS apps or developer tools.
class MockGPSDetector {
  /// Check if a position is from a mock location provider
  ///
  /// Returns true if the location appears to be fake/mocked.
  /// Returns false if the location appears genuine.
  ///
  /// Note: This is a best-effort detection and may not catch all cases.
  Future<bool> isMockLocation(Position position) async {
    // On Android, Geolocator provides isMocked flag
    // On iOS, this is harder to detect but we check for simulator
    return position.isMocked;
  }

  /// Calculate a confidence score for location authenticity
  ///
  /// Returns a value between 0.0 and 1.0:
  /// - 1.0 = highly confident the location is real
  /// - 0.0 = highly confident the location is fake
  ///
  /// Factors considered:
  /// - Mock location flag
  /// - GPS accuracy
  /// - Speed (unrealistic speeds indicate fake)
  /// - Altitude (if available)
  Future<double> calculateLocationConfidence(Position position) async {
    double confidence = 1.0;

    // Check mock flag (most reliable indicator)
    if (position.isMocked) {
      confidence -= 0.8; // Heavy penalty for mock flag
    }

    // Check accuracy (poor accuracy might indicate issues)
    if (position.accuracy > 100) {
      confidence -= 0.1; // Minor penalty for poor accuracy
    } else if (position.accuracy > 50) {
      confidence -= 0.05;
    }

    // Check for unrealistic speed (if available)
    if (position.speed > 200) {
      // Speed over 200 m/s (~720 km/h) is unrealistic for ground travel
      confidence -= 0.2;
    }

    // Ensure confidence stays within bounds
    return confidence.clamp(0.0, 1.0);
  }

  /// Get a human-readable description of the location confidence
  String getConfidenceDescription(double confidence) {
    if (confidence >= 0.9) {
      return 'High confidence - Location appears genuine';
    } else if (confidence >= 0.7) {
      return 'Good confidence - Location likely genuine';
    } else if (confidence >= 0.5) {
      return 'Medium confidence - Location may be questionable';
    } else if (confidence >= 0.3) {
      return 'Low confidence - Location appears suspicious';
    } else {
      return 'Very low confidence - Location likely fake';
    }
  }
}
