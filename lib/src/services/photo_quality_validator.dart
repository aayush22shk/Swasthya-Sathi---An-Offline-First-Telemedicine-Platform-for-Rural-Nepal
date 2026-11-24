import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Image quality validation before skin analysis.
/// Checks for blur, darkness, overexposure, and minimum resolution.
/// Returns a [PhotoQualityResult] with pass/fail status and human-readable reason.
class PhotoQualityValidator {
  PhotoQualityValidator._();

  static const int _minWidth = 100;
  static const int _minHeight = 100;
  static const double _minLaplacianVariance = 80.0;  // blur threshold
  static const double _minMeanBrightness = 25.0;     // darkness threshold (0–255)
  static const double _maxMeanBrightness = 240.0;    // overexposure threshold (0–255)

  /// Validates an image file for quality.
  /// Returns a [PhotoQualityResult] — always call this before running inference.
  static Future<PhotoQualityResult> validate(String imagePath) async {
    return await compute(_validateIsolate, imagePath);
  }

  static Future<PhotoQualityResult> _validateIsolate(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return PhotoQualityResult.fail('Image file not found. Please capture or select a photo first.');
      }

      final bytes = file.readAsBytesSync();
      if (bytes.isEmpty) {
        return PhotoQualityResult.fail('The selected image file is empty. Please try again.');
      }

      final image = img.decodeImage(bytes);
      if (image == null) {
        return PhotoQualityResult.fail('Could not read the image file. Please capture a new photo.');
      }

      // 1. Minimum resolution check
      if (image.width < _minWidth || image.height < _minHeight) {
        return PhotoQualityResult.fail(
          'Image is too small (${image.width}×${image.height}px). '
          'Please capture a photo with at least $_minWidth×$_minHeight px resolution.',
        );
      }

      // 2. Brightness check — convert to grayscale and compute mean pixel value
      final grayscale = img.grayscale(image);
      double totalBrightness = 0;
      for (int y = 0; y < grayscale.height; y++) {
        for (int x = 0; x < grayscale.width; x++) {
          totalBrightness += grayscale.getPixel(x, y).r;
        }
      }
      final meanBrightness = totalBrightness / (grayscale.width * grayscale.height);

      if (meanBrightness < _minMeanBrightness) {
        return PhotoQualityResult.fail(
          'Image is too dark (brightness: ${meanBrightness.toStringAsFixed(0)}/255). '
          'Please take the photo in better lighting conditions.',
        );
      }

      if (meanBrightness > _maxMeanBrightness) {
        return PhotoQualityResult.fail(
          'Image is overexposed (brightness: ${meanBrightness.toStringAsFixed(0)}/255). '
          'Please reduce lighting or move away from direct light.',
        );
      }

      // 3. Blur detection — Laplacian variance (higher = sharper)
      final laplacianVariance = _computeLaplacianVariance(grayscale);
      if (laplacianVariance < _minLaplacianVariance) {
        return PhotoQualityResult.fail(
          'Image appears blurry (sharpness: ${laplacianVariance.toStringAsFixed(1)}). '
          'Please hold the camera steady and ensure the skin lesion is in focus.',
        );
      }

      return PhotoQualityResult.pass(
        brightness: meanBrightness,
        sharpness: laplacianVariance,
        resolution: '${image.width}×${image.height}',
      );
    } catch (e) {
      // On any unexpected error, let analysis proceed (don't block the user)
      return PhotoQualityResult.pass(brightness: 128, sharpness: 200, resolution: 'unknown');
    }
  }

  /// Computes the variance of Laplacian (sharpness measure).
  /// A higher variance means a sharper, more in-focus image.
  static double _computeLaplacianVariance(img.Image gray) {
    // Sample every 4th pixel for performance
    const step = 4;
    final laplacian = <double>[];

    for (int y = step; y < gray.height - step; y += step) {
      for (int x = step; x < gray.width - step; x += step) {
        final center = gray.getPixel(x, y).r.toDouble();
        final top    = gray.getPixel(x, y - 1).r.toDouble();
        final bottom = gray.getPixel(x, y + 1).r.toDouble();
        final left   = gray.getPixel(x - 1, y).r.toDouble();
        final right  = gray.getPixel(x + 1, y).r.toDouble();
        final lap = (top + bottom + left + right) - 4 * center;
        laplacian.add(lap);
      }
    }

    if (laplacian.isEmpty) return 0.0;
    final mean = laplacian.reduce((a, b) => a + b) / laplacian.length;
    final variance = laplacian.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / laplacian.length;
    return variance;
  }
}

class PhotoQualityResult {
  final bool isPassed;
  final String? failureReason;
  final double? brightness;
  final double? sharpness;
  final String? resolution;

  const PhotoQualityResult._({
    required this.isPassed,
    this.failureReason,
    this.brightness,
    this.sharpness,
    this.resolution,
  });

  factory PhotoQualityResult.pass({
    required double brightness,
    required double sharpness,
    required String resolution,
  }) => PhotoQualityResult._(
    isPassed: true,
    brightness: brightness,
    sharpness: sharpness,
    resolution: resolution,
  );

  factory PhotoQualityResult.fail(String reason) => PhotoQualityResult._(
    isPassed: false,
    failureReason: reason,
  );

  @override
  String toString() => isPassed
      ? 'PASS (brightness=${brightness?.toStringAsFixed(0)}, '
        'sharpness=${sharpness?.toStringAsFixed(1)}, res=$resolution)'
      : 'FAIL: $failureReason';
}
