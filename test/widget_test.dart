import 'package:andy/main.dart';
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
}
