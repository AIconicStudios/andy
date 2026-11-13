import 'package:material_ui/material_ui.dart';

import '../dictionary.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Today's word, shown on the Today tab.
class WordOfTheDayCard extends StatelessWidget {
  const WordOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final entry = dictionary.wordOfTheDay(DateTime.now());
    if (entry == null || entry.senses.isEmpty) return const SizedBox.shrink();
    final sense = entry.senses.first;
    final saved = s.savedWords.contains(entry.word);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Word of the day'),
        Panel(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DictionaryScreen())),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(entry.word,
                            style: t.textTheme.headlineMedium
                                ?.copyWith(color: AndyColors.people)),
                      ),
                      IconButton(
                        tooltip: saved ? 'Remove from my words' : 'Save word',
                        onPressed: () => s.toggleWord(entry.word),
                        icon: Icon(
                            saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            color: saved
                                ? AndyColors.people
                                : cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Text(sense.pos,
                      style: t.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(sense.definition,
                        style: t.textTheme.bodyLarge?.copyWith(height: 1.35)),
                  ),
                  if (sense.example.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text('“${sense.example}”',
                          style: t.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                              height: 1.35)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(String word) {
    final entry = dictionary.lookup(word);
    if (entry != null) showAndySheet(context, _EntrySheet(entry: entry));
  }

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final q = _query.text.trim();
    final results = dictionary.search(q);
    final base = results.contains(q.toLowerCase()) ? null : dictionary.baseForm(q);
    final today = dictionary.wordOfTheDay(DateTime.now());
    final saved = s.savedWords.reversed.toList();

    Widget row(String word, {String? note}) {
      final e = dictionary.lookup(word);
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(word, style: t.textTheme.titleMedium),
        subtitle: Text(
          note ?? (e == null || e.senses.isEmpty ? '' : e.senses.first.definition),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing:
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        onTap: () => _open(word),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dictionary')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: TextField(
              controller: _query,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Look up a word',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(_query.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) {
                final w = v.trim().toLowerCase();
                _open(dictionary.lookup(w) != null
                    ? w
                    : dictionary.baseForm(w) ?? w);
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              children: [
                if (!dictionary.loaded)
                  const EmptyHint('📖', 'The dictionary could not be loaded.')
                else if (q.isEmpty) ...[
                  if (today != null) ...[
                    const SectionTitle('Today'),
                    row(today.word),
                  ],
                  SectionTitle('My words${saved.isEmpty ? '' : ' (${saved.length})'}'),
                  if (saved.isEmpty)
                    const EmptyHint('🔖',
                        'Bookmark a word and it stays here. A word you can use is a word you own.')
                  else
                    for (final w in saved) row(w),
                  const SizedBox(height: 20),
                  Text(
                    '${dictionary.size} words, all on your phone. '
                    'Definitions from WordNet 3.0, Princeton University.',
                    textAlign: TextAlign.center,
                    style: t.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ] else ...[
                  if (base != null) row(base, note: 'Base form of “$q”'),
                  for (final w in results) row(w),
                  if (results.isEmpty && base == null)
                    EmptyHint('🤷',
                        'No entry for “$q”. Check the spelling, or try the plain form of the word.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntrySheet extends StatelessWidget {
  const _EntrySheet({required this.entry});
  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final saved = s.savedWords.contains(entry.word);
    return SheetBody(
      title: entry.word,
      children: [
        for (var i = 0; i < entry.senses.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 26,
                  child: Text('${i + 1}',
                      style: t.textTheme.titleMedium
                          ?.copyWith(color: AndyColors.people)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.senses[i].pos,
                          style: t.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 2),
                      Text(entry.senses[i].definition,
                          style:
                              t.textTheme.bodyLarge?.copyWith(height: 1.35)),
                      if (entry.senses[i].example.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('“${entry.senses[i].example}”',
                            style: t.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                                height: 1.35)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        FilledButton.tonalIcon(
          onPressed: () => s.toggleWord(entry.word),
          icon: Icon(saved
              ? Icons.bookmark_rounded
              : Icons.bookmark_outline_rounded),
          label: Text(saved ? 'Saved to my words' : 'Save to my words'),
        ),
      ],
    );
  }
}
