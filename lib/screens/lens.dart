import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../lens_engine.dart';
import '../memories.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Point Andy at a thing. If he has seen it before, the memory pops up;
/// if not, he offers to remember it.
class LensScreen extends StatefulWidget {
  const LensScreen({super.key});

  @override
  State<LensScreen> createState() => _LensScreenState();
}

class _LensScreenState extends State<LensScreen> with WidgetsBindingObserver {
  CameraController? _camera;
  String? _problem;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera must be released when the app is backgrounded.
    if (state == AppLifecycleState.inactive) {
      _camera?.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      _start();
    }
  }

  Future<void> _start() async {
    if (kIsWeb) {
      setState(() => _problem =
          'The memory lens needs the phone app. It is not available in this preview.');
      return;
    }
    try {
      await lens.init();
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('none', 'No camera found');
      final back = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);
      final c = CameraController(back, ResolutionPreset.high,
          enableAudio: false);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _camera = c;
        _problem = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _problem = e.code.contains('ccessDenied')
          ? 'Andy needs camera permission to see things. Allow it in your phone settings.'
          : 'Could not open the camera. ${e.description ?? ''}');
    } catch (e) {
      if (mounted) setState(() => _problem = 'Could not open the camera.');
    }
  }

  Future<void> _look() async {
    final c = _camera;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    try {
      final shot = await c.takePicture();
      final sighting = await lens.look(shot.path);
      if (!mounted) return;
      final s = AndyScope.of(context);
      final found = recognise(s.memories, sighting.signature);
      if (found.isEmpty) {
        await showAndySheet(context, _SaveSheet(sighting: sighting));
      } else if (isClearWinner(found)) {
        final right = await showAndySheet<bool>(
            context, _RecallSheet(memory: found.first.memory, fromLens: true));
        if (!mounted) return;
        if (right == false) {
          await showAndySheet(context, _SaveSheet(sighting: sighting));
        } else if (right == true) {
          // Each confirmed sighting teaches Andy another angle or distance.
          s.reinforceMemory(found.first.memory.id, sighting.signature);
        }
      } else {
        // Not sure enough to announce it: offer the lookalikes instead.
        final pick = await showAndySheet<Object>(
            context, _MaybeSheet(found: found, sighting: sighting));
        if (!mounted) return;
        if (pick is Memory) {
          s.reinforceMemory(pick.id, sighting.signature);
          await showAndySheet(context, _RecallSheet(memory: pick));
        } else if (pick == false) {
          await showAndySheet(context, _SaveSheet(sighting: sighting));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('I could not get a clear look. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final c = _camera;
    return Theme(
      data: andyTheme(Brightness.dark),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (c != null && c.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: c.value.previewSize!.height,
                  height: c.value.previewSize!.width,
                  child: CameraPreview(c),
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _problem == null
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off_rounded,
                                color: Colors.white54, size: 48),
                            const SizedBox(height: 16),
                            Text(_problem!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ],
                        ),
                ),
              ),
            // Top bar
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton.filled(
                        tooltip: 'Close',
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 44)),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MemoriesScreen())),
                        icon: const Icon(Icons.auto_stories_rounded, size: 18),
                        label: Text('${s.memories.length} saved'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Shutter
            if (c != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            _busy
                                ? 'Looking…'
                                : 'Centre one thing, near or far, then tap',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Semantics(
                          button: true,
                          label: 'Look at this',
                          child: GestureDetector(
                            onTap: _look,
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AndyColors.fuel, AndyColors.brand],
                                ),
                              ),
                              child: _busy
                                  ? const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 3),
                                    )
                                  : const Icon(Icons.visibility_rounded,
                                      color: Colors.white, size: 36),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The saved photo of a memory, or a placeholder when there is none.
class MemoryPhoto extends StatelessWidget {
  const MemoryPhoto(this.memory, {super.key, this.size});
  final Memory memory;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final file = kIsWeb ? null : lens.photo(memory.photo);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size == null ? 20 : 14),
      child: file != null
          ? Image.file(file,
              width: size,
              height: size ?? 200,
              fit: BoxFit.cover,
              semanticLabel: 'Photo of ${memory.title}')
          : Container(
              width: size,
              height: size ?? 120,
              color: AndyColors.fuel.withValues(alpha: 0.18),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AndyColors.fuel),
            ),
    );
  }
}

