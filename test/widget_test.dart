import 'package:andy/main.dart';
import 'package:andy/memories.dart';
import 'package:andy/reminders.dart';
import 'package:andy/state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('onboarding leads to the Today screen', (tester) async {
    final state = AppState();
    await state.load();
    await tester.pumpWidget(AndyApp(state: state));
    expect(find.textContaining('Keep it handy'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Sam');
    await tester.ensureVisible(find.text('Let\'s go'));
    await tester.tap(find.text('Let\'s go'));
    await tester.pumpAndSettle();

    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('REMEMBER'), findsOneWidget);
  });

  test('life score rewards logging food, moving, people and self care',
      () async {
    final s = AppState();
    await s.load();
    s.finishOnboarding('Sam', 2000);
    expect(s.lifeScore, 0);

    s.addFood('Lunch', 1800, 'Lunch');
    expect(s.fuelScore, 1);

    s.addWorkout('Run', 150, 1);
    expect(s.moveScore, 1);
    expect(s.streak, 1);

    s.addPerson('Ama', 7);
    expect(s.peopleScore, 0);
    s.markContacted(s.people.first.id);
    expect(s.peopleScore, 1);

    s.setMood(4);
    s.addWater(8);
    for (final h in s.habits) {
      s.toggleHabit(h.id);
    }
    expect(s.lifeScore, 100);
  });

  test('state survives a restart', () async {
    final a = AppState();
    await a.load();
    a.finishOnboarding('Sam', 2000);
    a.addFood('Banana', 105, 'Snack');
    await Future<void>.delayed(Duration.zero);

    final b = AppState();
    await b.load();
    expect(b.onboarded, true);
    expect(b.kcalOn(DateTime.now()), 105);
  });

  group('reminder plan', () {
    late AppState s;
    final morning = DateTime(2026, 11, 12, 7);

    setUp(() async {
      s = AppState();
      await s.load();
      s.finishOnboarding('Sam', 2000);
    });

    List<String> titlesToday(DateTime now) => planReminders(s, now)
        .where((r) => r.when.day == now.day)
        .map((r) => r.title)
        .toList();

    test('covers a week, stays in the future and under the iOS limit', () {
      s.addPerson('Ama', 7);
      final plan = planReminders(s, morning);
      expect(plan.every((r) => r.when.isAfter(morning)), true);
      expect(plan.map((r) => r.id).toSet().length, plan.length);
      expect(plan.length, lessThanOrEqualTo(64));
      expect(plan.where((r) => r.title == 'Lunch check').length, 7);
      expect(plan.any((r) => r.title == 'Reach out to Ama'), true);
    });

    test('drops today\'s nudge once the thing is done', () {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 0, 1);
      expect(titlesToday(start), contains('Move your body'));
      s.addWorkout('Walk', 20, 0);
      expect(titlesToday(start), isNot(contains('Move your body')));
    });

    test('person reminder moves to their next due date after contact', () {
      s.addPerson('Ama', 7);
      s.markContacted(s.people.first.id);
      final now = DateTime.now();
      final r = planReminders(s, now)
          .firstWhere((r) => r.title == 'Reach out to Ama');
      final days = DateTime(r.when.year, r.when.month, r.when.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      expect(days, 8);
    });

    test('respects the master switch and category switches', () {
      s.setReminderCategory('food', false);
      expect(planReminders(s, morning).any((r) => r.title == 'Lunch check'),
          false);
      s.setReminders(false);
      expect(planReminders(s, morning), isEmpty);
    });

    test('an alarm on a memory fires exactly, even with nudges off', () {
      final at = morning.add(const Duration(days: 30, hours: 3));
      s.addMemory(Memory(
          id: 'm',
          title: 'Passport',
          note: '',
          photo: '',
          created: morning,
          signatures: [],
          remindAt: at));
      s.setReminders(false);
      final plan = planReminders(s, morning);
      expect(plan.single.title, 'Passport');
      expect(plan.single.when, at);
      expect(plan.single.exact, true);
      s.setReminders(true);
      expect(planReminders(s, morning).length, lessThanOrEqualTo(maxPending));
    });
  });
  test('a one-off alarm switches off once beaten; a daily one stays on',
      () async {
    final s = AppState();
    await s.load();
    s.saveAlarm(hour: 6, minute: 0, daily: true);
    s.saveAlarm(hour: 7, minute: 15, daily: false, label: 'Flight');
    expect(s.alarms.map((a) => a.id).toSet().length, 2);
    for (final a in [...s.alarms]) {
      s.alarmBeaten(a.id);
    }
    expect(s.alarms.firstWhere((a) => a.daily).enabled, true);
    expect(s.alarms.firstWhere((a) => !a.daily).enabled, false);
    await Future<void>.delayed(Duration.zero);

    final again = AppState();
    await again.load();
    expect(again.alarms.length, 2);
    expect(again.alarms.firstWhere((a) => !a.daily).label, 'Flight');
  });
}
