import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

const _moods = ['😞', '😕', '😐', '🙂', '😁'];
const _moodReplies = [
  'Thank you for being honest. Today the only job is to be gentle with yourself.',
  'Not your best, and that is fine. One small good thing, then rest.',
  'Steady is underrated. Steady builds lives.',
  'Good. Notice it. This is what your effort feels like.',
  'Look at you. Bank this feeling. Add it to the proof jar.',
];

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final mood = s.moodToday;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Me', style: t.textTheme.headlineMedium),
                  Text('The one person you can\'t ghost.',
                      style: t.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Settings',
              onPressed: () => showAndySheet(context, const _SettingsSheet()),
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Mood
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How are you, really?', style: t.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 5; i++)
                    Semantics(
                      button: true,
                      label: 'Mood ${i + 1} of 5',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => s.setMood(i + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mood == i + 1
                                ? AndyColors.self.withValues(alpha: 0.22)
                                : Colors.transparent,
                            border: Border.all(
                              width: 2,
                              color: mood == i + 1
                                  ? AndyColors.self
                                  : Colors.transparent,
                            ),
                          ),
                          child: Opacity(
                            opacity: mood == null || mood == i + 1 ? 1 : 0.45,
                            child: Text(_moods[i],
                                style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (mood != null) ...[
                const SizedBox(height: 12),
                Text(_moodReplies[mood - 1],
                    style: t.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant, height: 1.35)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Water
        Panel(
          child: Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.waterToday} of ${s.waterGoal} glasses',
                        style: t.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (s.waterToday / s.waterGoal).clamp(0.0, 1.0),
                        minHeight: 6,
                        color: AndyColors.self,
                        backgroundColor:
                            AndyColors.self.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove a glass',
                onPressed: s.waterToday == 0 ? null : () => s.addWater(-1),
                icon: const Icon(Icons.remove_rounded),
              ),
              IconButton.filled(
                tooltip: 'Add a glass',
                style: IconButton.styleFrom(backgroundColor: AndyColors.self),
                onPressed: () => s.addWater(1),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),

        // Non-negotiables
        SectionTitle(
          'Non-negotiables',
          trailing: TextButton.icon(
            onPressed: () => showAndySheet(context, const _AddHabitSheet()),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
          ),
        ),
        if (s.habits.isEmpty)
          const EmptyHint('✅',
              'The few daily things that keep your life from sliding. Add yours.')
        else
          Panel(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final h in s.habits)
                  Dismissible(
                    key: ValueKey(h.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child:
                          Icon(Icons.delete_outline_rounded, color: cs.error),
                    ),
                    onDismissed: (_) => s.removeHabit(h.id),
                    child: CheckboxListTile(
                      value: s.habitDoneToday(h.id),
                      onChanged: (_) => s.toggleHabit(h.id),
                      activeColor: AndyColors.self,
                      checkboxShape: const CircleBorder(),
                      secondary:
                          Text(h.emoji, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        h.title,
                        style: t.textTheme.bodyLarge?.copyWith(
                          decoration: s.habitDoneToday(h.id)
                              ? TextDecoration.lineThrough
                              : null,
                          color: s.habitDoneToday(h.id)
                              ? cs.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                  child: Text('Swipe left to remove one.',
                      style: t.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ),
              ],
            ),
          ),

        // Proof jar
        SectionTitle(
          'Proof jar',
          trailing: TextButton.icon(
            onPressed: () => showAndySheet(context, const _AddProofSheet()),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add proof'),
          ),
        ),
        if (s.proofs.isEmpty)
          const EmptyHint('🏺',
              'Evidence that you are capable, loved and worth it. A win, a compliment, something hard you got through. On bad days I will read these back to you.')
        else
          for (final p in s.proofs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: ValueKey(p.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete_outline_rounded, color: cs.error),
                ),
                onDismissed: (_) => s.removeProof(p.id),
                child: Panel(
                  color: AndyColors.fuel.withValues(alpha: 0.12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.text,
                          style:
                              t.textTheme.bodyLarge?.copyWith(height: 1.35)),
                      const SizedBox(height: 6),
                      Text(ago(p.time),
                          style: t.textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _AddHabitSheet extends StatefulWidget {
  const _AddHabitSheet();

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  static const _emojis = ['🎯', '😴', '📖', '🙏', '🧹', '💊', '📵', '🧠', '💰', '🌤️'];
  final _title = TextEditingController();
  String _emoji = _emojis.first;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      title: 'New non-negotiable',
      children: [
        TextField(
          controller: _title,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              labelText: 'Every day I will…', hintText: 'Save something'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          children: [
            for (final e in _emojis)
              ChoiceChip(
                showCheckmark: false,
                label: Text(e, style: const TextStyle(fontSize: 20)),
                selected: _emoji == e,
                onSelected: (_) => setState(() => _emoji = e),
              ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _title.text.trim().isEmpty
              ? null
              : () {
                  AndyScope.of(context).addHabit(_title.text, _emoji);
                  Navigator.pop(context);
                },
          child: const Text('Add it'),
        ),
      ],
    );
  }
}

class _AddProofSheet extends StatefulWidget {
  const _AddProofSheet();

  @override
  State<_AddProofSheet> createState() => _AddProofSheetState();
}

class _AddProofSheetState extends State<_AddProofSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      title: 'Add proof',
      children: [
        TextField(
          controller: _text,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText:
                'Something you did, survived, or were told that proves your worth.',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _text.text.trim().isEmpty
              ? null
              : () {
                  AndyScope.of(context).addProof(_text.text);
                  Navigator.pop(context);
                },
          child: const Text('Put it in the jar'),
        ),
      ],
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final TextEditingController _name, _kcal, _weight, _minutes;
  late ThemeMode _mode;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final s = AndyScope.of(context);
    _name = TextEditingController(text: s.name);
    _kcal = TextEditingController(text: '${s.kcalGoal}');
    _weight = TextEditingController(text: s.weightKg.round().toString());
    _minutes = TextEditingController(text: '${s.weeklyMinutesGoal}');
    _mode = s.themeMode;
  }

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _weight.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return SheetBody(
      title: 'Settings',
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _kcal,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: const InputDecoration(
                    labelText: 'Calorie goal', suffixText: 'kcal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _weight,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: const InputDecoration(
                    labelText: 'Weight', suffixText: 'kg'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _minutes,
          keyboardType: TextInputType.number,
          inputFormatters: digits,
          decoration: const InputDecoration(
              labelText: 'Weekly movement goal', suffixText: 'min'),
        ),
        const SizedBox(height: 14),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
          ],
          selected: {_mode},
          onSelectionChanged: (v) => setState(() => _mode = v.first),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () {
            s.updateSettings(
              name: _name.text.trim().isEmpty ? null : _name.text.trim(),
              kcalGoal: (int.tryParse(_kcal.text) ?? s.kcalGoal)
                  .clamp(1000, 6000),
              weightKg: (double.tryParse(_weight.text) ?? s.weightKg)
                  .clamp(30, 250)
                  .toDouble(),
              weeklyMinutesGoal:
                  (int.tryParse(_minutes.text) ?? s.weeklyMinutesGoal)
                      .clamp(30, 2000),
              themeMode: _mode,
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
