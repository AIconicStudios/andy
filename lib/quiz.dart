import 'dart:math';

/// One multiple-choice question. Hard enough that you have to be awake,
/// short enough to answer on a phone at 6am.
class Quiz {
  Quiz(this.kind, this.prompt, this.options, this.answer);
  final String kind;
  final String prompt;
  final List<String> options;

  /// Index into [options].
  final int answer;
}

/// How many must be answered correctly to silence the alarm.
const quizzesToSolve = 5;

T _pick<T>(Random r, List<T> from) => from[r.nextInt(from.length)];

/// Shuffles the right answer in among three distinct wrong ones.
Quiz _build(Random r, String kind, String prompt, String right,
    Iterable<String> wrong) {
  final options = <String>{right, ...wrong}.take(4).toList();
  assert(options.length == 4, 'need three distinct wrong answers: $prompt');
  options.shuffle(r);
  return Quiz(kind, prompt, options, options.indexOf(right));
}

/// Near-miss numbers around [right], so guessing by size does not work.
Iterable<String> _near(Random r, int right, [List<int> hints = const []]) {
  final out = <int>{};
  for (final h in hints) {
    if (h != right) out.add(h);
  }
  final spread = max(3, (right.abs() * 0.15).round());
  while (out.length < 3) {
    final delta = r.nextInt(spread * 2 + 1) - spread;
    final v = right + delta;
    if (delta != 0 && (right < 0 || v >= 0)) out.add(v);
  }
  return out.map((v) => '$v');
}

Quiz _sequence(Random r) {
  late List<int> shown;
  late int next;
  switch (r.nextInt(6)) {
    case 0: // constant step
      final start = r.nextInt(30) + 1, step = (r.nextInt(11) + 2) * (r.nextBool() ? 1 : -1);
      final all = List.generate(6, (i) => start + 60 + step * i);
      shown = all.sublist(0, 5);
      next = all[5];
    case 1: // multiply
      final start = r.nextInt(4) + 1, factor = r.nextInt(2) + 2;
      final all = List.generate(6, (i) => start * pow(factor, i).toInt());
      shown = all.sublist(0, 5);
      next = all[5];
    case 2: // squares plus a constant
      final from = r.nextInt(4) + 1, c = r.nextInt(7) - 3;
      final all = List.generate(6, (i) => (from + i) * (from + i) + c);
      shown = all.sublist(0, 5);
      next = all[5];
    case 3: // each is the sum of the two before
      final all = [r.nextInt(5) + 1, r.nextInt(6) + 2];
      while (all.length < 7) {
        all.add(all[all.length - 1] + all[all.length - 2]);
      }
      shown = all.sublist(0, 6);
      next = all[6];
    case 4: // two steps taking turns
      final a = r.nextInt(6) + 2, b = r.nextInt(6) + 8;
      final all = [r.nextInt(10) + 1];
      for (var i = 0; i < 6; i++) {
        all.add(all.last + (i.isEven ? a : b));
      }
      shown = all.sublist(0, 6);
      next = all[6];
    default: // the step grows by one each time
      final first = r.nextInt(4) + 1;
      final all = [r.nextInt(10) + 1];
      for (var i = 0; i < 6; i++) {
        all.add(all.last + first + i);
      }
      shown = all.sublist(0, 6);
      next = all[6];
  }
  final step = shown.last - shown[shown.length - 2];
  return _build(r, 'Sequence', 'What comes next?\n${shown.join(',  ')},  ?',
      '$next', _near(r, next, [shown.last + step, next + 1, next - 2]));
}

Quiz _arithmetic(Random r) {
  switch (r.nextInt(4)) {
    case 0: // multiplication comes before addition
      final a = r.nextInt(12) + 4, b = r.nextInt(7) + 3, c = r.nextInt(7) + 3;
      return _build(r, 'Arithmetic', '$a + $b × $c = ?', '${a + b * c}',
          _near(r, a + b * c, [(a + b) * c, a * b + c]));
    case 1:
      final a = r.nextInt(8) + 12, b = r.nextInt(6) + 4, c = r.nextInt(30) + 11;
      return _build(r, 'Arithmetic', '$a × $b − $c = ?', '${a * b - c}',
          _near(r, a * b - c, [a * (b - 1) - c, a * b + c]));
    case 2:
      final pct = _pick(r, [15, 20, 25, 30, 40, 60, 75]);
      final of = (r.nextInt(18) + 3) * 20;
      final right = pct * of ~/ 100;
      return _build(r, 'Arithmetic', 'What is $pct% of $of?', '$right',
          _near(r, right, [right + of ~/ 20, right - of ~/ 20]));
    default:
      final a = r.nextInt(9) + 6, b = r.nextInt(9) + 6, c = r.nextInt(5) + 3;
      return _build(r, 'Arithmetic', '($a + $b) × $c = ?', '${(a + b) * c}',
          _near(r, (a + b) * c, [a + b * c, (a + b) * (c + 1)]));
  }
}

