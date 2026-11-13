import 'dart:io';

import 'package:andy/dictionary.dart';
import 'package:andy/hangman.dart';
import 'package:andy/models.dart';
import 'package:andy/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final dict = Dictionary.fromText(
    File('assets/dictionary.tsv').readAsStringSync(),
    File('assets/words_of_the_day.txt').readAsStringSync(),
  );

  test('right letters fill every matching blank and cost nothing', () {
    var g = Hangman('placid', {'p'});
    expect(g.slots, ['p', null, null, null, null, null]);
    g = g.guess('a').guess('A').guess('p'); // repeats and givens are ignored
    expect(g.slots, ['p', null, 'a', null, null, null]);
    expect(g.misses, 0);
    expect(g.livesLeft, 3);
  });

  test('the third wrong letter loses and further guesses do nothing', () {
    var g = Hangman('placid', {'p'}).guess('x').guess('y');
    expect(g.lost, false);
    expect(g.livesLeft, 1);
    g = g.guess('z');
    expect(g.lost, true);
    expect(g.won, false);
    expect(g.guess('l').guesses, g.guesses);
  });

  test('filling the last blank wins, even after two misses', () {
    var g = Hangman('banana', {'b'}).guess('q').guess('z').guess('a');
    expect(g.over, false);
    g = g.guess('n');
    expect(g.won, true);
    expect(g.lost, false);
  });

  test('every day has a fair puzzle that is not the word of the day', () {
    final start = DateTime(2026, 11, 13);
    for (var i = 0; i < 567; i++) {
      final day = start.add(Duration(days: i));
      final p = dailyPuzzle(dict, day, '')!;
      final g = p.game;
      expect(g.word, isNot(dict.wordOfTheDay(day)!.word));
      expect(RegExp(r'^[a-z]+$').hasMatch(g.word), true);
      expect(g.given.length, 1); // hard is the default
      expect(dailyPuzzle(dict, day, '', level: 2)!.game.given, isEmpty);
      expect(dailyPuzzle(dict, day, '', level: 0)!.game.given.length,
          greaterThanOrEqualTo(1));
      // The clue must not contain the answer or an obvious relative of it.
      final clue = p.clue.definition.toLowerCase();
      expect(clue, isNotEmpty);
      expect(p.clue.example, isEmpty);
      for (final token in RegExp(r'[a-z]+').allMatches(clue)) {
        final w = token[0]!;
        if (w.length < 4) continue;
        expect(g.word.startsWith(w.substring(0, 4)), false,
            reason: '"$w" gives away "${g.word}"');
      }
      expect(g.over, false, reason: 'must not start solved: ${g.word}');
      expect(g.slots.where((c) => c == null).length, greaterThanOrEqualTo(2));
      expect(p.entry.senses.first.definition, isNotEmpty);
    }
    // Stable within a day.
    expect(dailyPuzzle(dict, start, '')!.game.given,
        dailyPuzzle(dict, DateTime(2026, 11, 13, 22), '')!.game.given);
  });

  test('clues blank out relatives of the answer', () {
    final clue = clueFor(dict.lookup('merciless')!);
    expect(clue.definition, isNot(contains('mercy')));
    expect(clue.definition, contains('•••'));
  });

  test('progress is kept for the day and wins build a streak', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load();
    expect(s.puzzleGuessesToday, '');
    s.recordPuzzle('ab', won: false, lost: false);
    expect(s.puzzleGuessesToday, 'ab');
    expect(s.puzzleStreakNow, 0);

    s.recordPuzzle('abc', won: true, lost: false);
    s.recordPuzzle('abc', won: true, lost: false); // counted once
    expect(s.puzzleStreakNow, 1);

    // Pretend that win was yesterday: today's win extends the run.
    s.puzzleLastWin = dk(DateTime.now().subtract(const Duration(days: 1)));
    s.puzzleDay = s.puzzleLastWin;
    expect(s.puzzleGuessesToday, ''); // yesterday's letters are forgotten
    s.recordPuzzle('xy', won: true, lost: false);
    expect(s.puzzleStreakNow, 2);
    expect(s.puzzleBest, 2);

    // A gap of two days kills it; so does losing.
    s.puzzleLastWin = dk(DateTime.now().subtract(const Duration(days: 2)));
    expect(s.puzzleStreakNow, 0);
    s.recordPuzzle('qzx', won: false, lost: true);
    expect(s.puzzleStreak, 0);
    expect(s.puzzleBest, 2);
  });
}