/// The pop-up: Andy recognised the thing and plays the memory back.
class _RecallSheet extends StatelessWidget {
  const _RecallSheet({required this.memory, this.fromLens = false});
  final Memory memory;
  final bool fromLens;

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return SheetBody(
      title: memory.title,
      children: [
        SizedBox(width: double.infinity, child: MemoryPhoto(memory)),
        const SizedBox(height: 16),
        Text(fromLens && memory.note.isNotEmpty ? 'YOU TOLD ME' : 'MEMORY',
            style: t.textTheme.labelSmall?.copyWith(
                color: AndyColors.brand,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
        const SizedBox(height: 6),
        Text(
            memory.note.isEmpty
                ? (fromLens ? 'I know this one.' : 'Saved so I recognise it.')
                : memory.note,
            style: t.textTheme.titleLarge
                ?.copyWith(height: 1.35, fontWeight: FontWeight.w600)),
        if (memory.remindAt != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                  memory.remindAt!.isAfter(DateTime.now())
                      ? Icons.alarm_rounded
                      : Icons.alarm_on_rounded,
                  size: 20,
                  color: AndyColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  memory.remindAt!.isAfter(DateTime.now())
                      ? 'Alarm set for ${whenText(memory.remindAt!)}'
                      : 'Reminded you on ${whenText(memory.remindAt!)}',
                  style: t.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text('Saved ${ago(memory.created).toLowerCase()}',
            style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 20),
        if (fromLens)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Not this'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('That\'s it'),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    lens.forgetPhoto(memory.photo);
                    s.removeMemory(memory.id);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Forget'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showAndySheet(context, _SaveSheet(editing: memory));
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Andy is not certain: show the lookalikes and let the user decide.
/// Pops with the chosen [Memory], or `false` for "none of these".
class _MaybeSheet extends StatelessWidget {
  const _MaybeSheet({required this.found, required this.sighting});
  final List<MemoryMatch> found;
  final Sighting sighting;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return SheetBody(
      title: found.length == 1 ? 'This could be…' : 'This could be one of these',
      children: [
        Text('I am not certain. Tap the right one and I will learn it better.',
            style:
                t.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        for (final m in found)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Panel(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () => Navigator.pop(context, m.memory),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      MemoryPhoto(m.memory, size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.memory.title,
                                style: t.textTheme.titleMedium),
                            Text('${m.percent}% alike',
                                style: t.textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
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
          ),
        const SizedBox(height: 6),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('None of these. Save as new'),
        ),
      ],
    );
  }
}

/// Save a new memory for a sighting, or edit the words of an existing one.
class _SaveSheet extends StatefulWidget {
  const _SaveSheet({this.sighting, this.editing})
      : assert(sighting != null || editing != null);
  final Sighting? sighting;
  final Memory? editing;

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  late final TextEditingController _title, _note;
  bool _saving = false;
  DateTime? _remindAt;

  @override
  void initState() {
    super.initState();
    final labels = widget.sighting?.signature.labels ?? const {};
    _title = TextEditingController(
        text: widget.editing?.title ??
            (labels.isEmpty ? '' : labels.keys.first));
    _note = TextEditingController(text: widget.editing?.note ?? '');
    _remindAt = widget.editing?.remindAt;
  }

  DateTime get _defaultAlarm {
    final t = DateTime.now().add(const Duration(days: 1));
    return DateTime(t.year, t.month, t.day, 9);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final at = _remindAt ?? _defaultAlarm;
    final d = await showDatePicker(
      context: context,
      initialDate: at.isBefore(now) ? now : at,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (d != null) {
      setState(() =>
          _remindAt = DateTime(d.year, d.month, d.day, at.hour, at.minute));
    }
  }

  Future<void> _pickTime() async {
    final at = _remindAt ?? _defaultAlarm;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(at));
    if (t != null) {
      setState(() => _remindAt =
          DateTime(at.year, at.month, at.day, t.hour, t.minute));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  // Only a name is required: a note and an alarm are both optional.
  bool get _valid => _title.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    setState(() => _saving = true);
    final s = AndyScope.of(context);
    final nav = Navigator.of(context);
    final editing = widget.editing;
    if (editing != null) {
      s.updateMemory(
          editing.id, _title.text.trim(), _note.text.trim(), _remindAt);
    } else {
      final id = newId();
      final photo = await lens.keepPhoto(id, widget.sighting!.thumbnail);
      s.addMemory(Memory(
        id: id,
        title: _title.text.trim(),
        note: _note.text.trim(),
        photo: photo,
        created: DateTime.now(),
        signatures: [widget.sighting!.signature],
        remindAt: _remindAt,
      ));
    }
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final sighting = widget.sighting;
    return SheetBody(
      title: widget.editing != null ? 'Edit memory' : 'I don\'t know this yet',
      children: [
        if (sighting != null && sighting.thumbnail.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(sighting.thumbnail,
                height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'What is it?'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            alignLabelWithHint: true,
            hintText: 'Leave empty if the name is enough.',
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.alarm_rounded),
          title: const Text('Set an alarm for this'),
          subtitle: Text(_remindAt == null
              ? 'I will notify you at a date and time you choose'
              : _remindAt!.isBefore(DateTime.now())
                  ? 'That time has passed. Pick a new one.'
                  : whenText(_remindAt!)),
          value: _remindAt != null,
          onChanged: (on) =>
              setState(() => _remindAt = on ? _defaultAlarm : null),
        ),
        if (_remindAt != null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(whenText(_remindAt!).split(',').first),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(whenText(_remindAt!).split(', ').last),
                ),
              ),
            ],
          ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _valid ? _save : null,
          child: Text(widget.editing != null ? 'Save' : 'Remember this'),
        ),
      ],
    );
  }
}

/// Everything Andy has been asked to remember.
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  @override
  void initState() {
    super.initState();
    lens.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AndyScope.of(context);
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Memories')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        children: [
          if (s.memories.isEmpty)
            const EmptyHint('🔍',
                'Nothing saved yet. Point me at a book, your TV, a gift, anything, and tell me what it means to you.')
          else
            for (final m in s.memories)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () =>
                        showAndySheet(context, _RecallSheet(memory: m)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          MemoryPhoto(m, size: 64),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.title, style: t.textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                    [
                                      if (m.remindAt != null &&
                                          m.remindAt!.isAfter(DateTime.now()))
                                        '⏰ ${whenText(m.remindAt!)}',
                                      if (m.note.isNotEmpty) m.note,
                                    ].join('  ·  ').isEmpty
                                        ? 'Saved ${ago(m.created).toLowerCase()}'
                                        : [
                                            if (m.remindAt != null &&
                                                m.remindAt!
                                                    .isAfter(DateTime.now()))
                                              '⏰ ${whenText(m.remindAt!)}',
                                            if (m.note.isNotEmpty) m.note,
                                          ].join('  ·  '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.textTheme.bodyMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        height: 1.3)),
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
              ),
        ],
      ),
    );
  }
}
