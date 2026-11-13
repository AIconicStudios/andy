import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../alarms.dart';
import '../andy_brain.dart';
import '../quiz.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final now = DateTime.now();
    final alarms = [...s.alarms]
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    return Scaffold(
      appBar: AppBar(title: const Text('Alarms')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'alarm',
        onPressed: () => showAndySheet(context, const _AlarmSheet()),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New alarm'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
        children: [
          Panel(
            color: AndyColors.brand.withValues(alpha: 0.10),
            child: Row(
              children: [
                const Text('🧠', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'No snooze. No off button. The alarm only stops when you '
                    'answer $quizzesToSolve questions correctly.',
                    style: t.textTheme.bodyLarge?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          if (!alarmService.available)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Alarms ring in the phone app. They cannot ring in this preview, but you can try the quiz.',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 12),
          if (alarms.isEmpty)
            const EmptyHint('⏰',
                'No alarms yet. Set one and I will make sure you are properly awake before it lets you go.')
          else
            for (final a in alarms)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () =>
                        showAndySheet(context, _AlarmSheet(editing: a)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.timeText,
                                  style: t.textTheme.displaySmall?.copyWith(
                                    color: a.enabled
                                        ? cs.onSurface
                                        : cs.onSurfaceVariant,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                Text(
                                  [
                                    if (a.label.isNotEmpty) a.label,
                                    a.daily ? 'Every day' : 'Once',
                                    if (a.enabled) untilText(a.next(now), now),
                                  ].join(' · '),
                                  style: t.textTheme.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: a.enabled,
                            onChanged: (v) => s.setAlarmEnabled(a.id, v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AlarmRingScreen(alarmId: null))),
            icon: const Icon(Icons.psychology_alt_rounded),
            label: const Text('Try the quiz (no sound)'),
          ),
        ],
      ),
    );
  }
}

class _AlarmSheet extends StatefulWidget {
  const _AlarmSheet({this.editing});
  final WakeAlarm? editing;

  @override
  State<_AlarmSheet> createState() => _AlarmSheetState();
}

class _AlarmSheetState extends State<_AlarmSheet> {
  late TimeOfDay _time;
  late bool _daily;
  late final TextEditingController _label;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _time = e == null
        ? const TimeOfDay(hour: 6, minute: 0)
        : TimeOfDay(hour: e.hour, minute: e.minute);
    _daily = e?.daily ?? true;
    _label = TextEditingController(text: e?.label ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final e = widget.editing;
    final text =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    return SheetBody(
      title: e == null ? 'New alarm' : 'Edit alarm',
      children: [
        Semantics(
          button: true,
          label: 'Alarm time $text. Tap to change.',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              final picked =
                  await showTimePicker(context: context, initialTime: _time);
              if (picked != null) setState(() => _time = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(text,
                  style: t.textTheme.displaySmall?.copyWith(
                      fontSize: 52,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _label,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              labelText: 'Label (optional)', hintText: 'Gym before work'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Every day'),
          subtitle:
              Text(_daily ? 'Rings daily until you switch it off' : 'Rings once'),
          value: _daily,
          onChanged: (v) => setState(() => _daily = v),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            s.saveAlarm(
              id: e?.id,
              hour: _time.hour,
              minute: _time.minute,
              label: _label.text.trim(),
              daily: _daily,
            );
            Navigator.pop(context);
          },
          child: Text(e == null ? 'Set alarm' : 'Save'),
        ),
        if (e != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
                foregroundColor: t.colorScheme.error,
                minimumSize: const Size(0, 48)),
            onPressed: () {
              s.removeAlarm(e.id);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete alarm'),
          ),
        ],
      ],
    );
  }
}

/// Shown while an alarm rings. There is no way out except through the quiz.
/// With a null [alarmId] it is a silent practice round.
class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({super.key, required this.alarmId});
  final int? alarmId;

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  final _random = Random();
  late Quiz _quiz = randomQuiz(_random);
  int _solved = 0;
  int? _picked; // option tapped for the current question
  bool _done = false;

  bool get _practice => widget.alarmId == null;

  Future<void> _answer(int i) async {
    if (_picked != null) return;
    setState(() => _picked = i);
    final right = i == _quiz.answer;
    // Long enough to see what the right answer was.
    await Future<void>.delayed(Duration(milliseconds: right ? 550 : 1300));
    if (!mounted) return;
    if (right && _solved + 1 >= quizzesToSolve) {
      final s = AndyScope.of(context);
      final id = widget.alarmId;
      if (id != null) {
        await alarmService.silence(id);
        s.alarmBeaten(id);
      }
      if (mounted) {
        setState(() {
          _solved++;
          _done = true;
        });
      }
      return;
    }
    setState(() {
      if (right) _solved++;
      _quiz = randomQuiz(_random, not: _quiz.kind);
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    WakeAlarm? alarm;
    for (final a in s.alarms) {
      if (a.id == widget.alarmId) alarm = a;
    }

    return Theme(
      data: andyTheme(Brightness.dark),
      child: PopScope(
        // The back button does nothing while the alarm is still ringing.
        canPop: _practice || _done,
        child: Builder(builder: (context) {
          final t = Theme.of(context);
          final cs = t.colorScheme;
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: _done
                    ? _Awake(
                        name: s.name,
                        practice: _practice,
                        onClose: () => Navigator.pop(context))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                  _practice
                                      ? Icons.psychology_alt_rounded
                                      : Icons.notifications_active_rounded,
                                  color: AndyColors.fuel),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _practice
                                      ? 'Practice round'
                                      : (alarm == null || alarm.label.isEmpty
                                          ? 'Wake up, ${s.name}'
                                          : alarm.label),
                                  style: t.textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_practice)
                                IconButton(
                                  tooltip: 'Close',
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              for (var i = 0; i < quizzesToSolve; i++)
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 8,
                                    margin: EdgeInsets.only(
                                        right: i == quizzesToSolve - 1 ? 0 : 6),
                                    decoration: BoxDecoration(
                                      color: i < _solved
                                          ? AndyColors.self
                                          : cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_solved of $quizzesToSolve solved'
                            '${_practice ? '' : ' · still ringing'}',
                            style: t.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const Spacer(),
                          Text(_quiz.kind.toUpperCase(),
                              style: t.textTheme.labelSmall?.copyWith(
                                  color: AndyColors.fuel,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2)),
                          const SizedBox(height: 10),
                          Text(_quiz.prompt,
                              style: t.textTheme.headlineSmall
                                  ?.copyWith(height: 1.35)),
                          const Spacer(),
                          if (_picked != null && _picked != _quiz.answer)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Not quite. That one does not count. Here comes another.',
                                style: t.textTheme.bodyMedium
                                    ?.copyWith(color: cs.error),
                              ),
                            ),
                          for (var i = 0; i < _quiz.options.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _Option(
                                text: _quiz.options[i],
                                state: _picked == null
                                    ? _OptionState.idle
                                    : i == _quiz.answer
                                        ? _OptionState.right
                                        : i == _picked
                                            ? _OptionState.wrong
                                            : _OptionState.dimmed,
                                onTap: () => _answer(i),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

enum _OptionState { idle, right, wrong, dimmed }

class _Option extends StatelessWidget {
  const _Option({required this.text, required this.state, required this.onTap});
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final (bg, fg, icon) = switch (state) {
      _OptionState.right => (AndyColors.self, Colors.white, Icons.check_rounded),
      _OptionState.wrong => (cs.error, cs.onError, Icons.close_rounded),
      _ => (cs.surfaceContainer, cs.onSurface, null),
    };
    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.4 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: state == _OptionState.idle ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
            child: Row(
              children: [
                Expanded(
                  child: Text(text,
                      style: t.textTheme.titleMedium?.copyWith(color: fg)),
                ),
                if (icon != null) Icon(icon, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Awake extends StatelessWidget {
  const _Awake(
      {required this.name, required this.practice, required this.onClose});
  final String name;
  final bool practice;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        const Text('☀️', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 18),
        Text(practice ? 'Sharp.' : 'You are up, $name.',
            style: t.textTheme.displaySmall),
        const SizedBox(height: 12),
        Text(
          practice
              ? 'That is what stands between you and the off switch.'
              : 'Brain is on. The alarm is off. The day is yours.',
          style: t.textTheme.titleMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 28),
        Text(worthForToday(),
            style: t.textTheme.titleLarge?.copyWith(height: 1.35)),
        const Spacer(),
        FilledButton(
            onPressed: onClose,
            child: Text(practice ? 'Done' : 'Start the day')),
      ],
    );
  }
}
