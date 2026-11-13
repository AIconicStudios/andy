import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Sense {
  Sense(this.pos, this.definition, this.example);

  /// noun, verb, adjective or adverb.
  final String pos;
  final String definition;

  /// May be empty.
  final String example;
}

class Entry {
  Entry(this.word, this.senses);
  final String word;

  /// Most common meaning first.
  final List<Sense> senses;
}

/// The dictionary inside Andy: about 32,000 English words with meanings and
/// examples, bundled with the app so it works with no connection.
///
/// Definitions come from WordNet 3.0 (Princeton University), which is free
/// to use and redistribute. See third_party/WORDNET_LICENSE.
class Dictionary {
  Dictionary();

  /// Builds from the raw asset text. One word per line, sorted:
  /// `word<TAB>pos|definition|example<TAB>pos|definition|example...`
  Dictionary.fromText(String entries, String daily) {
    _fill(entries, daily);
  }

  List<String> _lines = const [];
  List<String> _words = const [];
  List<String> _daily = const [];

  bool get loaded => _words.isNotEmpty;
  int get size => _words.length;

  Future<void> load() async {
    if (loaded) return;
    try {
      final texts = await Future.wait([
        rootBundle.loadString('assets/dictionary.tsv'),
        rootBundle.loadString('assets/words_of_the_day.txt'),
      ]);
      _fill(texts[0], texts[1]);
    } catch (_) {
      // Missing asset: the app works without it, minus this feature.
    }
  }

  void _fill(String entries, String daily) {
    _lines = const LineSplitter().convert(entries);
    _words = [for (final l in _lines) l.substring(0, l.indexOf('\t'))];
    _daily = const LineSplitter()
        .convert(daily)
        .where((w) => w.isNotEmpty)
        .toList();
  }

  int _lowerBound(String key) {
    var lo = 0, hi = _words.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_words[mid].compareTo(key) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  Entry? lookup(String word) {
    final key = word.trim().toLowerCase();
    final i = _lowerBound(key);
    if (i >= _words.length || _words[i] != key) return null;
    final parts = _lines[i].split('\t');
    return Entry(key, [
      for (final p in parts.skip(1))
        if (p.split('|') case [final pos, final def, final ex])
          Sense(pos, def, ex)
    ]);
  }

  /// Words starting with [prefix], alphabetical.
  List<String> search(String prefix, {int limit = 50}) {
    final key = prefix.trim().toLowerCase();
    if (key.isEmpty) return const [];
    final out = <String>[];
    for (var i = _lowerBound(key);
        i < _words.length && out.length < limit && _words[i].startsWith(key);
        i++) {
      out.add(_words[i]);
    }
    return out;
  }

  /// The plain form of an inflected word, if the typed one is not listed:
  /// "running" finds "run", "boxes" finds "box".
  String? baseForm(String word) {
    final w = word.trim().toLowerCase();
    final tries = <String>[
      if (w.endsWith('ies')) '${w.substring(0, w.length - 3)}y',
      if (w.endsWith('es')) w.substring(0, w.length - 2),
      if (w.endsWith('s')) w.substring(0, w.length - 1),
      if (w.endsWith('ed')) ...[
        w.substring(0, w.length - 2),
        w.substring(0, w.length - 1),
      ],
      if (w.endsWith('ing')) ...[
        w.substring(0, w.length - 3),
        '${w.substring(0, w.length - 3)}e',
        // running -> run
        if (w.length > 5 && w[w.length - 4] == w[w.length - 5])
          w.substring(0, w.length - 4),
      ],
    ];
    for (final t in tries) {
      if (t.length >= 2 && lookup(t) != null) return t;
    }
    return null;
  }

  /// The word for [day]. Everyone gets the same word on the same date, and
  /// the list runs for about a year and a half before repeating.
  Entry? wordOfTheDay(DateTime day) {
    if (_daily.isEmpty) return null;
    final n =
        DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    return lookup(_daily[n % _daily.length]);
  }

  /// The answer to the daily fill-in-the-blanks puzzle for [day]: taken
  /// from half a list away, so it is months from being the word of the day.
  Entry? puzzleWord(DateTime day) {
    if (_daily.isEmpty) return null;
    final n =
        DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    return lookup(_daily[(n + _daily.length ~/ 2) % _daily.length]);
  }

  /// Word and meaning pairs for vocabulary quiz questions.
  List<(String, String)> get vocabulary => [
        for (final w in _daily)
          if (lookup(w) case final e? when e.senses.isNotEmpty)
            (w, e.senses.first.definition)
      ];
}

final dictionary = Dictionary();
