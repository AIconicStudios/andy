import 'dart:math';

import 'dictionary.dart';

/// Wrong guesses allowed before the daily puzzle is lost.
const maxMisses = 3;

/// One game of fill-in-the-blanks. Immutable: every guess makes a new game,
/// so the whole state is just the string of letters tried so far.
class Hangman {
  Hangman(this.word, this.given, [String guesses = ''])
      : guesses = guesses.toLowerCase().split('').toSet().join();

  /// The answer, lower case a to z.
  final String word;

  /// Letters filled in for free at the start.
  final Set<String> given;

  /// Letters the player has tried, in order, without repeats.
  final String guesses;

  bool tried(String letter) => guesses.contains(letter) || given.contains(letter);

  bool shows(String letter) => given.contains(letter) || guesses.contains(letter);

  /// The word as the player sees it, with null for each blank.
  List<String?> get slots =>
      [for (final c in word.split('')) shows(c) ? c : null];

  int get misses => guesses.split('').where((c) => !word.contains(c)).length;
  int get livesLeft => max(0, maxMisses - misses);

  bool get lost => misses >= maxMisses;
  bool get won => !lost && !slots.contains(null);
  bool get over => won || lost;

  Hangman guess(String letter) {
    final c = letter.toLowerCase();
    if (over || c.length != 1 || tried(c)) return this;
    return Hangman(word, given, guesses + c);
  }
}

int _dayNumber(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

const puzzleLevels = [
  ('Gentle', 'A third of the letters are filled in'),
  ('Hard', 'One letter is filled in'),
  ('Brutal', 'Nothing filled in. Just the clue and three lives'),
];

/// Letters filled in for free at [level]: a third of the distinct letters
/// (gentle), a single one (hard), or none (brutal). Which letters is fixed
/// for the day.
Set<String> givenLetters(String word, DateTime day, [int level = 1]) {
  final distinct = word.split('').toSet().toList()..sort();
  distinct.shuffle(Random(_dayNumber(day)));
  final count = switch (level) {
    0 => max(1, distinct.length ~/ 3),
    1 => 1,
    _ => 0,
  };
  return distinct.take(count).toSet();
}

const _mask = '•••';

bool _leaks(String token, String answer) {
  final t = token.toLowerCase();
  if (t.length < 4) return false;
  // Same opening four letters means the same root: mercy / merciless.
  return answer.startsWith(t.substring(0, 4)) ||
      (answer.length >= 5 && t.contains(answer.substring(0, 5)));
}

/// A definition with any word that gives the answer away blanked out.
String _hide(String text, String answer) => text.replaceAllMapped(
    RegExp(r'[A-Za-z]+'), (m) => _leaks(m[0]!, answer) ? _mask : m[0]!);

/// The clue for a puzzle: the meaning that leaks least, with any relatives
/// of the answer blanked out. No example sentence, which would contain it.
Sense clueFor(Entry entry) {
  Sense? best;
  var bestHidden = 1 << 30;
  for (final s in entry.senses) {
    final hidden = _mask.allMatches(_hide(s.definition, entry.word)).length;
    if (hidden < bestHidden) {
      best = s;
      bestHidden = hidden;
    }
  }
  return Sense(best!.pos, _hide(best.definition, entry.word), '');
}

/// Today's puzzle: same word for everyone on the same date, and never the
/// word of the day (which is on show on the Today tab).
({Entry entry, Hangman game, Sense clue})? dailyPuzzle(
    Dictionary dict, DateTime day, String guesses,
    {int level = 1}) {
  final entry = dict.puzzleWord(day);
  if (entry == null) return null;
  return (
    entry: entry,
    game: Hangman(entry.word, givenLetters(entry.word, day, level), guesses),
    clue: clueFor(entry),
  );
}
