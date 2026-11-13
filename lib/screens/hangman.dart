import 'package:material_ui/material_ui.dart';

import '../dictionary.dart';
import '../hangman.dart';
import '../reminders.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// The daily fill-in-the-blanks puzzle. One word a day, three misses.
class HangmanScreen extends StatelessWidget {
  const HangmanScreen({super.key});

  static const _rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final puzzle = dailyPuzzle(
        dictionary, DateTime.now(), s.puzzleGuessesToday,
        level: s.puzzleLevel);

    if (puzzle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily puzzle')),
        body: const Padding(
          padding: EdgeInsets.all(18),
          child: EmptyHint('🧩', 'The puzzle needs the dictionary, which could not be loaded.'),
        ),
      );
    }
    final g = puzzle.game;
    final sense = puzzle.entry.senses.first; // full meaning, shown at the end
    final clue = puzzle.clue;
    final saved = s.savedWords.contains(g.word);

    void tap(String letter) {
      final next = g.guess(letter);
      if (identical(next, g)) return;
      s.recordPuzzle(next.guesses, won: next.won, lost: next.lost);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily puzzle'),
        actions: [
          IconButton(
            tooltip: 'Puzzle settings',
            onPressed: () => showAndySheet(context, const _PuzzleSettings()),
            icon: const Icon(Icons.tune_rounded),
          ),
          if (s.puzzleStreakNow > 0)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Center(
                child: Text('${s.puzzleStreakNow} 🔥',
                    style: t.textTheme.titleMedium),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            // Lives
            Semantics(
              label: '${g.livesLeft} of $maxMisses lives left',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < maxMisses; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < g.livesLeft
                            ? Icons.favorite_rounded
                            : Icons.heart_broken_rounded,
                        size: 30,
                        color: i < g.livesLeft
                            ? AndyColors.brand
                            : cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Clue
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CLUE · ${clue.pos.toUpperCase()}',
                      style: t.textTheme.labelSmall?.copyWith(
                          color: AndyColors.self,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text(clue.definition,
                      style: t.textTheme.titleMedium
                          ?.copyWith(height: 1.35, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 26),
            // Blanks
            Semantics(
              label: 'Word: ${g.slots.map((c) => c ?? 'blank').join(' ')}',
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < g.word.length; i++)
                    _Slot(
                      letter: g.slots[i] ?? (g.lost ? g.word[i] : null),
                      missed: g.slots[i] == null && g.lost,
                      given: g.given.contains(g.word[i]),
                      narrow: g.word.length > 9,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            if (!g.over)
              for (final row in _rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final c in row.split(''))
                        _Key(
                          letter: c,
                          state: !g.tried(c)
                              ? _KeyState.open
                              : g.word.contains(c)
                                  ? _KeyState.hit
                                  : _KeyState.miss,
                          onTap: () => tap(c),
                        ),
                    ],
                  ),
                )
            else ...[
              Panel(
                color: (g.won ? AndyColors.self : AndyColors.brand)
                    .withValues(alpha: 0.12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.won
                          ? (g.misses == 0
                              ? 'Flawless. Not one wrong letter.'
                              : 'Solved with ${g.livesLeft} ${g.livesLeft == 1 ? 'life' : 'lives'} to spare.')
                          : 'Out of lives. The word was “${g.word}”.',
                      style: t.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      g.won
                          ? (s.puzzleStreakNow > 1
                              ? '${s.puzzleStreakNow} days in a row. Best: ${s.puzzleBest}.'
                              : 'Do it again tomorrow and a streak starts.')
                          : 'Missing one teaches you more than guessing ten. New word tomorrow.',
                      style: t.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                    ),
                    if (sense.example.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('“${sense.example}”',
                          style: t.textTheme.bodyLarge?.copyWith(
                              fontStyle: FontStyle.italic, height: 1.35)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => s.toggleWord(g.word),
                icon: Icon(saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded),
                label: Text(saved ? 'Saved to my words' : 'Save “${g.word}” to my words'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot(
      {required this.letter,
      required this.missed,
      required this.given,
      required this.narrow});
  final String? letter;
  final bool missed; // revealed only because the game was lost
  final bool given; // filled in for free
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Container(
      width: narrow ? 26 : 32,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              width: 3,
              color: letter == null
                  ? cs.onSurfaceVariant
                  : missed
                      ? cs.error
                      : AndyColors.self),
        ),
      ),
      child: Text(
        (letter ?? '').toUpperCase(),
        style: t.textTheme.headlineSmall?.copyWith(
          fontSize: narrow ? 22 : 26,
          color: missed
              ? cs.error
              : given
                  ? cs.onSurfaceVariant
                  : cs.onSurface,
        ),
      ),
    );
  }
}

enum _KeyState { open, hit, miss }

class _Key extends StatelessWidget {
  const _Key({required this.letter, required this.state, required this.onTap});
  final String letter;
  final _KeyState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final (bg, fg) = switch (state) {
      _KeyState.open => (cs.surfaceContainerHighest, cs.onSurface),
      _KeyState.hit => (AndyColors.self, Colors.white),
      _KeyState.miss => (cs.error.withValues(alpha: 0.18), cs.error),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        button: true,
        enabled: state == _KeyState.open,
        label: switch (state) {
          _KeyState.open => 'Letter $letter',
          _KeyState.hit => 'Letter $letter, in the word',
          _KeyState.miss => 'Letter $letter, not in the word',
        },
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: state == _KeyState.open ? onTap : null,
            child: SizedBox(
              width: 31,
              height: 46,
              child: Center(
                child: Text(letter.toUpperCase(),
                    style: t.textTheme.titleMedium?.copyWith(color: fg)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PuzzleSettings extends StatelessWidget {
  const _PuzzleSettings();

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final started = s.puzzleGuessesToday.isNotEmpty;
    final reminderOn = s.remindersOn && !s.remindersOff.contains('puzzle');
    return SheetBody(
      title: 'Puzzle settings',
      children: [
        Text('Difficulty', style: t.textTheme.titleMedium),
        RadioGroup<int>(
          groupValue: s.puzzleLevel,
          onChanged: (v) {
            if (v != null && !started) s.setPuzzleLevel(v);
          },
          child: Column(
            children: [
              for (var i = 0; i < puzzleLevels.length; i++)
                RadioListTile<int>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  enabled: !started,
                  value: i,
                  title: Text(puzzleLevels[i].$1,
                      style: t.textTheme.bodyLarge),
                  subtitle: Text(puzzleLevels[i].$2),
                ),
            ],
          ),
        ),
        if (started)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Today\'s puzzle is already under way. You can change the difficulty again tomorrow.',
              style: t.textTheme.bodySmall
                  ?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
          ),
        const Divider(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Remind me to play', style: t.textTheme.titleMedium),
          subtitle: Text(!reminders.available
              ? 'Notifications work in the phone app'
              : !s.remindersOn
                  ? 'Andy\'s nudges are switched off under Me, Reminders'
                  : '11:00, on days you have not played yet'),
          value: reminderOn,
          onChanged: s.remindersOn && reminders.available
              ? (v) => s.setReminderCategory('puzzle', v)
              : null,
        ),
      ],
    );
  }
}
