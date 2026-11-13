import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarms.dart';
import 'memories.dart';
import 'models.dart';

/// Everything Andy knows, persisted on the device as one JSON document.
class AppState extends ChangeNotifier {
  static const _key = 'andy_state_v1';

  bool loaded = false;
  bool onboarded = false;

  String name = '';
  int kcalGoal = 2200;
  double weightKg = 70;
  int weeklyMinutesGoal = 150;
  int waterGoal = 8;
  ThemeMode themeMode = ThemeMode.system;
  String themeName = 'ember'; // id of an AndyPalette
  bool blackDark = false; // true black instead of charcoal in dark mode
  bool remindersOn = true;
  Set<String> remindersOff = {}; // categories switched off

  /// Called after every change, so reminders can be rescheduled.
  void Function(AppState)? onChanged;

  List<FoodEntry> foods = [];
  List<Workout> workouts = [];
  List<Person> people = [];
  List<Habit> habits = [];
  List<Proof> proofs = [];
  List<Memory> memories = []; // newest first
  List<WakeAlarm> alarms = [];
  List<String> savedWords = []; // dictionary bookmarks, oldest first

  // Daily puzzle: letters tried on [puzzleDay], and the run of days solved.
  String puzzleDay = '';
  String puzzleDoneDay = ''; // the day the puzzle was last won or lost
  int puzzleLevel = 1; // 0 gentle, 1 hard, 2 brutal
  String puzzleGuesses = '';
  String puzzleLastWin = '';
  int puzzleStreak = 0;
  int puzzleBest = 0;
  Set<String> habitDone = {}; // "<dateKey>|<habitId>"
  Map<String, int> mood = {}; // dateKey -> 1..5
  Map<String, int> water = {}; // dateKey -> glasses

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        onboarded = j['onboarded'] ?? false;
        name = j['name'] ?? '';
        kcalGoal = j['kcalGoal'] ?? 2200;
        weightKg = (j['weightKg'] ?? 70).toDouble();
        weeklyMinutesGoal = j['weeklyMinutesGoal'] ?? 150;
        waterGoal = j['waterGoal'] ?? 8;
        themeMode = ThemeMode.values[j['themeMode'] ?? 0];
        themeName = j['themeName'] ?? 'ember';
        blackDark = j['blackDark'] ?? false;
        remindersOn = j['remindersOn'] ?? true;
        remindersOff = Set<String>.from(j['remindersOff'] ?? []);
        List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
            ((j[k] ?? []) as List)
                .map((e) => f(Map<String, dynamic>.from(e)))
                .toList();
        foods = list('foods', FoodEntry.fromJson);
        workouts = list('workouts', Workout.fromJson);
        people = list('people', Person.fromJson);
        habits = list('habits', Habit.fromJson);
        proofs = list('proofs', Proof.fromJson);
        memories = list('memories', Memory.fromJson);
        alarms = list('alarms', WakeAlarm.fromJson);
        savedWords = List<String>.from(j['savedWords'] ?? []);
        puzzleDay = j['puzzleDay'] ?? '';
        puzzleDoneDay = j['puzzleDoneDay'] ?? '';
        puzzleLevel = j['puzzleLevel'] ?? 1;
        puzzleGuesses = j['puzzleGuesses'] ?? '';
        puzzleLastWin = j['puzzleLastWin'] ?? '';
        puzzleStreak = j['puzzleStreak'] ?? 0;
        puzzleBest = j['puzzleBest'] ?? 0;
        habitDone = Set<String>.from(j['habitDone'] ?? []);
        mood = Map<String, int>.from(j['mood'] ?? {});
        water = Map<String, int>.from(j['water'] ?? {});
      } catch (_) {
        // Corrupt store: start clean rather than crash on launch.
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'onboarded': onboarded,
        'name': name,
        'kcalGoal': kcalGoal,
        'weightKg': weightKg,
        'weeklyMinutesGoal': weeklyMinutesGoal,
        'waterGoal': waterGoal,
        'themeMode': themeMode.index,
        'themeName': themeName,
        'blackDark': blackDark,
        'remindersOn': remindersOn,
        'remindersOff': remindersOff.toList(),
        'foods': foods.map((e) => e.toJson()).toList(),
        'workouts': workouts.map((e) => e.toJson()).toList(),
        'people': people.map((e) => e.toJson()).toList(),
        'habits': habits.map((e) => e.toJson()).toList(),
        'proofs': proofs.map((e) => e.toJson()).toList(),
        'memories': memories.map((e) => e.toJson()).toList(),
        'alarms': alarms.map((e) => e.toJson()).toList(),
        'savedWords': savedWords,
        'puzzleDay': puzzleDay,
        'puzzleDoneDay': puzzleDoneDay,
        'puzzleLevel': puzzleLevel,
        'puzzleGuesses': puzzleGuesses,
        'puzzleLastWin': puzzleLastWin,
        'puzzleStreak': puzzleStreak,
        'puzzleBest': puzzleBest,
        'habitDone': habitDone.toList(),
        'mood': mood,
        'water': water,
      }),
    );
  }

  /// Rebuilds the UI without saving, after something outside the state loads.
  void refresh() => notifyListeners();

  void _changed() {
    notifyListeners();
    _save();
    onChanged?.call(this);
  }

  void setAppearance({ThemeMode? mode, String? theme, bool? black}) {
    themeMode = mode ?? themeMode;
    themeName = theme ?? themeName;
    blackDark = black ?? blackDark;
    _changed();
  }

  void setReminders(bool on) {
    remindersOn = on;
    _changed();
  }

  void setReminderCategory(String cat, bool on) {
    on ? remindersOff.remove(cat) : remindersOff.add(cat);
    _changed();
  }

  // ---- setup -------------------------------------------------------------

  void finishOnboarding(String n, int goal) {
    name = n.trim();
    kcalGoal = goal;
    onboarded = true;
    if (habits.isEmpty) {
      habits = [
        Habit(id: newId(), title: 'Slept 7+ hours', emoji: '😴'),
        Habit(id: newId(), title: 'Stepped outside', emoji: '🌤️'),
        Habit(id: newId(), title: 'Read 10 pages', emoji: '📖'),
        Habit(id: newId(), title: 'One thing for future me', emoji: '🎯'),
      ];
    }
    _changed();
  }

  void updateSettings({
    String? name,
    int? kcalGoal,
    double? weightKg,
    int? weeklyMinutesGoal,
    ThemeMode? themeMode,
  }) {
    this.name = name ?? this.name;
    this.kcalGoal = kcalGoal ?? this.kcalGoal;
    this.weightKg = weightKg ?? this.weightKg;
    this.weeklyMinutesGoal = weeklyMinutesGoal ?? this.weeklyMinutesGoal;
    this.themeMode = themeMode ?? this.themeMode;
    _changed();
  }

  // ---- food --------------------------------------------------------------

  void addFood(String name, int kcal, String meal) {
    foods.add(FoodEntry(
        id: newId(), name: name, kcal: kcal, meal: meal, time: DateTime.now()));
    _changed();
  }

  void removeFood(String id) {
    foods.removeWhere((f) => f.id == id);
    _changed();
  }

  List<FoodEntry> foodsOn(DateTime d) =>
      foods.where((f) => dk(f.time) == dk(d)).toList();

  int kcalOn(DateTime d) => foodsOn(d).fold(0, (a, f) => a + f.kcal);

  // ---- workouts ----------------------------------------------------------

  void addWorkout(String type, int minutes, int intensity) {
    workouts.add(Workout(
        id: newId(),
        type: type,
        minutes: minutes,
        intensity: intensity,
        time: DateTime.now()));
    _changed();
  }

  void removeWorkout(String id) {
    workouts.removeWhere((w) => w.id == id);
    _changed();
  }

  List<Workout> workoutsOn(DateTime d) =>
      workouts.where((w) => dk(w.time) == dk(d)).toList();

  int minutesOn(DateTime d) => workoutsOn(d).fold(0, (a, w) => a + w.minutes);

  int burnedOn(DateTime d) =>
      workoutsOn(d).fold(0, (a, w) => a + w.kcal(weightKg));

  /// The last seven days, oldest first, ending today.
  List<DateTime> get last7 {
    final t = dayOf(DateTime.now());
    return List.generate(7, (i) => t.subtract(Duration(days: 6 - i)));
  }

  int get weekMinutes => last7.fold(0, (a, d) => a + minutesOn(d));

  /// Consecutive active days. Today not being done yet does not break it.
  int get streak {
    var d = dayOf(DateTime.now());
    if (minutesOn(d) == 0) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (minutesOn(d) > 0) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  int? get daysSinceWorkout {
    if (workouts.isEmpty) return null;
    final last =
        workouts.map((w) => w.time).reduce((a, b) => a.isAfter(b) ? a : b);
    return dayOf(DateTime.now()).difference(dayOf(last)).inDays;
  }

  // ---- people ------------------------------------------------------------

  void addPerson(String name, int everyDays) {
    people.add(Person(id: newId(), name: name.trim(), everyDays: everyDays));
    _changed();
  }

  void removePerson(String id) {
    people.removeWhere((p) => p.id == id);
    _changed();
  }

  void markContacted(String id) {
    people.firstWhere((p) => p.id == id).lastContact = DateTime.now();
    _changed();
  }

  List<Person> get peopleByDrift =>
      [...people]..sort((a, b) => b.drift.compareTo(a.drift));

  List<Person> get overduePeople =>
      peopleByDrift.where((p) => p.overdue).toList();

  // ---- self --------------------------------------------------------------

  String get _today => dk(DateTime.now());

  bool habitDoneToday(String id) => habitDone.contains('$_today|$id');

  void toggleHabit(String id) {
    final k = '$_today|$id';
    habitDone.contains(k) ? habitDone.remove(k) : habitDone.add(k);
    _changed();
  }

  void addHabit(String title, String emoji) {
    habits.add(Habit(id: newId(), title: title.trim(), emoji: emoji));
    _changed();
  }

  void removeHabit(String id) {
    habits.removeWhere((h) => h.id == id);
    _changed();
  }

  int get habitsDoneToday => habits.where((h) => habitDoneToday(h.id)).length;

  int? get moodToday => mood[_today];

  void setMood(int v) {
    mood[_today] = v;
    _changed();
  }

  int get waterToday => water[_today] ?? 0;

  void addWater(int delta) {
    water[_today] = (waterToday + delta).clamp(0, 30);
    _changed();
  }

  void addProof(String text) {
    proofs.insert(
        0, Proof(id: newId(), text: text.trim(), time: DateTime.now()));
    _changed();
  }

  void removeProof(String id) {
    proofs.removeWhere((p) => p.id == id);
    _changed();
  }

  // ---- dictionary --------------------------------------------------------

  void toggleWord(String word) {
    savedWords.contains(word) ? savedWords.remove(word) : savedWords.add(word);
    _changed();
  }

  // ---- daily puzzle ------------------------------------------------------

  /// Letters tried so far today (yesterday's are forgotten).
  String get puzzleGuessesToday => puzzleDay == _today ? puzzleGuesses : '';

  /// Days solved in a row, counting only a run that is still alive.
  int get puzzleStreakNow {
    final yesterday =
        dk(DateTime.now().subtract(const Duration(days: 1)));
    return puzzleLastWin == _today || puzzleLastWin == yesterday
        ? puzzleStreak
        : 0;
  }

  bool get puzzleDoneToday => puzzleDoneDay == _today;

  /// Changing level mid-game would change the free letters, so it applies
  /// from the next puzzle unless today's has not been started.
  void setPuzzleLevel(int level) {
    puzzleLevel = level;
    _changed();
  }

  /// Stores the letters tried today. [won] and [lost] say how it ended.
  void recordPuzzle(String guesses, {required bool won, required bool lost}) {
    puzzleDay = _today;
    puzzleGuesses = guesses;
    if (won || lost) puzzleDoneDay = _today;
    if (won && puzzleLastWin != _today) {
      puzzleStreak = puzzleStreakNow + 1;
      puzzleLastWin = _today;
      if (puzzleStreak > puzzleBest) puzzleBest = puzzleStreak;
    } else if (lost) {
      puzzleStreak = 0;
    }
    _changed();
  }

  // ---- wake-up alarms ----------------------------------------------------

  /// Creates an alarm, or updates the one with [id]. Saving switches it on.
  void saveAlarm({
    int? id,
    required int hour,
    required int minute,
    String label = '',
    bool daily = true,
  }) {
    if (id == null) {
      // Small ids, clear of the ones reminders use for notifications.
      var next = 1000;
      for (final a in alarms) {
        if (a.id >= next) next = a.id + 1;
      }
      alarms.add(WakeAlarm(
          id: next, hour: hour, minute: minute, label: label, daily: daily));
    } else {
      final a = alarms.firstWhere((a) => a.id == id);
      a
        ..hour = hour
        ..minute = minute
        ..label = label
        ..daily = daily
        ..enabled = true;
    }
    _changed();
  }

  void setAlarmEnabled(int id, bool on) {
    alarms.firstWhere((a) => a.id == id).enabled = on;
    _changed();
  }

  void removeAlarm(int id) {
    alarms.removeWhere((a) => a.id == id);
    _changed();
  }

  /// The quiz was solved: a one-off alarm is finished, a daily one stays on
  /// and is rescheduled for tomorrow.
  void alarmBeaten(int id) {
    for (final a in alarms) {
      if (a.id == id && !a.daily) a.enabled = false;
    }
    _changed();
  }

  // ---- memories ----------------------------------------------------------

  void addMemory(Memory m) {
    memories.insert(0, m);
    _changed();
  }

  void updateMemory(String id, String title, String note, DateTime? remindAt) {
    final m = memories.firstWhere((m) => m.id == id);
    m.title = title;
    m.note = note;
    m.remindAt = remindAt;
    _changed();
  }

  void removeMemory(String id) {
    memories.removeWhere((m) => m.id == id);
    _changed();
  }

  /// Adds another confirmed sighting so the thing is recognised more easily.
  void reinforceMemory(String id, Signature seen) {
    final m = memories.firstWhere((m) => m.id == id);
    if (m.signatures.length >= maxSignaturesPerMemory) return;
    m.signatures.add(seen);
    _changed();
  }

  // ---- the life score ----------------------------------------------------
  // Four equal quarters, each 0..1. Deliberately forgiving: showing up counts.

  double get fuelScore {
    final eaten = kcalOn(DateTime.now());
    if (eaten == 0) return 0;
    final r = eaten / kcalGoal;
    // Logging at all is half the credit; the rest is landing near the goal.
    double fit;
    if (r < 0.75) {
      fit = r / 0.75;
    } else if (r <= 1.1) {
      fit = 1;
    } else {
      fit = (1 - (r - 1.1) / 0.5).clamp(0.0, 1.0);
    }
    return 0.5 + 0.5 * fit;
  }

  double get moveScore =>
      (weekMinutes / weeklyMinutesGoal).clamp(0.0, 1.0).toDouble();

  double get peopleScore {
    if (people.isEmpty) return 0;
    return people.where((p) => !p.overdue).length / people.length;
  }

  double get selfScore {
    final parts = <double>[
      (waterToday / waterGoal).clamp(0.0, 1.0).toDouble(),
      moodToday == null ? 0 : 1,
      if (habits.isNotEmpty) habitsDoneToday / habits.length,
    ];
    return parts.reduce((a, b) => a + b) / parts.length;
  }

  int get lifeScore =>
      ((fuelScore + moveScore + peopleScore + selfScore) * 25).round();
}

class AndyScope extends InheritedNotifier<AppState> {
  const AndyScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AndyScope>()!.notifier!;
}
