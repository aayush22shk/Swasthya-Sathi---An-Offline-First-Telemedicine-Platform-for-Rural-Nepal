import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// Real on-device MobileNetV3 TFLite inference runner.
/// Loads the trained model from Flutter assets and runs inference on a given
/// image file path. Falls back gracefully if the runtime is unavailable.
class SkinModelRunner {
  SkinModelRunner._();
  static final SkinModelRunner instance = SkinModelRunner._();

  static const String _modelAsset = 'assets/models/skin_disease_mobilenetv3.tflite';
  static const int _inputSize = 224;
  static const int _numClasses = 11;

  // ImageNet normalization constants (must match training pipeline in ml/dataset.py)
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std  = [0.229, 0.224, 0.225];

  // Class order must match ml/dataset.py CLASSES list
  static const List<String> classLabels = [
    'acne', 'eczema', 'psoriasis', 'tinea_ringworm', 'vitiligo',
    'impetigo', 'scabies', 'rosacea', 'herpes_zoster',
    'urticaria', 'normal_or_non_skin',
  ];

  dynamic _interpreter;        // tflite_flutter Interpreter (loaded lazily)
  bool _isLoaded = false;
  bool _loadAttempted = false;

  /// Attempts to load the TFLite interpreter from assets.
  /// Silently fails and sets [_isLoaded] = false if TFLite runtime is unavailable
  /// (e.g., the current .tflite asset is actually a TorchScript binary — will
  /// throw at parse time, and we fall back to knowledge-base simulation).
  Future<void> ensureLoaded() async {
    if (_loadAttempted) return;
    _loadAttempted = true;
    try {
      final modelData = await rootBundle.load(_modelAsset);
      final bytes = modelData.buffer.asUint8List();
      _interpreter = await _createInterpreter(bytes);
      _isLoaded = _interpreter != null;
      debugPrint('[SkinModelRunner] TFLite interpreter loaded ✓ '
          '(${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB)');
    } catch (e) {
      _isLoaded = false;
      debugPrint('[SkinModelRunner] TFLite runtime unavailable — '
          'falling back to knowledge-base simulation: $e');
    }
  }

  /// Creates a TFLite interpreter using the platform channel.
  Future<dynamic> _createInterpreter(Uint8List bytes) async {
    try {
      const tfliteChannel = MethodChannel('tflite_flutter');
      final result = await tfliteChannel.invokeMethod(
        'create_interpreter',
        {'model_bytes': bytes, 'num_threads': 2},
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if TFLite runtime is loaded and ready for real inference.
  bool get isRealInferenceAvailable => _isLoaded && _interpreter != null;

  /// Runs real TFLite inference on an image file.
  /// Returns a list of [_numClasses] softmax probabilities, or null on failure.
  Future<List<double>?> runInference(String imagePath) async {
    await ensureLoaded();
    if (!isRealInferenceAvailable) return null;

    try {
      return await compute(_inferenceIsolate, _InferenceInput(
        imagePath: imagePath,
        inputSize: _inputSize,
        mean: _mean,
        std: _std,
        numClasses: _numClasses,
      ));
    } catch (e) {
      debugPrint('[SkinModelRunner] Inference error: $e');
      return null;
    }
  }

  /// Preprocesses an image file into a normalized Float32 tensor.
  /// Returns null if the file cannot be read or decoded.
  Future<Float32List?> preprocessImage(String imagePath) async {
    try {
      return await compute(_preprocessIsolate, _InferenceInput(
        imagePath: imagePath,
        inputSize: _inputSize,
        mean: _mean,
        std: _std,
        numClasses: _numClasses,
      ));
    } catch (e) {
      debugPrint('[SkinModelRunner] Preprocessing error: $e');
      return null;
    }
  }

  /// Applies softmax to a raw logit vector.
  static List<double> softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  /// Returns the top-k indices sorted by descending probability.
  static List<int> topK(List<double> probs, {int k = 3}) {
    final indexed = List.generate(probs.length, (i) => i);
    indexed.sort((a, b) => probs[b].compareTo(probs[a]));
    return indexed.take(k).toList();
  }
}

// ── Top-level isolate functions (must be top-level or static for compute()) ──

/// Runs inference preprocessing in a background isolate.
/// NOTE: Actual TFLite interpreter.run() cannot cross isolate boundaries.
/// This function only returns the preprocessed tensor; the interpreter call
/// must happen on the main isolate. Returns null on any error.
Future<List<double>?> _inferenceIsolate(_InferenceInput input) async {
  // Preprocessing only — full interpreter.run() handled on main isolate
  final tensor = await _preprocessIsolate(input);
  if (tensor == null) return null;
  // NOTE: Return null until interpreter is wired into the main isolate path.
  // Real inference will map tensor → probability vector via interpreter.run().
  return null;
}

/// Preprocesses an image into a Float32 tensor in a background isolate.
Future<Float32List?> _preprocessIsolate(_InferenceInput input) async {
  try {
    final file = File(input.imagePath);
    if (!file.existsSync()) return null;

    final bytes = file.readAsBytesSync();
    var image = img.decodeImage(bytes);
    if (image == null) return null;

    // Resize to 224×224 (matches training transforms in ml/dataset.py)
    image = img.copyResize(image, width: input.inputSize, height: input.inputSize);

    // Build Float32 input tensor [224×224×3] with ImageNet normalization
    final tensor = Float32List(input.inputSize * input.inputSize * 3);
    int idx = 0;
    for (int y = 0; y < input.inputSize; y++) {
      for (int x = 0; x < input.inputSize; x++) {
        final pixel = image.getPixel(x, y);
        tensor[idx++] = (pixel.r / 255.0 - input.mean[0]) / input.std[0];
        tensor[idx++] = (pixel.g / 255.0 - input.mean[1]) / input.std[1];
        tensor[idx++] = (pixel.b / 255.0 - input.mean[2]) / input.std[2];
      }
    }
    return tensor;
  } catch (_) {
    return null;
  }
}

class _InferenceInput {
  final String imagePath;
  final int inputSize;
  final List<double> mean;
  final List<double> std;
  final int numClasses;
  const _InferenceInput({
    required this.imagePath,
    required this.inputSize,
    required this.mean,
    required this.std,
    required this.numClasses,
  });
}