const _groups = {
  'fruit': ['Mango', 'Orange', 'Pineapple', 'Banana', 'Pawpaw', 'Guava'],
  'metal': ['Iron', 'Copper', 'Gold', 'Silver', 'Zinc', 'Tin'],
  'instrument': ['Guitar', 'Drum', 'Flute', 'Violin', 'Trumpet', 'Piano'],
  'planet': ['Mars', 'Venus', 'Saturn', 'Jupiter', 'Neptune', 'Mercury'],
  'bird': ['Eagle', 'Parrot', 'Owl', 'Sparrow', 'Heron', 'Falcon'],
  'tool': ['Hammer', 'Spanner', 'Chisel', 'Pliers', 'Saw', 'Drill'],
  'river': ['Nile', 'Volta', 'Niger', 'Congo', 'Amazon', 'Danube'],
  'shape': ['Triangle', 'Square', 'Hexagon', 'Circle', 'Pentagon', 'Oval'],
  'fabric': ['Cotton', 'Silk', 'Wool', 'Linen', 'Denim', 'Velvet'],
  'organ': ['Heart', 'Liver', 'Kidney', 'Lung', 'Stomach', 'Brain'],
};

Quiz _oddOneOut(Random r) {
  final names = _groups.keys.toList()..shuffle(r);
  final same = [..._groups[names[0]]!]..shuffle(r);
  final odd = _pick(r, _groups[names[1]]!);
  return _build(
      r, 'Odd one out', 'Which one does not belong?', odd, same.take(3));
}

// first is to second as third is to answer; then three wrong answers.
const _analogies = [
  ['Hot', 'Cold', 'Up', 'Down', 'High', 'Over', 'Sky'],
  ['Bird', 'Nest', 'Bee', 'Hive', 'Honey', 'Flower', 'Wing'],
  ['Pen', 'Write', 'Knife', 'Cut', 'Sharp', 'Fork', 'Kitchen'],
  ['Doctor', 'Hospital', 'Teacher', 'School', 'Student', 'Lesson', 'Book'],
  ['Eye', 'See', 'Ear', 'Hear', 'Sound', 'Head', 'Listen to'],
  ['Day', 'Week', 'Month', 'Year', 'Hour', 'Calendar', 'Season'],
  ['Seed', 'Tree', 'Egg', 'Bird', 'Shell', 'Nest', 'Yolk'],
  ['Fish', 'Water', 'Bird', 'Air', 'Feather', 'Nest', 'Tree'],
  ['Hungry', 'Eat', 'Tired', 'Sleep', 'Bed', 'Yawn', 'Night'],
  ['Author', 'Book', 'Composer', 'Music', 'Piano', 'Concert', 'Singer'],
  ['Wheel', 'Car', 'Wing', 'Plane', 'Bird', 'Sky', 'Pilot'],
  ['Cup', 'Drink', 'Plate', 'Eat', 'Food', 'Table', 'Spoon'],
  ['Clock', 'Time', 'Scale', 'Weight', 'Heavy', 'Kilogram', 'Balance'],
  ['Kitten', 'Cat', 'Calf', 'Cow', 'Milk', 'Farm', 'Bull'],
  ['Finger', 'Hand', 'Toe', 'Foot', 'Leg', 'Shoe', 'Nail'],
  ['Rain', 'Wet', 'Sun', 'Dry', 'Hot day', 'Cloud', 'Light'],
];

Quiz _analogy(Random r) {
  final a = _pick(r, _analogies);
  return _build(r, 'Analogy', '${a[0]} is to ${a[1]}\nas ${a[2]} is to ?',
      a[3], a.sublist(4));
}

