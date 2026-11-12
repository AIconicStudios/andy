import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

const _cadences = {
  2: 'Every couple of days',
  7: 'Weekly',
  14: 'Every 2 weeks',
  30: 'Monthly',
  90: 'Every 3 months',
};

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final people = s.peopleByDrift;
    final onTrack = people.where((p) => !p.overdue).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'people',
        onPressed: () => showAndySheet(context, const _AddPersonSheet()),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add someone'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
        children: [
          Text('People', style: t.textTheme.headlineMedium),
          Text('Nobody wins at life alone.',
              style:
                  t.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (people.isEmpty)
            const EmptyHint('🫂',
                'Add the people who matter and how often you want to speak. I will tell you when someone is slipping away.')
          else ...[
            Panel(
              child: Row(
                children: [
                  Rings(
                    values: [s.peopleScore],
                    colors: const [AndyColors.people],
                    size: 84,
                    stroke: 10,
                    child: Text('$onTrack/${people.length}',
                        style: t.textTheme.titleMedium),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      onTrack == people.length
                          ? 'Everyone in your circle has heard from you. That is rare. Well done.'
                          : '${people.length - onTrack} ${people.length - onTrack == 1 ? 'person is' : 'people are'} waiting to hear from you. A message takes a minute.',
                      style: t.textTheme.bodyLarge?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final p in people) _PersonCard(p),
          ],
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard(this.p);
  final Person p;

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final d = p.daysSince;
    final status = d == null
        ? 'Not logged yet'
        : d == 0
            ? 'Spoke today'
            : d == 1
                ? 'Spoke yesterday'
                : 'Spoke $d days ago';
    final barColor = p.overdue ? cs.error : AndyColors.people;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AndyColors.people.withValues(alpha: 0.18),
                  child: Text(
                    p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: AndyColors.people,
                        fontWeight: FontWeight.w800,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: t.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '$status · ${(_cadences[p.everyDays] ?? 'every ${p.everyDays} days').toLowerCase()}',
                        style: t.textTheme.bodySmall?.copyWith(
                            color: p.overdue ? cs.error : cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14)),
                  onPressed: d == 0 ? null : () => s.markContacted(p.id),
                  child: Text(d == 0 ? 'Done' : 'We talked'),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: cs.onSurfaceVariant),
                  onSelected: (_) => s.removePerson(p.id),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: p.drift.clamp(0.0, 1.0),
                  minHeight: 6,
                  color: barColor,
                  backgroundColor: barColor.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPersonSheet extends StatefulWidget {
  const _AddPersonSheet();

  @override
  State<_AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends State<_AddPersonSheet> {
  final _name = TextEditingController();
  int _every = 7;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      title: 'Who matters to you?',
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text('How often do you want to connect?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in _cadences.entries)
              ChoiceChip(
                showCheckmark: false,
                label: Text(e.value),
                selected: _every == e.key,
                onSelected: (_) => setState(() => _every = e.key),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _name.text.trim().isEmpty
              ? null
              : () {
                  AndyScope.of(context).addPerson(_name.text, _every);
                  Navigator.pop(context);
                },
          child: const Text('Add to my circle'),
        ),
      ],
    );
  }
}
