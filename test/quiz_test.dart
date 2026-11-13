import 'dart:math';

import 'package:andy/alarms.dart';
import 'package:andy/quiz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every generated question is well formed', () {
    final kinds = <String>{};
    for (var seed = 0; seed < 3000; seed++) {
      final q = randomQuiz(Random(seed));
      kinds.add(q.kind);
      expect(q.options.length, 4, reason: q.prompt);
      expect(q.options.toSet().length, 4, reason: '${q.prompt} ${q.options}');
      expect(q.answer, inInclusiveRange(0, 3));
      expect(q.prompt.trim(), isNotEmpty);
    }
    expect(kinds.length, greaterThanOrEqualTo(7));
  });

  test('arithmetic answers respect the order of operations', () {
    final ask = RegExp(r'^(\d+) \+ (\d+) × (\d+) = \?$');
    var checked = 0;
    for (var seed = 0; seed < 3000; seed++) {
      final q = randomQuiz(Random(seed));
      final m = ask.firstMatch(q.prompt);
      if (m == null) continue;
      final n = [1, 2, 3].map((i) => int.parse(m.group(i)!)).toList();
      expect(q.options[q.answer], '${n[0] + n[1] * n[2]}');
      checked++;
    }
    expect(checked, greaterThan(20));
  });

  test('constant-step sequences have the right next term', () {
    var checked = 0;
    for (var seed = 0; seed < 3000; seed++) {
      final q = randomQuiz(Random(seed));
      if (q.kind != 'Sequence') continue;
      final n = RegExp(r'-?\d+')
          .allMatches(q.prompt.split('\n').last)
          .map((m) => int.parse(m.group(0)!))
          .toList();
      final steps = [for (var i = 1; i < n.length; i++) n[i] - n[i - 1]];
      if (steps.toSet().length != 1) continue;
      expect(q.options[q.answer], '${n.last + steps.first}', reason: q.prompt);
      checked++;
    }
    expect(checked, greaterThan(20));
  });

  test('does not repeat the kind it is told to avoid', () {
    final r = Random(4);
    var last = randomQuiz(r);
    for (var i = 0; i < 200; i++) {
      final q = randomQuiz(r, not: last.kind);
      expect(q.kind, isNot(last.kind));
      last = q;
    }
  });

  test('an alarm picks today if the time is ahead, otherwise tomorrow', () {
    final a = WakeAlarm(id: 1000, hour: 6, minute: 30);
    expect(a.next(DateTime(2026, 11, 13, 5)), DateTime(2026, 11, 13, 6, 30));
    expect(a.next(DateTime(2026, 11, 13, 6, 30)), DateTime(2026, 11, 14, 6, 30));
    expect(a.next(DateTime(2026, 12, 31, 23)), DateTime(2027, 1, 1, 6, 30));
    expect(untilText(DateTime(2026, 11, 14, 6, 30), DateTime(2026, 11, 13, 23)),
        'in 7 h 30 min');
    expect(WakeAlarm.fromJson(a.toJson()).timeText, '06:30');
  });
}
