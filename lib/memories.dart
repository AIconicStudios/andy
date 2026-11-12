import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// What Andy "sees" in one photo of a thing: how it looks (a neural
/// fingerprint at several zoom levels), any words printed on it, what kind of
/// thing it is, and its colours.
class Signature {
  Signature({
    required this.labels,
    required this.words,
    required this.colors,
    this.embeds = const [],
  });

  /// Visual fingerprints of the photo at several zoom levels, widest first.
  /// Comparing every zoom of one photo with every zoom of another is what
  /// lets a close-up match a shot taken from across the room. Empty when
  /// the model was unavailable (and for memories saved by older versions).
  final List<Int8List> embeds;

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
        'embeds': embeds.map((e) => base64Encode(Uint8List.sublistView(e))).toList(),
      };

  static Signature fromJson(Map<String, dynamic> j) => Signature(
        labels: Map<String, dynamic>.from(j['labels'] ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        words: Set<String>.from(j['words'] ?? []),
        colors: ((j['colors'] ?? []) as List)
            .map((e) => (e as num).toDouble())
            .toList(),
        embeds: ((j['embeds'] ?? []) as List)
            .map((e) => Int8List.sublistView(base64Decode(e as String)))
            .toList(),
      );
}

/// Packs a model output into one byte per value. Only the direction of the
/// vector matters for matching, so the scale can be thrown away.
Int8List quantize(List<double> v) {
  var peak = 0.0;
  for (final x in v) {
    peak = max(peak, x.abs());
  }
  final out = Int8List(v.length);
  if (peak == 0) return out;
  for (var i = 0; i < v.length; i++) {
    out[i] = (v[i] / peak * 127).round();
  }
  return out;
}

class Memory {
  Memory({
    required this.id,
    required this.title,
    required this.note,
    required this.photo,
    required this.created,
    required this.signatures,
    this.remindAt,
  });
  final String id;
  String title;

  /// Optional. Some things only need a name.
  String note;

  /// Optional alarm: Andy notifies you about this thing at this time.
  DateTime? remindAt;

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
        'remindAt': remindAt?.toIso8601String(),
        'signatures': signatures.map((s) => s.toJson()).toList(),
      };

  static Memory fromJson(Map<String, dynamic> j) => Memory(
        id: j['id'],
        title: j['title'],
        note: j['note'] ?? '',
        remindAt: j['remindAt'] == null ? null : DateTime.parse(j['remindAt']),
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

double _cosine(Int8List a, Int8List b) {
  if (a.length != b.length) return 0;
  var dot = 0, na = 0, nb = 0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return na == 0 || nb == 0 ? 0 : dot / sqrt(na * nb);
}

/// Best agreement between any zoom level of one photo and any of the other.
double _lookScore(List<Int8List> a, List<Int8List> b) {
  var best = 0.0;
  for (final x in a) {
    for (final y in b) {
      best = max(best, _cosine(x, y));
    }
  }
  return best;
}

bool _hasText(Signature s) => s.words.length >= 2;

double _textScore(Signature a, Signature b) =>
    a.words.intersection(b.words).length / min(a.words.length, b.words.length);

/// Score at which Andy is confident enough to pop the memory up unasked.
const sureAt = 0.56;

/// Score at which Andy offers it as "this could be...".
const maybeAt = 0.36;

/// How alike two sightings are. Comparable against [sureAt] and [maybeAt].
///
/// The visual fingerprint carries most of the weight. Printed words then
/// push the score up when they agree and down when they clash, which is what
/// separates two books of the same size and colour. In a simulation with
/// objects shown at 0.3x to 1.3x size under different light, the same object
/// scored 0.58 or more and different objects 0.43 or less.
double similarity(Signature a, Signature b) {
  final color = _colorScore(a.colors, b.colors);
  if (a.embeds.isEmpty || b.embeds.isEmpty) return _legacySimilarity(a, b);
  var score = _lookScore(a.embeds, b.embeds) + 0.06 * (color - 0.5);
  if (_hasText(a) && _hasText(b)) {
    final text = _textScore(a, b);
    score += 0.28 * (text - 0.35);
    // Readable words on both that do not overlap at all: however alike the
    // two look, never announce it. Offer it as a "could be" at most.
    if (text < 0.2) score = min(score, sureAt - 0.01);
  }
  return score;
}

/// Matching without the neural fingerprint: words, kind of thing, colours.
/// Rescaled so the same [sureAt] and [maybeAt] bars apply.
double _legacySimilarity(Signature a, Signature b) {
  final label = _labelScore(a.labels, b.labels);
  final color = _colorScore(a.colors, b.colors);
  if (_hasText(a) && _hasText(b)) {
    final raw = 0.65 * _textScore(a, b) + 0.15 * label + 0.20 * color;
    return raw + (sureAt - 0.55);
  }
  final look = 0.45 * label + 0.55 * color;
  final raw = _hasText(a) != _hasText(b) ? look * 0.85 : look;
  return raw + (sureAt - 0.72);
}

class MemoryMatch {
  MemoryMatch(this.memory, this.score);
  final Memory memory;
  final double score;

  bool get sure => score >= sureAt;

  /// Rough confidence for display, 0..100.
  int get percent =>
      (50 + (score - maybeAt) / (0.85 - maybeAt) * 49).clamp(50, 99).round();
}

/// Saved memories this sighting might belong to, most likely first.
/// Includes weaker "could be" candidates; check [MemoryMatch.sure].
List<MemoryMatch> recognise(List<Memory> memories, Signature seen,
    {int limit = 3}) {
  final out = <MemoryMatch>[];
  for (final m in memories) {
    var best = -1.0;
    for (final s in m.signatures) {
      best = max(best, similarity(seen, s));
    }
    if (best >= maybeAt) out.add(MemoryMatch(m, best));
  }
  out.sort((a, b) => b.score.compareTo(a.score));
  return out.take(limit).toList();
}

/// True when the top candidate is strong and clearly ahead of the next, so
/// Andy can show it without asking.
bool isClearWinner(List<MemoryMatch> found) =>
    found.isNotEmpty &&
    found.first.sure &&
    (found.length == 1 || found[0].score - found[1].score >= 0.06);
