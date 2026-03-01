/// Model class representing location information for GPS photo capture.
///
/// Contains GPS coordinates, accuracy, timestamp, and optional address.
/// Provides formatted output methods for display and image overlay.
class LocationData {
  /// Latitude in degrees (-90 to 90)
  final double latitude;

  /// Longitude in degrees (-180 to 180)
  final double longitude;

  /// Accuracy of the location in meters
  final double accuracy;

  /// Timestamp when the location was captured
  final DateTime timestamp;

  /// Human-readable address (null if geocoding failed or unavailable)
  final String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.address,
  });

  /// Format coordinates for display with 6 decimal places
  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  /// Format timestamp as "YYYY-MM-DD HH:MM:SS"
  String get formattedTimestamp =>
      '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

  /// Get display text for image overlay
  ///
  /// Returns a multi-line string containing:
  /// - Location name (city, region, country) 
  /// - Full address
  /// - Labeled coordinates (Lat/Long)
  /// - Day of week + formatted date/time with timezone
  String getOverlayText() {
    final buffer = StringBuffer();
    
    if (address != null && address!.isNotEmpty) {
      // Extract location name from address (last parts typically contain city, region, country)
      final addressParts = address!.split(',').map((s) => s.trim()).toList();
      
      // Create a location header from last 2-3 parts (e.g., "Ikeja, Lagos, Nigeria")
      if (addressParts.length >= 3) {
        final locationName = addressParts.skip(addressParts.length - 3).join(', ');
        buffer.writeln(locationName);
      } else if (addressParts.length == 2) {
        final locationName = addressParts.join(', ');
        buffer.writeln(locationName);
      }
      
      // Full address on next line
      buffer.writeln(address);
    } else {
      buffer.writeln('Location Unavailable');
    }
    
    // Coordinates with labels (5 decimal places for cleaner display)
    buffer.writeln('Lat ${latitude.toStringAsFixed(5)}° Long ${longitude.toStringAsFixed(6)}°');
    
    // Day of week + formatted date/time with timezone
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayOfWeek = weekdays[timestamp.weekday - 1];
    final formattedDate = '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    final formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.timeZoneName}';
    buffer.writeln('$dayOfWeek, $formattedDate $formattedTime');
    
    return buffer.toString().trim();
  }
}
