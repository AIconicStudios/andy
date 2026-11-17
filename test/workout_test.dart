import 'package:andy/exercises.dart';
import 'package:andy/models.dart';
import 'package:andy/reminders.dart';
import 'package:andy/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SetLog log(String e, String day, int amount, [Effort f = Effort.hard]) =>
    SetLog(exercise: e, day: day, amount: amount, effort: f);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every exercise has a demo and its ladders point at real exercises', () {
    for (final e in exercises.values) {
      expect(e.demo.frames.length, greaterThanOrEqualTo(2), reason: e.id);
      expect(e.lo, lessThan(e.hi));
      expect(e.steps, isNotEmpty);
      for (final id in [e.harder, e.easier]) {
        if (id != null) expect(exercises.containsKey(id), true, reason: id);
      }
      if (e.harder == null) expect(e.harderTip, isNotEmpty, reason: e.id);
    }
    for (final ladder in slotLadders.values) {
      expect(ladder.every(exercises.containsKey), true);
    }
    for (final r in routines) {
      for (final (slot, sets) in r.blocks) {
        expect(slotLadders[slot], contains(defaultVariants[slot]));
        expect(sets, inInclusiveRange(1, 5));
      }
    }
  });

  test('demos keep planted hands still while the body moves', () {
    final d = exercises['pushup']!.demo;
    final top = d.at(0), bottom = d.at(0.5);
    expect(top.hand, bottom.hand);
    expect(top.hip.dy, lessThan(bottom.hip.dy)); // body goes down
    expect(d.at(1).hip, top.hip); // and comes back up
  });

  group('set feedback', () {
    final pushup = exercises['pushup']!; // 8-20 reps
    test('in range with 1-2 left is the sweet spot', () {
      expect(judgeSet(pushup, 12, Effort.hard).tone, Tone.great);
      expect(judgeSet(pushup, 12, Effort.easy).tone, Tone.push);
      expect(judgeSet(pushup, 12, Effort.max).tone, Tone.good);
    });
    test('above the range suggests the harder variation', () {
      final v = judgeSet(pushup, 22, Effort.hard);
      expect(v.detail, contains('Feet-elevated push-up'));
    });
    test('below the range suggests the easier variation', () {
      final v = judgeSet(pushup, 4, Effort.max);
      expect(v.tone, Tone.ease);
      expect(v.detail, contains('Incline push-up'));
      expect(judgeSet(pushup, 4, Effort.easy).tone, Tone.push);
    });
    test('compares with the same set last time', () {
      expect(judgeSet(pushup, 12, Effort.hard, previous: 10).detail,
          contains('2 more than last time'));
    });
  });

  group('recommendations', () {
    final pushup = exercises['pushup']!;
    test('all sets at the top: level up', () {
      final a = recommend(pushup,
          [log('pushup', 'd', 20), log('pushup', 'd', 21), log('pushup', 'd', 20)], []);
      expect(a.switchTo, 'elevated_pushup');
    });
    test('all sets short: step down', () {
      final a = recommend(pushup, [log('pushup', 'd', 5), log('pushup', 'd', 4)], []);
      expect(a.switchTo, 'incline_pushup');
    });
    test('progress against last session', () {
      final last = [log('pushup', 'x', 10), log('pushup', 'x', 9)];
      expect(recommend(pushup, [log('pushup', 'd', 12), log('pushup', 'd', 10)], last).text,
          contains('Up 3'));
      expect(recommend(pushup, [log('pushup', 'd', 10), log('pushup', 'd', 9)], last).text,
          contains('Same total'));
      expect(recommend(pushup, [log('pushup', 'd', 10)], []).text,
          contains('number to beat'));
    });
    test('top of the range with no harder exercise gives a tip', () {
      final plank = exercises['plank']!;
      final a = recommend(plank, [log('plank', 'd', 60), log('plank', 'd', 65)], []);
      expect(a.switchTo, isNull);
      expect(a.text, contains(plank.harderTip));
    });
  });

  test('logged sets, last session and switching variations', () async {
    final s = AppState();
    await s.load();
    s.setLogs.addAll([log('pushup', '2026-01-01', 9), log('pushup', '2026-01-01', 8)]);
    s.logSet('pushup', 12, Effort.hard);
    expect(s.setsToday('pushup').single.amount, 12);
    expect(s.lastSession('pushup').map((l) => l.amount), [9, 8]);
    expect(s.bestSet('pushup'), 12);
    s.undoLastSet('pushup');
    expect(s.setsToday('pushup'), isEmpty);

    s.useInPlan('elevated_pushup');
    expect(s.variants['push'], 'elevated_pushup');
    s.useInPlan('bulgarian_split_squat'); // in two ladders
    expect(s.variants['squat'], 'bulgarian_split_squat');
    expect(s.variants['lunge'], 'bulgarian_split_squat');
  });

  test('routines alternate and a finished workout counts as movement', () async {
    final s = AppState();
    await s.load();
    expect(s.upcomingRoutine.id, 'a');
    s.finishWorkout('a', 31);
    expect(s.trainedToday, true);
    expect(s.upcomingRoutine.id, 'a'); // today's stays today's
    expect(nextRoutine('a').id, 'b');
    expect(s.workouts.last.type, 'Bodyweight');
    expect(s.minutesOn(DateTime.now()), 31);
    expect(workoutType('Bodyweight').emoji, '💪');
  });

  group('steps', () {
    test('only the difference between readings is counted', () async {
      final s = AppState();
      await s.load();
      final day = DateTime(2026, 11, 17, 9);
      s.recordStepCounter(52000, now: day); // first reading: a baseline
      expect(s.steps[dk(day)], isNull);
      s.recordStepCounter(52400, now: day);
      s.recordStepCounter(53000, now: day);
      expect(s.steps[dk(day)], 1000);
      // Phone restarted: the counter starts again from zero.
      s.recordStepCounter(300, now: day);
      expect(s.steps[dk(day)], 1300);
      // Next morning.
      final next = DateTime(2026, 11, 18, 8);
      s.recordStepCounter(800, now: next);
      expect(s.steps[dk(next)], 500);
      expect(s.steps[dk(day)], 1300);
    });

    test('steps add to calories burned and to the move score', () async {
      final s = AppState();
      await s.load();
      final now = DateTime.now();
      expect(s.moveScore, 0);
      s.steps[dk(now)] = s.stepGoal;
      expect(s.moveScore, closeTo(0.3, 1e-9));
      expect(s.burnedOn(now), s.stepKcal(s.stepGoal));
      expect(s.stepKcal(10000), (10000 * s.weightKg * 0.0005).round());
    });
  });

  group('workout reminders', () {
    test('on training days, routines in turn, skipped once done', () async {
      final s = AppState();
      await s.load();
      s.finishOnboarding('Sam', 2000);
      s.setTrainingPlan(days: {1, 2, 3, 4, 5, 6, 7}, hour: 18, minute: 30);
      final morning = DateTime.now().copyWith(hour: 7, minute: 0);
      var plan = planReminders(s, morning)
          .where((r) => r.title.startsWith('Workout day'))
          .toList()
        ..sort((a, b) => a.when.compareTo(b.when));
      expect(plan.length, 7);
      expect(plan.first.when.hour, 18);
      expect(plan.first.when.minute, 30);
      expect(plan[0].title, 'Workout day: Push & legs');
      expect(plan[1].title, 'Workout day: Pull & core');

      s.finishWorkout('a', 30);
      plan = planReminders(s, morning)
          .where((r) => r.title.startsWith('Workout day'))
          .toList()
        ..sort((a, b) => a.when.compareTo(b.when));
      expect(plan.length, 6);
      expect(plan.first.title, 'Workout day: Pull & core');

      s.setReminderCategory('workout', false);
      expect(planReminders(s, morning).any((r) => r.title.startsWith('Workout')),
          false);
    });

    test('the come-back message survives the phone limit', () async {
      final s = AppState();
      await s.load();
      s.finishOnboarding('Sam', 2000);
      s.setTrainingPlan(days: {1, 2, 3, 4, 5, 6, 7});
      for (var i = 0; i < 12; i++) {
        s.addPerson('Friend $i', 2);
      }
      final plan = planReminders(s, DateTime.now().copyWith(hour: 6, minute: 0));
      expect(plan.length, lessThanOrEqualTo(maxPending));
      expect(plan.any((r) => r.id == 99), true);
    });
  });
}
