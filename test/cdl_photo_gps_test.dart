import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cdl_photo_gps/cdl_photo_gps.dart';

void main() {
  group('LocationData', () {
    test('formats coordinates correctly', () {
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: DateTime(2024, 1, 15, 14, 30, 45),
        address: 'San Francisco, CA, USA',
      );

      expect(location.formattedCoordinates, '37.774900, -122.419400');
    });

    test('formats timestamp correctly', () {
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: DateTime(2024, 1, 15, 14, 30, 45),
      );

      expect(location.formattedTimestamp, '2024-01-15 14:30:45');
    });

    test('generates overlay text with address', () {
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: DateTime(2024, 1, 15, 14, 30, 45),
        address: '123 Main St, San Francisco, CA, USA',
      );

      final overlayText = location.getOverlayText();
      expect(overlayText, contains('San Francisco'));
      expect(overlayText, contains('37.77490'));
      expect(overlayText, contains('-122.419400'));
    });

    test('generates overlay text without address', () {
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: DateTime(2024, 1, 15, 14, 30, 45),
      );

      final overlayText = location.getOverlayText();
      expect(overlayText, contains('Location Unavailable'));
      expect(overlayText, contains('37.77490'));
    });
  });

  group('PhotoCaptureResult', () {
    test('creates result with required fields', () {
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );

      final result = PhotoCaptureResult(
        photoBytes: Uint8List(0),
        locationData: location,
      );

      expect(result.photoBytes, isNotNull);
      expect(result.locationData, equals(location));
      expect(result.savedPath, isNull);
    });

    test('copyWith updates fields correctly', () {
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );

      final result = PhotoCaptureResult(
        photoBytes: Uint8List(0),
        locationData: location,
      );

      final updated = result.copyWith(savedPath: '/path/to/photo.jpg');

      expect(updated.savedPath, '/path/to/photo.jpg');
      expect(updated.locationData, equals(location));
    });
  });

  group('PermissionStatus', () {
    test('has all required status values', () {
      expect(PermissionStatus.granted, isNotNull);
      expect(PermissionStatus.denied, isNotNull);
      expect(PermissionStatus.permanentlyDenied, isNotNull);
      expect(PermissionStatus.restricted, isNotNull);
    });
  });
}
