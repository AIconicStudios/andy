import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final now = DateTime.now();
    final eaten = s.kcalOn(now);
    final burned = s.burnedOn(now);
    final left = s.kcalGoal - eaten;
    final today = s.foodsOn(now);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'food',
        onPressed: () => showAndySheet(context, const _AddFoodSheet()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log food'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          Text('Food', style: t.textTheme.headlineMedium),
          Text('Fuel, not punishment.',
              style:
                  t.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          Panel(
            child: Row(
              children: [
                Rings(
                  values: [eaten / s.kcalGoal],
                  colors: const [AndyColors.fuel],
                  size: 140,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${left.abs()}', style: t.textTheme.headlineMedium),
                      Text(left >= 0 ? 'kcal left' : 'kcal over',
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
                      Stat('$eaten', 'eaten'),
                      const SizedBox(height: 8),
                      Stat('${s.kcalGoal}', 'goal'),
                      const SizedBox(height: 8),
                      Stat('$burned', 'burned moving'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Today'),
          if (today.isEmpty)
            const EmptyHint('🍽️',
                'Nothing logged yet. Honest tracking beats perfect eating.')
          else
            for (final meal in meals)
              if (today.any((f) => f.meal == meal))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Panel(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(meal,
                                    style: t.textTheme.titleMedium)),
                            Text(
                              '${today.where((f) => f.meal == meal).fold(0, (a, f) => a + f.kcal)} kcal',
                              style: t.textTheme.labelLarge
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                        for (final f in today.where((f) => f.meal == meal))
                          Dismissible(
                            key: ValueKey(f.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.delete_outline_rounded,
                                  color: cs.error),
                            ),
                            onDismissed: (_) => s.removeFood(f.id),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(f.name,
                                  style: t.textTheme.bodyLarge),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${f.kcal}',
                                      style: t.textTheme.titleMedium),
                                  IconButton(
                                    tooltip: 'Remove',
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(Icons.close_rounded,
                                        size: 18, color: cs.onSurfaceVariant),
                                    onPressed: () => s.removeFood(f.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
          const SectionTitle('Last 7 days'),
          Panel(
            child: WeekBars(
              days: s.last7,
              values: s.last7.map(s.kcalOn).toList(),
              color: AndyColors.fuel,
              goal: s.kcalGoal,
            ),
          ),
        ],
      ),
    );
  }
}

String _mealForNow() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Breakfast';
  if (h < 16) return 'Lunch';
  if (h < 22) return 'Dinner';
  return 'Snack';
}

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet();

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  String _meal = _mealForNow();

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && (int.tryParse(_kcal.text) ?? 0) > 0;

  void _save() {
    AndyScope.of(context)
        .addFood(_name.text.trim(), int.parse(_kcal.text), _meal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final q = _name.text.trim().toLowerCase();
    final picks = quickFoods
        .where((f) => q.isEmpty || f.name.toLowerCase().contains(q))
        .take(12)
        .toList();
    return SheetBody(
      title: 'What did you eat?',
      children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            for (final m in meals) ButtonSegment(value: m, label: Text(m)),
          ],
          selected: {_meal},
          onSelectionChanged: (v) => setState(() => _meal = v.first),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Food'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final f in picks)
              ActionChip(
                label: Text('${f.name} · ${f.kcal}'),
                onPressed: () => setState(() {
                  _name.text = f.name;
                  _kcal.text = '${f.kcal}';
                }),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _kcal,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
              labelText: 'Calories',
              suffixText: 'kcal',
              helperText: 'A decent guess is good enough.'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _valid ? _save : null,
          child: const Text('Log it'),
        ),
      ],
    );
  }
}
