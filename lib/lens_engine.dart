import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'memories.dart';

/// One look through the camera: the clues, plus a small photo to keep.
class Sighting {
  Sighting(this.signature, this.thumbnail);
  final Signature signature;
  final Uint8List thumbnail;
}

class _Pixels {
  _Pixels(this.colors, this.thumbnail, this.crops);
  final List<double> colors;
  final Uint8List thumbnail;

  /// Model inputs: the photo's centre at each zoom level, 224x224 RGB 0..1.
  final List<Float32List> crops;
}

const _side = 224;
const embedSize = 1024;

/// Fractions of the photo's short side to look at. The widest catches a
/// thing that fills the frame; the tightest catches it small and far away.
const zoomLevels = [1.0, 0.7, 0.5, 0.33];

Float32List _modelInput(img.Image photo, double zoom) {
  final side = (min(photo.width, photo.height) * zoom).round();
  final crop = img.copyCrop(photo,
      x: (photo.width - side) ~/ 2,
      y: (photo.height - side) ~/ 2,
      width: side,
      height: side);
  final sized = img.copyResize(crop,
      width: _side, height: _side, interpolation: img.Interpolation.linear);
  final out = Float32List(_side * _side * 3);
  var i = 0;
  for (final p in sized) {
    out[i++] = p.rNormalized.toDouble();
    out[i++] = p.gNormalized.toDouble();
    out[i++] = p.bNormalized.toDouble();
  }
  return out;
}

// Runs off the UI thread: decoding a camera JPEG in Dart takes a moment.
_Pixels _readPixels(String path) {
  final decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) {
    return _Pixels(List.filled(colorBins, 0), Uint8List(0), const []);
  }
  final upright = img.bakeOrientation(decoded);
  final small = upright.width > upright.height
      ? img.copyResize(upright, width: 720)
      : img.copyResize(upright, height: 720);
  // Zoomed crops come from the full photo so the tightest stays sharp.
  return _Pixels(colorHistogram(small), img.encodeJpg(small, quality: 82),
      [for (final z in zoomLevels) _modelInput(upright, z)]);
}

/// Turns a photo into a [Signature]. All recognition runs on the phone with
/// free models (a MobileNet image embedder and Google ML Kit); no photo ever
/// leaves the device.
class LensEngine {
  ImageLabeler? _labeler;
  TextRecognizer? _reader;
  Interpreter? _embedder;
  String? _dir;

  /// False if the visual model failed to load; matching then falls back to
  /// words, kind and colour.
  bool get hasEmbedder => _embedder != null;

  Future<void> init() async {
    if (kIsWeb || _dir != null) return;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/memories');
    await dir.create(recursive: true);
    _dir = dir.path;
    _labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.55));
    _reader = TextRecognizer();
    try {
      _embedder = await Interpreter.fromAsset('assets/embedder.tflite',
          options: InterpreterOptions()..threads = 2);
    } catch (e) {
      debugPrint('Visual model unavailable: $e');
    }
  }

  Future<Sighting> look(String photoPath) async {
    final input = InputImage.fromFilePath(photoPath);
    final labelsF = _labeler!.processImage(input).catchError((_) => <ImageLabel>[]);
    final textF = _reader!.processImage(input).then((t) => t.text).catchError((_) => '');
    final pixelsF = compute(_readPixels, photoPath);
    final labels = await labelsF;
    final text = await textF;
    final pixels = await pixelsF;
    return Sighting(
      Signature(
        labels: {for (final l in labels.take(6)) l.label: l.confidence},
        words: wordsFrom(text),
        colors: pixels.colors,
        embeds: _embed(pixels.crops),
      ),
      pixels.thumbnail,
    );
  }

  List<Int8List> _embed(List<Float32List> crops) {
    final model = _embedder;
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

  /// Saves the photo for a memory and returns its file name.
  Future<String> keepPhoto(String id, Uint8List jpg) async {
    final name = '$id.jpg';
    await File('$_dir/$name').writeAsBytes(jpg);
    return name;
  }

  /// The stored photo, or null if there is none (or on the web preview).
  File? photo(String name) {
    if (_dir == null || name.isEmpty) return null;
    final f = File('$_dir/$name');
    return f.existsSync() ? f : null;
  }

  Future<void> forgetPhoto(String name) async {
    final f = photo(name);
    if (f != null) await f.delete();
  }
}

final lens = LensEngine();
