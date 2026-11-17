import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../exercises.dart';
import '../reminders.dart';
import '../silhouette.dart';
import '../state.dart';
import '../steps.dart';
import '../theme.dart';
import '../widgets.dart';

const _weekdayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];

Color toneColor(Tone t, ColorScheme cs) => switch (t) {
      Tone.great => AndyColors.self,
      Tone.good => AndyColors.people,
      Tone.push => AndyColors.fuel,
      Tone.ease => cs.error,
    };

String _time(int h, int m) =>
    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

// ---- Move tab cards -----------------------------------------------------------

/// Today's steps from the phone's sensor.
class StepsCard extends StatelessWidget {
  const StepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return ListenableBuilder(
      listenable: stepService,
      builder: (context, _) {
        final today = s.stepsOn(DateTime.now());
        final km = (today * 0.75 / 1000).toStringAsFixed(1);
        final status = stepService.status;
        return Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Rings(
                    values: [today / s.stepGoal],
                    colors: const [AndyColors.self],
                    size: 110,
                    stroke: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('👣', style: TextStyle(fontSize: 22)),
                        Text('${(today / s.stepGoal * 100).clamp(0, 999).round()}%',
                            style: t.textTheme.labelMedium),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stat(_thousands(today), 'steps of ${_thousands(s.stepGoal)}'),
                        const SizedBox(height: 6),
                        Stat('$km km', '${s.stepKcal(today)} kcal walking'),
                      ],
                    ),
                  ),
                ],
              ),
              if (status != StepStatus.counting) ...[
                const SizedBox(height: 12),
                Text(
                  switch (status) {
                    StepStatus.starting => 'Starting the step counter…',
                    StepStatus.denied =>
                      'Andy needs permission to count your steps.',
                    _ => 'Step counting works in the phone app, on phones with a step sensor.',
                  },
                  style: t.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (status == StepStatus.denied)
                  TextButton.icon(
                    onPressed: stepService.openSettings,
                    icon: const Icon(Icons.settings_rounded, size: 18),
                    label: const Text('Allow in settings'),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

String _thousands(int n) {
  final s = '$n';
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// The workout due today, or the next one.
class TodayWorkoutCard extends StatelessWidget {
  const TodayWorkoutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final now = DateTime.now();
    final routine = s.upcomingRoutine;
    final due = s.isTrainDay(now) && !s.trainedToday;
    final next = s.nextTrainDay;
    final headline = s.trainedToday
        ? 'Done today: ${routine.name} ✓'
        : due
            ? 'Today: ${routine.name}'
            : 'Rest day';
    final sub = s.trainedToday
        ? 'Recovery is when the muscle is built. Eat well and sleep.'
        : due
            ? '${routine.blocks.length} exercises, about 30 minutes. Reminder at ${_time(s.trainHour, s.trainMinute)}.'
            : next == null
                ? 'No training days set. Pick some in the plan.'
                : 'Next: ${_weekdayNames[next.weekday - 1]}, ${routine.name}. A walk today still counts.';
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: t.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(sub,
              style: t.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 14),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (slot, sets) in routine.blocks)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _MiniExercise(
                        exercise: exercises[s.variants[slot]]!, sets: sets),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WorkoutScreen(routine: routine))),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(due
                      ? 'Start workout'
                      : s.trainedToday
                          ? 'Do it again'
                          : 'Train anyway'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Plan and reminders',
                onPressed: () => showAndySheet(context, const PlanSheet()),
                icon: const Icon(Icons.event_repeat_rounded),
              ),
              IconButton.filledTonal(
                tooltip: 'Exercise library',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExerciseLibraryScreen())),
                icon: const Icon(Icons.menu_book_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniExercise extends StatelessWidget {
  const _MiniExercise({required this.exercise, required this.sets});
  final Exercise exercise;
  final int sets;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () =>
          showAndySheet(context, ExerciseSheet(exercise: exercise)),
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
        child: Column(
          children: [
            Expanded(
              child: ExerciseDemo(
                demo: exercise.demo,
                background: Color.alphaBlend(
                    cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    cs.surfaceContainer),
              ),
            ),
            Text(exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.labelSmall),
            Text('$sets × ${exercise.range}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ---- plan ---------------------------------------------------------------------

class PlanSheet extends StatefulWidget {
  const PlanSheet({super.key});

  @override
  State<PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<PlanSheet> {
  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final remind = s.remindersOn && !s.remindersOff.contains('workout');
    return SheetBody(
      title: 'Plan',
      children: [
        Text('Training days', style: t.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('3 or 4 a week, with rest days between, works best.',
            style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var d = 1; d <= 7; d++)
              Semantics(
                button: true,
                selected: s.trainDays.contains(d),
                label: _weekdayNames[d - 1],
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    final days = {...s.trainDays};
                    days.contains(d) ? days.remove(d) : days.add(d);
                    s.setTrainingPlan(days: days);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.trainDays.contains(d)
                          ? AndyColors.brand
                          : cs.surfaceContainerHighest,
                    ),
                    child: Text(_weekdayShort[d - 1],
                        style: t.textTheme.titleSmall?.copyWith(
                            color: s.trainDays.contains(d)
                                ? Colors.white
                                : cs.onSurface)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Workout reminder'),
          subtitle: Text(!reminders.available
              ? 'Notifications work in the phone app'
              : !s.remindersOn
                  ? 'Andy\'s nudges are switched off under Me, Reminders'
                  : 'On training days at ${_time(s.trainHour, s.trainMinute)}'),
          value: remind,
          onChanged: s.remindersOn && reminders.available
              ? (v) => s.setReminderCategory('workout', v)
              : null,
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay(hour: s.trainHour, minute: s.trainMinute));
            if (picked != null) {
              s.setTrainingPlan(hour: picked.hour, minute: picked.minute);
            }
          },
          icon: const Icon(Icons.schedule_rounded),
          label: Text('Reminder time: ${_time(s.trainHour, s.trainMinute)}'),
        ),
        const SizedBox(height: 18),
        Text('Daily step goal', style: t.textTheme.titleMedium),
        Slider(
          value: s.stepGoal.toDouble(),
          min: 3000,
          max: 15000,
          divisions: 24,
          label: _thousands(s.stepGoal),
          onChanged: (v) => s.setTrainingPlan(goal: v.round()),
        ),
        Center(
          child: Text('${_thousands(s.stepGoal)} steps',
              style: t.textTheme.titleMedium),
        ),
        const SizedBox(height: 18),
        Text('Your exercises', style: t.textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final slot in slotLadders.keys)
          if (slotLadders[slot]!.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final id in slotLadders[slot]!)
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text(exercises[id]!.name),
                      selected: s.variants[slot] == id,
                      onSelected: (_) => s.setVariant(slot, id),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

// ---- library ------------------------------------------------------------------

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  Area? _area;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final list = exercises.values
        .where((e) => _area == null || e.area == _area)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                showCheckmark: false,
                label: const Text('All'),
                selected: _area == null,
                onSelected: (_) => setState(() => _area = null),
              ),
              for (final a in Area.values)
                ChoiceChip(
                  showCheckmark: false,
                  label: Text(areaNames[a]!),
                  selected: _area == a,
                  onSelected: (_) => setState(() => _area = a),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
            children: [
              for (final e in list)
                Panel(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () =>
                        showAndySheet(context, ExerciseSheet(exercise: e)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: ExerciseDemo(demo: e.demo)),
                          Text(e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.titleSmall),
                          Text(e.muscles,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full demonstration and instructions for one exercise.
class ExerciseSheet extends StatelessWidget {
  const ExerciseSheet({super.key, required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final e = exercise;
    final best = s.bestSet(e.id);
    final inPlan = s.variants.containsValue(e.id);
    final ladder =
        slotLadders.values.any((l) => l.length > 1 && l.contains(e.id));
    return SheetBody(
      title: e.name,
      children: [
        Text('${areaNames[e.area]} · ${e.muscles}',
            style: t.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ExerciseDemo(
            demo: e.demo,
            background: Color.alphaBlend(
                cs.surfaceContainerHighest.withValues(alpha: 0.4),
                t.bottomSheetTheme.backgroundColor ?? cs.surfaceContainerLow),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Chip(label: Text('Target ${e.range}')),
            if (best != null) Chip(label: Text('Best set $best ${e.unitShort}')),
            if (e.needs.isNotEmpty) Chip(label: Text(e.needs)),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < e.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text('${i + 1}',
                      style: t.textTheme.titleSmall
                          ?.copyWith(color: AndyColors.brand)),
                ),
                Expanded(
                    child: Text(e.steps[i],
                        style: t.textTheme.bodyMedium?.copyWith(height: 1.35))),
              ],
            ),
          ),
        if (e.safety.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AndyColors.fuel.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.health_and_safety_rounded,
                    color: AndyColors.fuel, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(e.safety, style: t.textTheme.bodyMedium)),
              ],
            ),
          ),
        if (ladder) ...[
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: inPlan ? null : () => s.useInPlan(e.id),
            child: Text(inPlan ? 'In your plan' : 'Use this in my plan'),
          ),
        ],
      ],
    );
  }
}

// ---- the guided workout ---------------------------------------------------------

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key, required this.routine});
  final Routine routine;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _started = DateTime.now();
  int _block = 0;
  int _amount = 0;
  Effort _effort = Effort.hard;
  Verdict? _verdict;
  bool _summary = false;

  // Rest between sets.
  Timer? _ticker;
  int _rest = 0;

  // Hold timer for timed exercises.
  DateTime? _holdStart;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  AppState get _s => AndyScope.of(context);
  String get _slot => widget.routine.blocks[_block].$1;
  int get _sets => widget.routine.blocks[_block].$2;
  Exercise get _exercise => exercises[_s.variants[_slot]]!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_amount == 0) _amount = _suggestedAmount();
  }

  /// Start from what you did last time on this set, or the bottom of the
  /// range.
  int _suggestedAmount() {
    final e = _exercise;
    final done = _s.setsToday(e.id);
    final last = _s.lastSession(e.id);
    if (done.isNotEmpty) return done.last.amount;
    if (last.isNotEmpty) return last.first.amount;
    return e.lo;
  }

  void _log() {
    final e = _exercise;
    final done = _s.setsToday(e.id).length;
    final last = _s.lastSession(e.id);
    final previous = done < last.length ? last[done].amount : null;
    _s.logSet(e.id, _amount, _effort);
    setState(() {
      _verdict = judgeSet(e, _amount, _effort, previous: previous);
      _holdStart = null;
    });
    if (done + 1 < _sets) _startRest();
  }

  void _startRest() {
    _ticker?.cancel();
    setState(() => _rest = 75);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _rest--);
      if (_rest <= 0) timer.cancel();
    });
  }

  void _skipRest() {
    _ticker?.cancel();
    setState(() => _rest = 0);
  }

  void _next() {
    _skipRest();
    setState(() {
      _verdict = null;
      _effort = Effort.hard;
      if (_block + 1 < widget.routine.blocks.length) {
        _block++;
        _amount = _suggestedAmount();
      } else {
        _summary = true;
      }
    });
  }

  void _finish() {
    final minutes = DateTime.now().difference(_started).inMinutes;
    _s.finishWorkout(widget.routine.id, minutes);
    Navigator.pop(context);
  }

  Future<bool> _confirmLeave() async {
    final anyLogged = widget.routine.blocks.any(
        (b) => _s.setsToday(_s.variants[b.$1]!).isNotEmpty);
    if (!anyLogged) return true;
    final answer = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the workout?'),
        content: const Text(
            'Your logged sets are kept. Finish now to count it as today\'s workout.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, 'stay'),
              child: const Text('Keep going')),
          TextButton(
              onPressed: () => Navigator.pop(context, 'leave'),
              child: const Text('Just leave')),
          FilledButton(
              onPressed: () => Navigator.pop(context, 'finish'),
              child: const Text('Finish now')),
        ],
      ),
    );
    if (answer == 'finish' && mounted) {
      _finish();
      return false;
    }
    return answer == 'leave';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (_summary || await _confirmLeave()) nav.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.routine.name),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              value: _summary
                  ? 1
                  : (_block + _doneFraction()) / widget.routine.blocks.length,
              color: AndyColors.brand,
              backgroundColor: t.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        body: SafeArea(child: _summary ? _buildSummary(t) : _buildExercise(t)),
      ),
    );
  }

  double _doneFraction() =>
      (_s.setsToday(_exercise.id).length / _sets).clamp(0.0, 1.0);

  Widget _buildExercise(ThemeData t) {
    final cs = t.colorScheme;
    final e = _exercise;
    final done = _s.setsToday(e.id);
    final setNo = done.length + 1;
    final finished = done.length >= _sets;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        Text('Exercise ${_block + 1} of ${widget.routine.blocks.length}',
            style: t.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        Row(
          children: [
            Expanded(child: Text(e.name, style: t.textTheme.headlineSmall)),
            IconButton(
              tooltip: 'How to do it',
              onPressed: () =>
                  showAndySheet(context, ExerciseSheet(exercise: e)),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Panel(
          padding: const EdgeInsets.all(8),
          child: SizedBox(height: 190, child: ExerciseDemo(demo: e.demo)),
        ),
        const SizedBox(height: 10),
        Text(e.steps.first,
            style: t.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < _sets; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  backgroundColor: i < done.length
                      ? AndyColors.self.withValues(alpha: 0.18)
                      : null,
                  label: Text(i < done.length
                      ? '${done[i].amount} ✓'
                      : 'Set ${i + 1}'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_verdict != null) _VerdictCard(verdict: _verdict!),
        if (_rest > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Panel(
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _rest / 75,
                          strokeWidth: 5,
                          color: AndyColors.brand,
                        ),
                        Text('$_rest', style: t.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('Rest. Breathe slowly. Next: set $setNo.',
                        style: t.textTheme.bodyLarge),
                  ),
                  TextButton(onPressed: _skipRest, child: const Text('Skip')),
                ],
              ),
            ),
          )
        else if (!finished) ...[
          const SizedBox(height: 10),
          Text('Set $setNo of $_sets · target ${e.range}',
              style: t.textTheme.titleMedium),
          const SizedBox(height: 10),
          _AmountPicker(
            value: _amount,
            unit: e.seconds ? 'seconds' : e.unit,
            onChanged: (v) => setState(() => _amount = v),
          ),
          if (e.seconds) ...[
            const SizedBox(height: 8),
            _HoldTimer(
              started: _holdStart,
              onStart: () => setState(() => _holdStart = DateTime.now()),
              onStop: () => setState(() {
                _amount = DateTime.now().difference(_holdStart!).inSeconds;
                _holdStart = null;
              }),
            ),
          ],
          const SizedBox(height: 14),
          Text('How did it feel?', style: t.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<Effort>(
            showSelectedIcon: false,
            segments: [
              for (final f in Effort.values)
                ButtonSegment(
                  value: f,
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(effortLabels[f]!.$1),
                      Text(effortLabels[f]!.$2,
                          style: t.textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
            ],
            selected: {_effort},
            onSelectionChanged: (v) => setState(() => _effort = v.first),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _amount > 0 && _holdStart == null ? _log : null,
            child: Text('Log set $setNo'),
          ),
          if (done.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _s.undoLastSet(e.id);
                _verdict = null;
              }),
              child: const Text('Undo last set'),
            ),
        ],
        if (finished || _rest > 0) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: finished ? _next : null,
            child: Text(_block + 1 < widget.routine.blocks.length
                ? 'Next exercise'
                : 'See how you did'),
          ),
        ],
        if (!finished && _rest == 0 && done.isEmpty)
          TextButton(
            onPressed: _next,
            child: const Text('Skip this exercise'),
          ),
      ],
    );
  }

  Widget _buildSummary(ThemeData t) {
    final cs = t.colorScheme;
    final minutes = DateTime.now().difference(_started).inMinutes;
    var sets = 0, reps = 0;
    final items = <(Exercise, Advice)>[];
    for (final (slot, _) in widget.routine.blocks) {
      final e = exercises[_s.variants[slot]]!;
      final today = _s.setsToday(e.id);
      sets += today.length;
      if (!e.seconds) reps += today.fold(0, (a, l) => a + l.amount);
      items.add((e, recommend(e, today, _s.lastSession(e.id))));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        const Text('💪', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text('Workout done', style: t.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('$sets sets · $reps reps · $minutes min',
            style: t.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SectionTitle('Andy\'s notes for next time'),
        for (final (e, advice) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Panel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 64, height: 64, child: ExerciseDemo(demo: e.demo)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: t.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(advice.text,
                            style: t.textTheme.bodyMedium?.copyWith(
                                color: toneColor(advice.tone, cs) ==
                                        cs.error
                                    ? cs.onSurface
                                    : null,
                                height: 1.35)),
                        if (advice.switchTo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _s.variants.containsValue(advice.switchTo)
                                ? Text('Switched ✓',
                                    style: t.textTheme.labelLarge
                                        ?.copyWith(color: AndyColors.self))
                                : FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                        minimumSize: const Size(0, 40)),
                                    onPressed: () => setState(() =>
                                        _s.useInPlan(advice.switchTo!)),
                                    child: Text(
                                        'Switch to ${exercises[advice.switchTo]!.name}'),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _finish, child: const Text('Save workout')),
      ],
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.verdict});
  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = toneColor(verdict.tone, t.colorScheme);
    return Panel(
      color: c.withValues(alpha: 0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            switch (verdict.tone) {
              Tone.great => Icons.verified_rounded,
              Tone.good => Icons.thumb_up_alt_rounded,
              Tone.push => Icons.trending_up_rounded,
              Tone.ease => Icons.self_improvement_rounded,
            },
            color: c,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verdict.title, style: t.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(verdict.detail,
                    style: t.textTheme.bodyMedium?.copyWith(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountPicker extends StatelessWidget {
  const _AmountPicker(
      {required this.value, required this.unit, required this.onChanged});
  final int value;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget button(IconData icon, int delta, String tip) => IconButton.filledTonal(
          tooltip: tip,
          iconSize: 28,
          style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
          onPressed: value + delta < 0 ? null : () => onChanged(value + delta),
          icon: Icon(icon),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        button(Icons.remove_rounded, -1, 'One less'),
        const SizedBox(width: 20),
        Semantics(
          label: '$value $unit',
          child: Column(
            children: [
              Text('$value',
                  style: t.textTheme.displaySmall?.copyWith(
                      fontSize: 52,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              Text(unit,
                  style: t.textTheme.labelMedium
                      ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 20),
        button(Icons.add_rounded, 1, 'One more'),
      ],
    );
  }
}

/// Counts up while you hold, then fills in the seconds.
class _HoldTimer extends StatefulWidget {
  const _HoldTimer(
      {required this.started, required this.onStart, required this.onStop});
  final DateTime? started;
  final VoidCallback onStart, onStop;

  @override
  State<_HoldTimer> createState() => _HoldTimerState();
}

class _HoldTimerState extends State<_HoldTimer> {
  Timer? _tick;

  @override
  void didUpdateWidget(_HoldTimer old) {
    super.didUpdateWidget(old);
    _tick?.cancel();
    if (widget.started != null) {
      _tick = Timer.periodic(
          const Duration(milliseconds: 250), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.started != null;
    final secs =
        running ? DateTime.now().difference(widget.started!).inSeconds : 0;
    return Center(
      child: running
          ? FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AndyColors.self),
              onPressed: widget.onStop,
              icon: const Icon(Icons.stop_rounded),
              label: Text('Holding… $secs s. Tap when you drop'),
            )
          : OutlinedButton.icon(
              onPressed: widget.onStart,
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Start hold timer'),
            ),
    );
  }
}
