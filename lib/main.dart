import 'package:material_ui/material_ui.dart';

import 'alarms.dart';
import 'dictionary.dart';
import 'steps.dart';
import 'reminders.dart';
import 'screens/alarms.dart';
import 'screens/food.dart';
import 'screens/me.dart';
import 'screens/move.dart';
import 'screens/onboarding.dart';
import 'screens/people.dart';
import 'screens/today.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState()
    ..onChanged = (s) {
      reminders.sync(s);
      alarmService.sync(s);
    };
  runApp(AndyApp(state: state));
  await Future.wait([
    state.load(),
    reminders.init(),
    alarmService.init(),
    dictionary.load(),
  ]);
  state.refresh(); // the dictionary is in: show the word of the day
  stepService.start(state); // asks for permission on first run
  // Refresh the week of reminders and the alarms on every launch.
  reminders.sync(state);
  await alarmService.sync(state);
  alarmService.listen(_showRinging);
}

final _navigator = GlobalKey<NavigatorState>();
final _ringing = <int>{};

/// Puts the quiz in front of whatever screen is open when an alarm goes off.
void _showRinging(int id) {
  final nav = _navigator.currentState;
  if (nav == null || !_ringing.add(id)) return;
  nav
      .push(MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => AlarmRingScreen(alarmId: id)))
      .whenComplete(() => _ringing.remove(id));
}

class AndyApp extends StatelessWidget {
  const AndyApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AndyScope(
      state: state,
      child: Builder(
        builder: (context) {
          final s = AndyScope.of(context);
          // Apply the chosen colours before anything is built with them.
          AndyColors.palette = paletteById(s.themeName);
          return MaterialApp(
            title: 'Andy',
            navigatorKey: _navigator,
            debugShowCheckedModeBanner: false,
            theme: andyTheme(Brightness.light),
            darkTheme: andyTheme(Brightness.dark, black: s.blackDark),
            themeMode: s.themeMode,
            home: !s.loaded
                ? const Scaffold(body: SizedBox())
                : s.onboarded
                    ? const Shell()
                    : const Onboarding(),
          );
        },
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final overdue = s.overduePeople.length;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            // Hidden tabs keep their state but stop animating.
            for (final (i, tab) in <Widget>[
              TodayScreen(onGo: _go),
              const FoodScreen(),
              const MoveScreen(),
              const PeopleScreen(),
              const MeScreen(),
            ].indexed)
              TickerMode(enabled: i == _tab, child: tab),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny_rounded),
              label: 'Today'),
          const NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant_rounded),
              label: 'Food'),
          const NavigationDestination(
              icon: Icon(Icons.directions_run_outlined),
              selectedIcon: Icon(Icons.directions_run_rounded),
              label: 'Move'),
          NavigationDestination(
              icon: Badge(
                isLabelVisible: overdue > 0,
                label: Text('$overdue'),
                child: const Icon(Icons.people_alt_outlined),
              ),
              selectedIcon: const Icon(Icons.people_alt_rounded),
              label: 'People'),
          const NavigationDestination(
              icon: Icon(Icons.favorite_outline_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'Me'),
        ],
      ),
    );
  }
}
