import 'package:material_ui/material_ui.dart';

import 'reminders.dart';
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
  final state = AppState()..onChanged = reminders.sync;
  runApp(AndyApp(state: state));
  await Future.wait([state.load(), reminders.init()]);
  // Refresh the week of reminders on every launch.
  reminders.sync(state);
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
          return MaterialApp(
            title: 'Andy',
            debugShowCheckedModeBanner: false,
            theme: andyTheme(Brightness.light),
            darkTheme: andyTheme(Brightness.dark),
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
            TodayScreen(onGo: _go),
            const FoodScreen(),
            const MoveScreen(),
            const PeopleScreen(),
            const MeScreen(),
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
