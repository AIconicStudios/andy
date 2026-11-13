import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'memories.dart';

const embedSize = 1024;

/// Runs the bundled MobileNet image embedder with TensorFlow Lite.
class Embedder {
  Interpreter? _model;

  bool get loaded => _model != null;

  Future<void> load() async {
    try {
      _model = await Interpreter.fromAsset('assets/embedder.tflite',
          options: InterpreterOptions()..threads = 2);
    } catch (e) {
      debugPrint('Visual model unavailable: $e');
    }
  }

  /// One fingerprint per crop, or nothing if the model is unavailable.
  List<Int8List> embed(List<Float32List> crops) {
    final model = _model;
    if (model == null) return const [];
    try {
      final out = <Int8List>[];
      for (final crop in crops) {
        final result = Float32List(embedSize);
        model.run(crop.buffer.asUint8List(), result.buffer);
        out.add(quantize(result));
      }
      return out;
    } catch (e) {
      debugPrint('Visual model failed: $e');
      return const [];
    }
  }
}
