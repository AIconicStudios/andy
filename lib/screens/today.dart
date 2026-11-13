import 'package:material_ui/material_ui.dart';

import '../andy_brain.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'alarms.dart';
import '../dictionary.dart' show dictionary;
import '../hangman.dart';
import 'dictionary.dart';
import 'hangman.dart';
import 'lens.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.onGo});
  final ValueChanged<int> onGo;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  String _worth = worthForToday();

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final nudges = nudgesFor(s);
    final scores = [s.fuelScore, s.moveScore, s.peopleScore, s.selfScore];
    const labels = ['Fuel', 'Move', 'People', 'Me'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        Row(
          children: [
            const AndyMark(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${greeting()},',
                      style: t.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  Text(s.name, style: t.textTheme.headlineSmall),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Memory lens',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LensScreen())),
              icon: const Icon(Icons.center_focus_strong_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Worth reminder: the first thing Andy says, every day.
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AndyColors.gradient,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('REMEMBER',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...previous, ?current],
                ),
                child: Text(
                  _worth,
                  key: ValueKey(_worth),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.3,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _worth = randomWorth(not: _worth)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('I need another'),
                ),
              ),
            ],
          ),
        ),

        const WordOfTheDayCard(),

        const _PuzzleCard(),

        const SectionTitle('Your day'),
        Panel(
          child: Column(
            children: [
              Row(
                children: [
                  Rings(
                    values: scores,
                    colors: AndyColors.quarters,
                    size: 150,
                    stroke: 11,
                    gap: 4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${s.lifeScore}',
                            style: t.textTheme.headlineMedium),
                        Text('of 100',
                            style: t.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = 0; i < 4; i++)
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => widget.onGo(i + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 7, horizontal: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: AndyColors.quarters[i],
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(labels[i],
                                          style: t.textTheme.bodyLarge)),
                                  Text('${(scores[i] * 100).round()}%',
                                      style: t.textTheme.titleMedium?.copyWith(
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ])),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(verdict(s.lifeScore),
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),

        const SectionTitle('Tools'),
        Panel(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LensScreen())),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AndyColors.brand.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.center_focus_strong_rounded,
                        color: AndyColors.brand),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Point me at something',
                            style: t.textTheme.titleMedium),
                        Text(
                          s.memories.isEmpty
                              ? 'A book, your TV, a gift. Tell me what it means and I will remind you next time.'
                              : '${s.memories.length} ${s.memories.length == 1 ? 'memory' : 'memories'} saved. Point again to bring one back.',
                          style: t.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Panel(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AlarmsScreen())),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AndyColors.fuel.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.alarm_rounded,
                        color: AndyColors.fuel),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Brain alarm', style: t.textTheme.titleMedium),
                        Text(
                          s.alarms.where((a) => a.enabled).isEmpty
                              ? 'An alarm that only stops when you solve 5 questions.'
                              : 'Next: ${(s.alarms.where((a) => a.enabled).toList()..sort((a, b) => a.next(DateTime.now()).compareTo(b.next(DateTime.now())))).first.timeText}. Solve 5 questions to stop it.',
                          style: t.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Panel(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DictionaryScreen())),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AndyColors.people.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: AndyColors.people),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dictionary', style: t.textTheme.titleMedium),
                        Text(
                          s.savedWords.isEmpty
                              ? 'Look up any word, offline. Bookmark the ones worth keeping.'
                              : '${s.savedWords.length} ${s.savedWords.length == 1 ? 'word' : 'words'} saved. Look up any word, offline.',
                          style: t.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),

        SectionTitle(nudges.isEmpty ? 'Andy says' : 'Andy says, handle these'),
        if (nudges.isEmpty)
          const EmptyHint('🙌',
              'Nothing to chase. You are on top of your life right now. Enjoy it.')
        else
          for (final n in nudges)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => widget.onGo(n.tab),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: n.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(n.icon, color: n.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Text(n.text,
                                style: t.textTheme.bodyMedium
                                    ?.copyWith(height: 1.35))),
                        Icon(Icons.chevron_right_rounded,
                            color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Entry to the daily fill-in-the-blanks puzzle, with today's status.
class _PuzzleCard extends StatelessWidget {
  const _PuzzleCard();

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final puzzle = dailyPuzzle(
        dictionary, DateTime.now(), s.puzzleGuessesToday,
        level: s.puzzleLevel);
    if (puzzle == null) return const SizedBox.shrink();
    final g = puzzle.game;
    final streak = s.puzzleStreakNow;
    final status = g.won
        ? 'Solved. ${streak > 1 ? '$streak days in a row.' : 'Come back tomorrow.'}'
        : g.lost
            ? 'Missed today. The word was "${g.word}". New one tomorrow.'
            : g.guesses.isEmpty
                ? '${puzzleLevels[s.puzzleLevel].$1} mode. Three wrong letters and it is over.'
                : 'In progress. ${g.livesLeft} ${g.livesLeft == 1 ? 'life' : 'lives'} left.';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Panel(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HangmanScreen())),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AndyColors.self.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                      g.won
                          ? Icons.check_circle_rounded
                          : Icons.extension_rounded,
                      color: AndyColors.self),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily puzzle', style: t.textTheme.titleMedium),
                      Text(status,
                          style: t.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant, height: 1.3)),
                    ],
                  ),
                ),
                if (streak > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('$streak 🔥', style: t.textTheme.titleMedium),
                  ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
