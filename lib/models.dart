import 'dart:math';

String dk(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

final _rng = Random();
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}${_rng.nextInt(9999)}';

const meals = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

class FoodEntry {
  FoodEntry({
    required this.id,
    required this.name,
    required this.kcal,
    required this.meal,
    required this.time,
  });
  final String id;
  final String name;
  final int kcal;
  final String meal;
  final DateTime time;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kcal': kcal,
        'meal': meal,
        'time': time.toIso8601String(),
      };
  static FoodEntry fromJson(Map<String, dynamic> j) => FoodEntry(
        id: j['id'],
        name: j['name'],
        kcal: j['kcal'],
        meal: j['meal'],
        time: DateTime.parse(j['time']),
      );
}

class WorkoutType {
  const WorkoutType(this.name, this.emoji, this.met);
  final String name;
  final String emoji;
  final double met; // metabolic equivalent at moderate effort
}

const workoutTypes = [
  WorkoutType('Walk', '🚶', 3.5),
  WorkoutType('Run', '🏃', 9.0),
  WorkoutType('Weights', '🏋️', 5.0),
  WorkoutType('Cycle', '🚴', 7.0),
  WorkoutType('Football', '⚽', 7.5),
  WorkoutType('Swim', '🏊', 7.0),
  WorkoutType('HIIT', '🔥', 9.5),
  WorkoutType('Yoga', '🧘', 2.8),
  WorkoutType('Dance', '💃', 5.5),
  WorkoutType('Other', '✨', 4.5),
];

WorkoutType workoutType(String name) => workoutTypes
    .firstWhere((t) => t.name == name, orElse: () => workoutTypes.last);

const intensityLabels = ['Easy', 'Steady', 'All out'];
const _intensityFactor = [0.8, 1.0, 1.25];

class Workout {
  Workout({
    required this.id,
    required this.type,
    required this.minutes,
    required this.intensity,
    required this.time,
  });
  final String id;
  final String type;
  final int minutes;
  final int intensity; // 0..2
  final DateTime time;

  int kcal(double weightKg) => (workoutType(type).met *
          _intensityFactor[intensity] *
          weightKg *
          minutes /
          60)
      .round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'minutes': minutes,
        'intensity': intensity,
        'time': time.toIso8601String(),
      };
  static Workout fromJson(Map<String, dynamic> j) => Workout(
        id: j['id'],
        type: j['type'],
        minutes: j['minutes'],
        intensity: j['intensity'],
        time: DateTime.parse(j['time']),
      );
}

class Person {
  Person({
    required this.id,
    required this.name,
    required this.everyDays,
    this.lastContact,
  });
  final String id;
  String name;
  int everyDays;
  DateTime? lastContact;

  /// Days since last contact, or null if never logged.
  int? get daysSince => lastContact == null
      ? null
      : dayOf(DateTime.now()).difference(dayOf(lastContact!)).inDays;

  bool get overdue => daysSince == null || daysSince! > everyDays;

  /// 0 = just spoke, 1 = due now, >1 = overdue.
  double get drift => daysSince == null ? 2 : daysSince! / everyDays;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'everyDays': everyDays,
        'lastContact': lastContact?.toIso8601String(),
      };
  static Person fromJson(Map<String, dynamic> j) => Person(
        id: j['id'],
        name: j['name'],
        everyDays: j['everyDays'],
        lastContact:
            j['lastContact'] == null ? null : DateTime.parse(j['lastContact']),
      );
}

class Habit {
  Habit({required this.id, required this.title, required this.emoji});
  final String id;
  final String title;
  final String emoji;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'emoji': emoji};
  static Habit fromJson(Map<String, dynamic> j) =>
      Habit(id: j['id'], title: j['title'], emoji: j['emoji']);
}

class Proof {
  Proof({required this.id, required this.text, required this.time});
  final String id;
  final String text;
  final DateTime time;

  Map<String, dynamic> toJson() =>
      {'id': id, 'text': text, 'time': time.toIso8601String()};
  static Proof fromJson(Map<String, dynamic> j) =>
      Proof(id: j['id'], text: j['text'], time: DateTime.parse(j['time']));
}

class QuickFood {
  const QuickFood(this.name, this.kcal);
  final String name;
  final int kcal;
}

/// Rough per-serving estimates so logging takes seconds, not minutes.
const quickFoods = [
  QuickFood('Boiled egg', 78),
  QuickFood('Oats with milk', 300),
  QuickFood('Bread, 2 slices', 160),
  QuickFood('Banana', 105),
  QuickFood('Apple', 95),
  QuickFood('Orange', 62),
  QuickFood('Rice, 1 cup cooked', 205),
  QuickFood('Jollof rice, 1 plate', 450),
  QuickFood('Fried rice, 1 plate', 480),
  QuickFood('Waakye, 1 plate', 520),
  QuickFood('Banku and tilapia', 650),
  QuickFood('Fufu and light soup', 600),
  QuickFood('Kenkey and fish', 550),
  QuickFood('Fried plantain, 1 serving', 300),
  QuickFood('Beans stew, 1 cup', 280),
  QuickFood('Grilled chicken breast', 280),
  QuickFood('Fried chicken, 2 pieces', 480),
  QuickFood('Beef stew, 1 cup', 350),
  QuickFood('Pasta with sauce', 420),
  QuickFood('Pizza, 2 slices', 570),
  QuickFood('Burger', 550),
  QuickFood('Fries, medium', 365),
  QuickFood('Salad with dressing', 220),
  QuickFood('Greek yoghurt', 130),
  QuickFood('Groundnuts, handful', 170),
  QuickFood('Protein shake', 160),
  QuickFood('Soft drink, can', 140),
  QuickFood('Malt drink', 180),
  QuickFood('Beer, bottle', 150),
  QuickFood('Coffee with milk', 60),
  QuickFood('Chocolate bar', 230),
  QuickFood('Meat pie', 380),
];
