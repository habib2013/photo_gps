import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/location_data.dart';

/// Service class for processing images and embedding location information.
///
/// Handles overlaying location data (GPS coordinates, address, timestamp)
/// onto captured photos with proper formatting and readability.
class ImageProcessor {
  /// Embed location information onto a photo.
  ///
  /// Takes raw photo bytes and location data, overlays the location information
  /// on the image with a semi-transparent background, and returns the processed
  /// image as JPEG bytes.
  ///
  /// Parameters:
  /// - [photoBytes]: Raw image data as bytes
  /// - [locationData]: Location information to embed
  ///
  /// Returns: Processed image as JPEG bytes with embedded location overlay
  ///
  /// Throws: Exception if image processing fails
  Future<Uint8List> embedLocationOnPhoto({
    required Uint8List photoBytes,
    required LocationData locationData,
  }) async {
    try {
      // Load image from bytes
      final image = img.decodeImage(photoBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Get overlay text from location data
      final overlayText = locationData.getOverlayText();

      // Calculate font size based on image resolution (24px base for 1920x1080)
      final baseFontSize = 24.0;
      final scaleFactor = image.width / 1920.0;
      final fontSize = (baseFontSize * scaleFactor).round().clamp(16, 48);

      // Draw text with background
      _drawTextWithBackground(
        image: image,
        text: overlayText,
        fontSize: fontSize,
      );

      // Encode as JPEG with 85% quality
      final jpegBytes = img.encodeJpg(image, quality: 85);

      // Check if output is under 2MB
      if (jpegBytes.length > 2 * 1024 * 1024) {
        // If over 2MB, re-encode with lower quality
        final reducedQualityBytes = img.encodeJpg(image, quality: 70);
        return Uint8List.fromList(reducedQualityBytes);
      }

      return Uint8List.fromList(jpegBytes);
    } catch (e) {
      throw Exception('Failed to embed location on photo: $e');
    }
  }

  /// Draw text with semi-transparent background on image.
  ///
  /// Positions text at bottom with padding and draws a
  /// semi-transparent black background behind white text for readability.
  /// Uses larger text that spans most of the screen width.
  ///
  /// Parameters:
  /// - [image]: Image to draw on
  /// - [text]: Multi-line text to draw
  /// - [fontSize]: Base font size in pixels (used for scaling calculations)
  void _drawTextWithBackground({
    required img.Image image,
    required String text,
    required int fontSize,
  }) {
    // Split text into lines
    final lines = text.split('\n');
    if (lines.isEmpty) return;

    // Use arial24 for better fit - still readable but won't overflow
    // This ensures even long addresses fit within the screen
    final font = img.arial24;

    // Calculate actual line height based on font
    final lineHeight = font.lineHeight;
    
    // For arial24, character width is approximately 14-15 pixels
    final charWidth = 15;
    
    // Padding and spacing adjusted for smaller font
    final textPadding = 25;
    final imagePadding = 20;
    final lineSpacing = 10;

    // Calculate text width based on longest line
    final maxLineLength = lines.map((line) => line.length).reduce((a, b) => a > b ? a : b);
    final estimatedTextWidth = maxLineLength * charWidth;

    // Calculate background width
    var bgWidth = estimatedTextWidth + (textPadding * 2);
    
    // Cap at image width minus margins (ensure it fits on screen)
    final maxAllowedWidth = image.width - (imagePadding * 2);
    if (bgWidth > maxAllowedWidth) {
      bgWidth = maxAllowedWidth;
    }

    // Calculate total height with increased spacing
    final totalHeight = (lines.length * lineHeight) + ((lines.length - 1) * lineSpacing) + (textPadding * 2);
    final bgHeight = totalHeight;

    // Position at bottom-left with padding
    final bgX = imagePadding;
    final bgY = image.height - bgHeight - imagePadding;

    // Safety check: if overlay is too tall, skip drawing
    if (bgY < 0) {
      return;
    }

    // Draw semi-transparent black background (0.85 opacity for better readability)
    final backgroundColor = img.ColorRgba8(0, 0, 0, (255 * 0.85).round());
    img.fillRect(
      image,
      x1: bgX,
      y1: bgY,
      x2: bgX + bgWidth,
      y2: bgY + bgHeight,
      color: backgroundColor,
    );

    // Draw white text line by line
    final textColor = img.ColorRgba8(255, 255, 255, 255);
    final textX = bgX + textPadding;
    var textY = bgY + textPadding;

    for (final line in lines) {
      img.drawString(
        image,
        line,
        font: font,
        x: textX,
        y: textY,
        color: textColor,
      );
      
      // Move to next line position
      textY += lineHeight + lineSpacing;
    }
  }
}
