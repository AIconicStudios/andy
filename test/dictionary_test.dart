import 'dart:io';
import 'dart:math';

import 'package:andy/dictionary.dart';
import 'package:andy/quiz.dart';
import 'package:andy/reminders.dart';
import 'package:andy/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The real bundled data, so a bad line or a missing word fails here.
  final dict = Dictionary.fromText(
    File('assets/dictionary.tsv').readAsStringSync(),
    File('assets/words_of_the_day.txt').readAsStringSync(),
  );

  test('looks words up, whatever the case', () {
    expect(dict.size, greaterThan(30000));
    final e = dict.lookup('  Serene ')!;
    expect(e.word, 'serene');
    expect(e.senses.first.pos, 'adjective');
    expect(e.senses.first.definition, isNotEmpty);
    expect(dict.lookup('zzzzqq'), isNull);
  });

  test('searches by prefix in alphabetical order', () {
    final found = dict.search('resil');
    expect(found, contains('resilient'));
    expect(found.every((w) => w.startsWith('resil')), true);
    expect(found, [...found]..sort());
    expect(dict.search(''), isEmpty);
    expect(dict.search('qqqq'), isEmpty);
  });

  test('finds the plain form of an inflected word', () {
    expect(dict.baseForm('running'), 'run');
    expect(dict.baseForm('boxes'), 'box');
    expect(dict.baseForm('studies'), 'study');
    expect(dict.baseForm('qqqqing'), isNull);
  });

  test('every word of the day has a meaning and an example', () {
    final seen = <String>{};
    final start = DateTime(2026, 11, 13);
    for (var i = 0; i < 567; i++) {
      final e = dict.wordOfTheDay(start.add(Duration(days: i)))!;
      expect(e.senses.first.definition, isNotEmpty, reason: e.word);
      expect(e.senses.first.example, isNotEmpty, reason: e.word);
      seen.add(e.word);
    }
    expect(seen.length, 567); // no repeats until the list runs out
    expect(dict.wordOfTheDay(start)!.word,
        dict.wordOfTheDay(DateTime(2026, 11, 13, 23, 59))!.word);
  });

  test('the word of the day is sent as a 9:30 notification', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load();
    s.finishOnboarding('Sam', 2000);
    final now = DateTime(2026, 11, 13, 7);
    final plan = planReminders(s, now, words: dict);
    final word = dict.wordOfTheDay(now)!.word;
    final r = plan.firstWhere((r) => r.title == 'Word of the day: $word');
    expect(r.when, DateTime(2026, 11, 13, 9, 30));
    expect(plan.where((r) => r.title.startsWith('Word of the day')).length, 7);
    expect(plan.length, lessThanOrEqualTo(maxPending));
    s.setReminderCategory('word', false);
    expect(
        planReminders(s, now, words: dict)
            .any((r) => r.title.startsWith('Word of the day')),
        false);
  });

  test('vocabulary questions ask for the word that fits a meaning', () {
    final vocab = dict.vocabulary;
    var asked = 0;
    for (var seed = 0; seed < 400; seed++) {
      final q = randomQuiz(Random(seed), vocab: vocab);
      expect(q.options.toSet().length, 4);
      if (q.kind != 'Vocabulary') continue;
      final right = q.options[q.answer];
      expect(q.prompt, contains(dict.lookup(right)!.senses.first.definition));
      asked++;
    }
    expect(asked, greaterThan(10));
  });
}
