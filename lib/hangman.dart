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

/// About a third of the word's distinct letters, filled in for free. With
/// only three misses allowed, a bare row of blanks would be a coin toss.
Set<String> givenLetters(String word, DateTime day) {
  final distinct = word.split('').toSet().toList()..sort();
  distinct.shuffle(Random(_dayNumber(day)));
  return distinct.take(max(1, distinct.length ~/ 3)).toSet();
}

/// Today's puzzle: same word for everyone on the same date, and never the
/// word of the day (which is on show on the Today tab).
({Entry entry, Hangman game})? dailyPuzzle(
    Dictionary dict, DateTime day, String guesses) {
  final entry = dict.puzzleWord(day);
  if (entry == null) return null;
  return (
    entry: entry,
    game: Hangman(entry.word, givenLetters(entry.word, day), guesses)
  );
}