Quiz _letters(Random r) {
  final step = r.nextInt(4) + 1;
  final back = r.nextInt(4) == 0;
  final start = back ? 25 - r.nextInt(4) : r.nextInt(26 - step * 5);
  String at(int i) =>
      String.fromCharCode(65 + (back ? start - step * i : start + step * i));
  final right = at(4);
  final code = right.codeUnitAt(0) - 65;
  final wrong = <String>{};
  for (final d in [1, -1, 2, -2, 3, -3]) {
    final c = code + d;
    if (c >= 0 && c < 26 && wrong.length < 3) {
      wrong.add(String.fromCharCode(65 + c));
    }
  }
  return _build(r, 'Letters',
      'What comes next?\n${List.generate(4, at).join(',  ')},  ?', right, wrong);
}

const _names = ['Ama', 'Kofi', 'Yaw', 'Esi', 'Kojo', 'Adwoa', 'Kwame', 'Abena'];

// Classic trick questions: the tempting answer is listed first among the
// wrong ones.
const _riddles = [
  ['A bat and a ball cost 110 in total. The bat costs 100 more than the ball. What does the ball cost?', '5', '10', '15', '1'],
  ['5 machines make 5 parts in 5 minutes. How many minutes do 100 machines need to make 100 parts?', '5', '100', '20', '50'],
  ['A pond weed doubles in size every day and covers the pond on day 48. On which day did it cover half?', '47', '24', '12', '46'],
  ['You overtake the runner in second place. What place are you in now?', 'Second', 'First', 'Third', 'Last'],
  ['How many months of the year have 28 days?', '12', '1', '2', '11'],
  ['A farmer has 17 sheep. All but 9 run away. How many are left?', '9', '8', '17', '26'],
  ['If you have 6 apples and take away 4, how many do you have?', '4', '2', '6', '10'],
  ['A clock strikes 6 in 5 seconds. How many seconds does it take to strike 12?', '11', '10', '12', '6'],
  ['Divide 30 by a half and add 10. What do you get?', '70', '25', '40', '20'],
  ['Some months have 31 days. How many days are there in 3 weeks and 3 days?', '24', '21', '23', '27'],
];

Quiz _logic(Random r) {
  switch (r.nextInt(3)) {
    case 0: // put three people in order
      final n = [..._names]..shuffle(r);
      final tallest = r.nextBool();
      return _build(
          r,
          'Logic',
          '${n[0]} is taller than ${n[1]}.\n${n[2]} is shorter than ${n[1]}.\n'
              'Who is the ${tallest ? 'tallest' : 'shortest'}?',
          tallest ? n[0] : n[2],
          [tallest ? n[2] : n[0], n[1], 'Cannot tell']);
    case 1: // what day is it
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final today = r.nextInt(7), ahead = r.nextInt(3) + 2;
      // "the day after tomorrow" style, but stated from yesterday.
      final right = days[(today + ahead) % 7];
      return _build(
          r,
          'Logic',
          'Yesterday was ${days[(today + 6) % 7]}.\nWhat day is it $ahead days from today?',
          right,
          [days[(today + ahead + 1) % 7], days[(today + ahead + 6) % 7], days[(today + ahead + 2) % 7]]);
    default:
      final q = _pick(r, _riddles);
      return _build(r, 'Think twice', q[0], q[1], q.sublist(2));
  }
}

Quiz _rule(Random r) {
  // Work out the hidden rule from two examples, then apply it.
  final kind = r.nextInt(3);
  final m = r.nextInt(4) + 2, c = r.nextInt(9) + 1;
  int f(int x) => switch (kind) { 0 => x * x, 1 => x * m + c, _ => x * x - x };
  // Three examples, so only one simple rule fits them all.
  final xs = ([2, 3, 4, 5, 6, 7, 8, 9]..shuffle(r)).take(4).toList()..sort();
  final right = f(xs[3]);
  return _build(
      r,
      'Hidden rule',
      'Find the rule.\n${xs[0]} → ${f(xs[0])}\n${xs[1]} → ${f(xs[1])}\n'
          '${xs[2]} → ${f(xs[2])}\n${xs[3]} → ?',
      '$right',
      _near(r, right, [right + xs[3], right - m, f(xs[2]) + (f(xs[2]) - f(xs[1]))]));
}

const _makers = [_sequence, _arithmetic, _oddOneOut, _analogy, _letters, _logic, _rule];

/// A fresh random question. [not] avoids repeating the previous kind.
Quiz randomQuiz(Random r, {String? not}) {
  while (true) {
    final q = _pick(r, _makers)(r);
    if (q.kind != not) return q;
  }
}
