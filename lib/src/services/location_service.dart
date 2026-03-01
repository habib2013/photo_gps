import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_data.dart';

/// Service for retrieving GPS location and converting to addresses.
///
/// Handles location permissions, GPS coordinate retrieval with timeout,
/// and geocoding with proper error handling.
class LocationService {
  /// Get current GPS location with timeout
  ///
  /// Returns [LocationData] with coordinates, accuracy, timestamp, and address.
  /// Address will be null if geocoding fails or times out.
  ///
  /// Throws [TimeoutException] if GPS retrieval exceeds timeout duration.
  /// Throws [LocationServiceDisabledException] if location services are disabled.
  /// Throws [PermissionDeniedException] if location permission is not granted.
  Future<LocationData> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException(
        'Location services are disabled. Please enable location services.',
      );
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw PermissionDeniedException(
          'Location permission denied. Please grant location permission.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException(
        'Location permission permanently denied. Please enable in settings.',
      );
    }

    // Get current position with timeout
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(
          'GPS location retrieval timed out after ${timeout.inSeconds} seconds.',
        );
      },
    );

    // Attempt to get address with timeout
    String? address;
    try {
      address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      // Silently fail geocoding - address will be null
      address = null;
    }

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
      address: address,
    );
  }

  /// Convert GPS coordinates to human-readable address
  ///
  /// Returns address string if successful, null if geocoding fails or times out.
  ///
  /// Parameters:
  /// - [latitude]: Latitude in degrees (-90 to 90)
  /// - [longitude]: Longitude in degrees (-180 to 180)
  /// - [timeout]: Maximum time to wait for geocoding (default: 10 seconds)
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Geocoding timed out after ${timeout.inSeconds} seconds.',
          );
        },
      );

      if (placemarks.isEmpty) {
        return null;
      }

      final placemark = placemarks.first;
      final addressParts = <String>[];

      if (placemark.street != null && placemark.street!.isNotEmpty) {
        addressParts.add(placemark.street!);
      }
      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        addressParts.add(placemark.locality!);
      }
      if (placemark.administrativeArea != null &&
          placemark.administrativeArea!.isNotEmpty) {
        addressParts.add(placemark.administrativeArea!);
      }
      if (placemark.country != null && placemark.country!.isNotEmpty) {
        addressParts.add(placemark.country!);
      }

      return addressParts.isEmpty ? null : addressParts.join(', ');
    } catch (e) {
      // Return null on any error (timeout, network, etc.)
      return null;
    }
  }

  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission from the user
  ///
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}

/// Exception thrown when location services are disabled
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when location permission is denied
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when an operation times out
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
