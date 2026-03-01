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

    test('tracks mock location flag', () {
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: DateTime.now(),
        isMocked: true,
      );

      expect(location.isMocked, isTrue);
    });
  });

  group('PhotoCaptureResult', () {
    test('creates result with bytes format', () {
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );

      final result = PhotoCaptureResult(
        photoBytes: Uint8List(100),
        locationData: location,
        isMockLocation: false,
        locationConfidence: 1.0,
      );

      expect(result.photoBytes, isNotNull);
      expect(result.photoBase64, isNull);
      expect(result.filePath, isNull);
      expect(result.locationData, equals(location));
      expect(result.isMockLocation, isFalse);
      expect(result.locationConfidence, equals(1.0));
    });

    test('creates result with base64 format', () {
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );

      final result = PhotoCaptureResult(
        photoBase64: 'base64string',
        locationData: location,
        isMockLocation: false,
        locationConfidence: 0.8,
      );

      expect(result.photoBytes, isNull);
      expect(result.photoBase64, equals('base64string'));
      expect(result.locationConfidence, equals(0.8));
    });

    test('tracks mock location in result', () {
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 10.0,
        timestamp: DateTime.now(),
        isMocked: true,
      );

      final result = PhotoCaptureResult(
        photoBytes: Uint8List(100),
        locationData: location,
        isMockLocation: true,
        locationConfidence: 0.2,
      );

      expect(result.isMockLocation, isTrue);
      expect(result.locationConfidence, equals(0.2));
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

      final updated = result.copyWith(filePath: '/path/to/photo.jpg');

      expect(updated.filePath, '/path/to/photo.jpg');
      expect(updated.locationData, equals(location));
    });
  });

  group('SDKConfig', () {
    test('has default values', () {
      const config = SDKConfig();

      expect(config.outputFormat, OutputFormat.bytes);
      expect(config.detectMockGPS, isTrue);
      expect(config.gpsTimeout, Duration(seconds: 15));
      expect(config.showPermissionRationale, isTrue);
      expect(config.imageQuality, 85);
    });

    test('copyWith updates fields', () {
      const config = SDKConfig();
      final updated = config.copyWith(
        outputFormat: OutputFormat.base64,
        detectMockGPS: false,
      );

      expect(updated.outputFormat, OutputFormat.base64);
      expect(updated.detectMockGPS, isFalse);
      expect(updated.gpsTimeout, Duration(seconds: 15)); // unchanged
    });
  });

  group('OutputFormat', () {
    test('has all required formats', () {
      expect(OutputFormat.bytes, isNotNull);
      expect(OutputFormat.base64, isNotNull);
      expect(OutputFormat.file, isNotNull);
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

  group('FormatConverter', () {
    test('converts bytes to base64', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final base64 = FormatConverter.bytesToBase64(bytes);

      expect(base64, isNotEmpty);
      expect(base64, isA<String>());
    });

    test('converts base64 to bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final base64 = FormatConverter.bytesToBase64(bytes);
      final decoded = FormatConverter.base64ToBytes(base64);

      expect(decoded, equals(bytes));
    });

    test('formats size correctly', () {
      expect(FormatConverter.formatSize(500), '500 B');
      expect(FormatConverter.formatSize(1024), '1.0 KB');
      expect(FormatConverter.formatSize(1024 * 1024), '1.0 MB');
    });
  });
}
