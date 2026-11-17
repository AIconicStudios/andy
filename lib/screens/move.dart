import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'workout.dart';

class MoveScreen extends StatelessWidget {
  const MoveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final recent = [...s.workouts]..sort((a, b) => b.time.compareTo(a.time));
    final activeDays = s.last7.where((d) => s.minutesOn(d) > 0).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'move',
        onPressed: () => showAndySheet(context, const _AddWorkoutSheet()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log workout'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          Text('Move', style: t.textTheme.headlineMedium),
          Text('Your body keeps the receipts.',
              style:
                  t.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          const TodayWorkoutCard(),
          const SectionTitle('Steps'),
          const StepsCard(),
          const SectionTitle('This week'),
          Panel(
            child: Row(
              children: [
                Rings(
                  values: [s.weekMinutes / s.weeklyMinutesGoal],
                  colors: const [AndyColors.move],
                  size: 140,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${s.weekMinutes}',
                          style: t.textTheme.headlineMedium),
                      Text('of ${s.weeklyMinutesGoal} min',
                          style: t.textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stat('${s.streak} 🔥',
                          s.streak == 1 ? 'day streak' : 'day streak'),
                      const SizedBox(height: 8),
                      Stat('$activeDays / 7', 'active days'),
                      const SizedBox(height: 8),
                      Stat(
                          '${s.last7.fold(0, (a, d) => a + s.burnedOn(d))}',
                          'kcal burned'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Minutes, last 7 days'),
          Panel(
            child: WeekBars(
              days: s.last7,
              values: s.last7.map(s.minutesOn).toList(),
              color: AndyColors.move,
            ),
          ),
          const SectionTitle('Steps, last 7 days'),
          Panel(
            child: WeekBars(
              days: s.last7,
              values: s.last7.map(s.stepsOn).toList(),
              color: AndyColors.self,
              goal: s.stepGoal,
            ),
          ),
          const SectionTitle('History'),
          if (recent.isEmpty)
            const EmptyHint('👟',
                'No workouts yet. You do not need a gym. You need ten minutes and shoes.')
          else
            for (final w in recent.take(30))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey(w.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete_outline_rounded, color: cs.error),
                  ),
                  onDismissed: (_) => s.removeWorkout(w.id),
                  child: Panel(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(workoutType(w.type).emoji,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.type, style: t.textTheme.titleMedium),
                              Text(
                                '${ago(w.time)} · ${intensityLabels[w.intensity]} · ${w.kcal(s.weightKg)} kcal',
                                style: t.textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Text('${w.minutes} min',
                            style: t.textTheme.titleMedium),
                        IconButton(
                          tooltip: 'Remove',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: cs.onSurfaceVariant),
                          onPressed: () => s.removeWorkout(w.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _AddWorkoutSheet extends StatefulWidget {
  const _AddWorkoutSheet();

  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  String _type = 'Walk';
  double _minutes = 30;
  int _intensity = 1;

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final preview = Workout(
            id: '',
            type: _type,
            minutes: _minutes.round(),
            intensity: _intensity,
            time: DateTime.now())
        .kcal(s.weightKg);
    return SheetBody(
      title: 'What did you do?',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final w in workoutTypes)
              ChoiceChip(
                showCheckmark: false,
                label: Text('${w.emoji} ${w.name}'),
                selected: _type == w.name,
                onSelected: (_) => setState(() => _type = w.name),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Duration', style: t.textTheme.titleMedium),
            const Spacer(),
            Text('${_minutes.round()} min', style: t.textTheme.titleMedium),
          ],
        ),
        Slider(
          value: _minutes,
          min: 5,
          max: 180,
          divisions: 35,
          onChanged: (v) => setState(() => _minutes = v),
        ),
        const SizedBox(height: 6),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var i = 0; i < 3; i++)
              ButtonSegment(value: i, label: Text(intensityLabels[i])),
          ],
          selected: {_intensity},
          onSelectionChanged: (v) => setState(() => _intensity = v.first),
        ),
        const SizedBox(height: 14),
        Text('About $preview kcal burned',
            textAlign: TextAlign.center,
            style: t.textTheme.bodyMedium
                ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () {
            s.addWorkout(_type, _minutes.round(), _intensity);
            Navigator.pop(context);
          },
          child: const Text('Done. Log it'),
        ),
      ],
    );
  }
}
