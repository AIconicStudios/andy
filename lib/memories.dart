import 'dart:math';

import 'package:image/image.dart' as img;

/// What Andy "sees" in one photo of a thing. Three independent clues:
/// what kind of thing it is, any words printed on it, and its colours.
class Signature {
  Signature({required this.labels, required this.words, required this.colors});

  /// Kind of object, with confidence 0..1, e.g. {"Book": 0.9}.
  final Map<String, double> labels;

  /// Words read off the object: a book title, a brand on a TV.
  final Set<String> words;

  /// Normalised colour histogram, [colorBins] long.
  final List<double> colors;

  Map<String, dynamic> toJson() => {
        'labels': labels,
        'words': words.toList(),
        'colors': colors.map((c) => (c * 1000).round() / 1000).toList(),
      };

  static Signature fromJson(Map<String, dynamic> j) => Signature(
        labels: Map<String, dynamic>.from(j['labels'] ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        words: Set<String>.from(j['words'] ?? []),
        colors: ((j['colors'] ?? []) as List)
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}

class Memory {
  Memory({
    required this.id,
    required this.title,
    required this.note,
    required this.photo,
    required this.created,
    required this.signatures,
  });
  final String id;
  String title;
  String note;

  /// File name of the saved photo inside the app's memories folder.
  final String photo;
  final DateTime created;

  /// One per confirmed sighting, so recognition improves with use.
  final List<Signature> signatures;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'photo': photo,
        'created': created.toIso8601String(),
        'signatures': signatures.map((s) => s.toJson()).toList(),
      };

  static Memory fromJson(Map<String, dynamic> j) => Memory(
        id: j['id'],
        title: j['title'],
        note: j['note'],
        photo: j['photo'] ?? '',
        created: DateTime.parse(j['created']),
        signatures: ((j['signatures'] ?? []) as List)
            .map((e) => Signature.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

const maxSignaturesPerMemory = 4;

// ---- reading clues out of raw input ---------------------------------------

/// Keeps distinctive words only: lower-cased, 3+ characters, capped.
Set<String> wordsFrom(String text) => text
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((w) => w.length >= 3)
    .take(40)
    .toSet();

const _hueBins = 12;
const _greyBins = 4;
const colorBins = _hueBins + _greyBins;

/// Colour fingerprint of the middle of the picture, where the object is.
///
/// Colourful pixels are binned by hue alone, so the same object under
/// brighter or dimmer light lands in the same bins. Greys are binned by
/// brightness. Rotation of the photo makes no difference.
List<double> colorHistogram(img.Image image) {
  final hist = List<double>.filled(colorBins, 0);
  final x0 = (image.width * 0.2).floor(), x1 = (image.width * 0.8).ceil();
  final y0 = (image.height * 0.2).floor(), y1 = (image.height * 0.8).ceil();
  final step = max(1, min(x1 - x0, y1 - y0) ~/ 64);
  var n = 0;
  for (var y = y0; y < y1; y += step) {
    for (var x = x0; x < x1; x += step) {
      final p = image.getPixel(x, y);
      final r = p.rNormalized.toDouble();
      final g = p.gNormalized.toDouble();
      final b = p.bNormalized.toDouble();
      final hi = max(r, max(g, b)), lo = min(r, min(g, b));
      final delta = hi - lo;
      final sat = hi == 0 ? 0.0 : delta / hi;
      if (sat < 0.2 || hi < 0.15) {
        hist[_hueBins + min(_greyBins - 1, (hi * _greyBins).floor())]++;
      } else {
        double hue;
        if (hi == r) {
          hue = ((g - b) / delta) % 6;
        } else if (hi == g) {
          hue = (b - r) / delta + 2;
        } else {
          hue = (r - g) / delta + 4;
        }
        hist[(hue / 6 * _hueBins).floor() % _hueBins]++;
      }
      n++;
    }
  }
  if (n > 0) {
    for (var i = 0; i < hist.length; i++) {
      hist[i] /= n;
    }
  }
  return hist;
}

// ---- matching -------------------------------------------------------------

double _labelScore(Map<String, double> a, Map<String, double> b) {
  if (a.isEmpty && b.isEmpty) return 0.5; // no evidence either way
  if (a.isEmpty || b.isEmpty) return 0;
  var dot = 0.0, na = 0.0, nb = 0.0;
  for (final e in a.entries) {
    dot += e.value * (b[e.key] ?? 0);
    na += e.value * e.value;
  }
  for (final v in b.values) {
    nb += v * v;
  }
  return dot / sqrt(na * nb);
}

double _colorScore(List<double> a, List<double> b) {
  if (a.length != b.length || a.isEmpty) return 0;
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    s += min(a[i], b[i]);
  }
  return s;
}

bool _hasText(Signature s) => s.words.length >= 2;

/// How alike two sightings are, 0..1.
///
/// Printed words are the strongest clue for telling one particular book or
/// box from another, so when both sightings have them they dominate. With no
/// words to go on, Andy falls back to "same kind of thing, same colours".
double similarity(Signature a, Signature b) {
  final label = _labelScore(a.labels, b.labels);
  final color = _colorScore(a.colors, b.colors);
  if (_hasText(a) && _hasText(b)) {
    final shared = a.words.intersection(b.words).length;
    final text = shared / min(a.words.length, b.words.length);
    return 0.65 * text + 0.15 * label + 0.20 * color;
  }
  final look = 0.45 * label + 0.55 * color;
  // Words on one sighting but not the other: probably different things.
  return _hasText(a) != _hasText(b) ? look * 0.85 : look;
}

/// Score needed to call it a match. Looks alone are weaker evidence than
/// words, so they have to agree more strongly.
double threshold(Signature a, Signature b) =>
    _hasText(a) && _hasText(b) ? 0.55 : 0.72;

class MemoryMatch {
  MemoryMatch(this.memory, this.score);
  final Memory memory;
  final double score;
}

/// The saved memory this sighting most likely belongs to, if any.
MemoryMatch? bestMatch(List<Memory> memories, Signature seen) {
  MemoryMatch? best;
  for (final m in memories) {
    for (final s in m.signatures) {
      final score = similarity(seen, s);
      // Rank by margin over the bar, so a strong text match beats a
      // marginal looks-only match.
      final margin = score - threshold(seen, s);
      if (margin >= 0 &&
          (best == null || margin > best.score)) {
        best = MemoryMatch(m, margin);
      }
    }
  }
  return best;
}
