import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'memories.dart';

/// One look through the camera: the clues, plus a small photo to keep.
class Sighting {
  Sighting(this.signature, this.thumbnail);
  final Signature signature;
  final Uint8List thumbnail;
}

class _Pixels {
  _Pixels(this.colors, this.thumbnail);
  final List<double> colors;
  final Uint8List thumbnail;
}

// Runs off the UI thread: decoding a camera JPEG in Dart takes a moment.
_Pixels _readPixels(String path) {
  final decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) return _Pixels(List.filled(colorBins, 0), Uint8List(0));
  final upright = img.bakeOrientation(decoded);
  final small = upright.width > upright.height
      ? img.copyResize(upright, width: 720)
      : img.copyResize(upright, height: 720);
  return _Pixels(colorHistogram(small), img.encodeJpg(small, quality: 82));
}

/// Turns a photo into a [Signature]. All recognition runs on the phone with
/// Google's free ML Kit models; no photo ever leaves the device.
class LensEngine {
  ImageLabeler? _labeler;
  TextRecognizer? _reader;
  String? _dir;

  Future<void> init() async {
    if (kIsWeb || _dir != null) return;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/memories');
    await dir.create(recursive: true);
    _dir = dir.path;
    _labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.55));
    _reader = TextRecognizer();
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
      ),
      pixels.thumbnail,
    );
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
