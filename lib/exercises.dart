import 'exercise_demos.dart';
import 'silhouette.dart';

enum Area { push, pull, legs, core }

const areaNames = {
  Area.push: 'Push',
  Area.pull: 'Pull',
  Area.legs: 'Legs',
  Area.core: 'Core',
};

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.area,
    required this.muscles,
    required this.lo,
    required this.hi,
    required this.steps,
    this.seconds = false,
    this.perSide = false,
    this.needs = '',
    this.safety = '',
    this.harder,
    this.easier,
    this.harderTip = '',
  });
  final String id;
  final String name;
  final Area area;
  final String muscles;

  /// Target range per set: reps, or seconds when [seconds] is true.
  final int lo, hi;
  final bool seconds;

  /// Reps are counted for each leg.
  final bool perSide;
  final String needs;
  final List<String> steps;
  final String safety;

  /// Ids of the next step up and down, if there is one.
  final String? harder, easier;

  /// How to make it harder when there is no harder exercise.
  final String harderTip;

  String get unit => seconds ? 's' : (perSide ? 'reps each leg' : 'reps');
  String get unitShort => seconds ? 's' : 'reps';
  String get range => seconds ? '$lo–$hi s' : '$lo–$hi $unit';
  Demo get demo => demos[id]!;
}

const exercises = <String, Exercise>{
  'incline_pushup': Exercise(
    id: 'incline_pushup',
    name: 'Incline push-up',
    area: Area.push,
    muscles: 'Chest, shoulders, triceps',
    lo: 8,
    hi: 20,
    needs: 'A pillar, bench or sturdy chair',
    steps: [
      'Put your hands on the edge of a pillar or sturdy chair, a little wider than your shoulders.',
      'Walk your feet back until your body is one straight line from head to heels.',
      'Lower your chest to the edge, elbows angled back about 45° from your body.',
      'Push back up until your arms are straight.',
    ],
    safety: 'Squeeze your glutes so your hips do not sag.',
    harder: 'pushup',
  ),
  'pushup': Exercise(
    id: 'pushup',
    name: 'Push-up',
    area: Area.push,
    muscles: 'Chest, shoulders, triceps',
    lo: 8,
    hi: 20,
    steps: [
      'Hands on the floor just wider than your shoulders, under your chest.',
      'Body straight from head to heels, core tight.',
      'Lower until your chest is a fist from the floor, elbows angled back.',
      'Push the floor away until your arms are straight.',
    ],
    safety: 'Stop the set when your hips sag or your lower back arches.',
    easier: 'incline_pushup',
    harder: 'elevated_pushup',
  ),
  'elevated_pushup': Exercise(
    id: 'elevated_pushup',
    name: 'Feet-elevated push-up',
    area: Area.push,
    muscles: 'Upper chest, shoulders, triceps',
    lo: 6,
    hi: 15,
    needs: 'A chair or bed for your feet',
    steps: [
      'Feet on a chair or the edge of a bed, hands on the floor under your shoulders.',
      'Keep your body in one straight line.',
      'Lower your chest towards the floor with elbows angled back.',
      'Press back up to straight arms.',
    ],
    safety: 'Make sure the chair cannot slide away behind you.',
    easier: 'pushup',
    harderTip: 'Lower over 3 seconds and pause at the bottom.',
  ),
  'pike_pushup': Exercise(
    id: 'pike_pushup',
    name: 'Pike push-up',
    area: Area.push,
    muscles: 'Shoulders, triceps',
    lo: 6,
    hi: 12,
    steps: [
      'Start in a push-up, then walk your feet in and lift your hips high into an upside-down V.',
      'Bend your elbows and lower the top of your head towards the floor, just in front of your hands.',
      'Press back up until your arms are straight.',
    ],
    safety: 'Lower slowly. Your head should never hit the floor.',
    harderTip: 'Put your feet on a chair to make it steeper.',
  ),
  'support_hold': Exercise(
    id: 'support_hold',
    name: 'Support hold',
    area: Area.push,
    muscles: 'Triceps, shoulders, core',
    lo: 15,
    hi: 45,
    seconds: true,
    needs: 'Two short, solid pillars',
    steps: [
      'Put one hand firmly on each pillar and check they will not move.',
      'Push down to lift yourself with your arms locked straight.',
      'Bend your knees so your feet stay off the floor.',
      'Keep your shoulders pressed down, away from your ears, and hold.',
    ],
    safety: 'Wrists straight. Step down if a pillar shifts at all.',
    harder: 'pillar_dip',
  ),
  'pillar_dip': Exercise(
    id: 'pillar_dip',
    name: 'Pillar dip',
    area: Area.push,
    muscles: 'Triceps, chest, front shoulders',
    lo: 6,
    hi: 15,
    needs: 'Two short, solid pillars',
    steps: [
      'One hand on each pillar, wrists straight, and check they feel completely solid.',
      'Lift yourself with your arms locked, shoulders down, knees bent so your feet stay up.',
      'Slowly bend your elbows until your upper arms are about level with the floor.',
      'Push firmly back up, without snapping your elbows straight.',
    ],
    safety:
        'Do not go lower if you feel any sharp pinching at the front of your shoulders.',
    easier: 'support_hold',
    harderTip: 'Lower over 3 seconds and pause for a second at the bottom.',
  ),
  'towel_row': Exercise(
    id: 'towel_row',
    name: 'Towel row',
    area: Area.pull,
    muscles: 'Upper back, lats, biceps',
    lo: 8,
    hi: 15,
    needs: 'A thick towel and a pillar or post',
    steps: [
      'Wrap a thick, sturdy towel around a pillar and grab both ends.',
      'Plant your feet close to the base of the pillar.',
      'Lean back with straight arms until your body makes an angle.',
      'Pull your chest towards your hands, squeezing your shoulder blades together.',
      'Lower back slowly.',
    ],
    safety: 'Check the towel will not slip off the pillar before you lean back.',
    harder: 'table_row',
    harderTip: 'Walk your feet closer to the pillar so you lean back further.',
  ),
  'table_row': Exercise(
    id: 'table_row',
    name: 'Table row',
    area: Area.pull,
    muscles: 'Upper back, lats, biceps',
    lo: 6,
    hi: 15,
    needs: 'A strong table that cannot tip',
    steps: [
      'Lie under a sturdy table and grip its edge, hands shoulder-width apart.',
      'Heels on the floor, body straight from head to heels.',
      'Pull your chest up to the edge of the table.',
      'Lower yourself slowly until your arms are straight.',
    ],
    safety: 'Test the table first: it must not tip or slide when you pull.',
    easier: 'towel_row',
    harderTip: 'Put your feet up on a chair.',
  ),
  'towel_curl': Exercise(
    id: 'towel_curl',
    name: 'Towel bicep curl',
    area: Area.pull,
    muscles: 'Biceps, forearms',
    lo: 8,
    hi: 15,
    needs: 'A thick towel and a pillar or post',
    steps: [
      'Loop a sturdy bath towel around a short pillar and grab the ends, palms facing up.',
      'Walk your feet close to the pillar and lean back with straight arms.',
      'Keep your elbows pinned in place and curl your body up towards your hands.',
      'Squeeze your biceps at the top, then lower slowly.',
    ],
    safety: 'Only your elbows bend. If your back does the work, lean back less.',
    harderTip: 'Lean back further, or pause for 2 seconds at the top.',
  ),
  'squat': Exercise(
    id: 'squat',
    name: 'Bodyweight squat',
    area: Area.legs,
    muscles: 'Thighs, glutes',
    lo: 15,
    hi: 25,
    steps: [
      'Feet shoulder-width apart, toes turned out a little.',
      'Sit your hips back and down until your thighs are about level with the floor.',
      'Keep your chest up and your knees tracking over your toes.',
      'Drive up through your heels to standing.',
    ],
    safety: 'Heels stay down. Only go as low as you can keep your back straight.',
    harder: 'bulgarian_split_squat',
  ),
  'reverse_lunge': Exercise(
    id: 'reverse_lunge',
    name: 'Reverse lunge',
    area: Area.legs,
    muscles: 'Thighs, glutes',
    lo: 10,
    hi: 15,
    perSide: true,
    steps: [
      'Stand tall, feet hip-width apart.',
      'Take a big step back and lower your back knee towards the floor.',
      'Both knees bend to about 90°, front knee over your ankle.',
      'Push through your front heel to step back up. Switch legs.',
    ],
    safety: 'Lower the back knee gently. Do not slam it into the floor.',
    harder: 'bulgarian_split_squat',
  ),
  'bulgarian_split_squat': Exercise(
    id: 'bulgarian_split_squat',
    name: 'Bulgarian split squat',
    area: Area.legs,
    muscles: 'Thighs, glutes',
    lo: 8,
    hi: 15,
    perSide: true,
    needs: 'A chair or bed behind you',
    steps: [
      'Stand a big step in front of a chair and rest the top of your back foot on it.',
      'Lower straight down until your front thigh is about level with the floor.',
      'Keep your chest up and your front knee over your ankle.',
      'Drive up through your front heel. Do every rep, then switch legs.',
    ],
    safety: 'Use a chair that cannot slide, and hold a wall for balance at first.',
    easier: 'squat',
    harderTip: 'Lower over 3 seconds, or pause at the bottom.',
  ),
  'plank': Exercise(
    id: 'plank',
    name: 'Plank',
    area: Area.core,
    muscles: 'Abs, deep core, shoulders',
    lo: 30,
    hi: 60,
    seconds: true,
    steps: [
      'Forearms on the floor, elbows under your shoulders.',
      'Step your feet back so your body is one straight line.',
      'Squeeze your glutes and brace your stomach as if someone might poke it.',
      'Breathe slowly and hold.',
    ],
    safety: 'Stop when your hips start to sag.',
    harderTip: 'Lift one foot for 5 seconds at a time, or add 10 seconds a session.',
  ),
  'leg_raise': Exercise(
    id: 'leg_raise',
    name: 'Lying leg raise',
    area: Area.core,
    muscles: 'Lower abs, hip flexors',
    lo: 8,
    hi: 15,
    steps: [
      'Lie on your back, legs straight, hands flat by your sides or under your hips.',
      'Press your lower back into the floor.',
      'Keep your legs straight and raise them until they point at the ceiling.',
      'Lower slowly and stop just before your heels touch the floor.',
    ],
    safety: 'If your lower back lifts off the floor, bend your knees a little.',
    harderTip: 'Lower over 4 seconds and keep your heels hovering between reps.',
  ),
};

// ---- the plan ---------------------------------------------------------------

/// A place in a routine. Each slot holds one exercise from a ladder of
/// easier and harder versions; progress moves the slot up the ladder.
const slotLadders = <String, List<String>>{
  'push': ['incline_pushup', 'pushup', 'elevated_pushup'],
  'dip': ['support_hold', 'pillar_dip'],
  'pike': ['pike_pushup'],
  'pull': ['towel_row', 'table_row'],
  'curl': ['towel_curl'],
  'squat': ['squat', 'bulgarian_split_squat'],
  'lunge': ['reverse_lunge', 'bulgarian_split_squat'],
  'plank': ['plank'],
  'raise': ['leg_raise'],
};

const defaultVariants = {
  'push': 'pushup',
  'dip': 'pillar_dip',
  'pike': 'pike_pushup',
  'pull': 'towel_row',
  'curl': 'towel_curl',
  'squat': 'squat',
  'lunge': 'reverse_lunge',
  'plank': 'plank',
  'raise': 'leg_raise',
};

class Routine {
  const Routine(this.id, this.name, this.blocks);
  final String id;
  final String name;

  /// (slot, sets) in order.
  final List<(String, int)> blocks;
}

/// Two routines, taken in turn: about 30 minutes each.
const routines = [
  Routine('a', 'Push & legs', [
    ('push', 3),
    ('dip', 3),
    ('pike', 2),
    ('squat', 3),
    ('plank', 2),
  ]),
  Routine('b', 'Pull & core', [
    ('pull', 3),
    ('curl', 3),
    ('lunge', 3),
    ('raise', 3),
    ('plank', 2),
  ]),
];

Routine routineById(String id) =>
    routines.firstWhere((r) => r.id == id, orElse: () => routines.first);

/// The routine after [last], or the first one.
Routine nextRoutine(String last) {
  final i = routines.indexWhere((r) => r.id == last);
  return routines[(i + 1) % routines.length];
}

/// The slot in [routine] that [exerciseId] currently fills, if any.
String? slotOf(String exerciseId, Map<String, String> variants) {
  for (final e in variants.entries) {
    if (e.value == exerciseId) return e.key;
  }
  return null;
}

// ---- logs and judgement -------------------------------------------------------

/// How hard a set felt: how many more reps were left in the tank.
enum Effort { easy, hard, max }

const effortLabels = {
  Effort.easy: ('Easy', '3+ left'),
  Effort.hard: ('Hard', '1–2 left'),
  Effort.max: ('Max', 'nothing left'),
};

class SetLog {
  SetLog({
    required this.exercise,
    required this.day,
    required this.amount,
    required this.effort,
  });
  final String exercise;

  /// Date key, yyyy-mm-dd.
  final String day;

  /// Reps, or seconds held.
  final int amount;
  final Effort effort;

  Map<String, dynamic> toJson() =>
      {'e': exercise, 'd': day, 'a': amount, 'f': effort.index};
  static SetLog fromJson(Map<String, dynamic> j) => SetLog(
        exercise: j['e'],
        day: j['d'],
        amount: j['a'],
        effort: Effort.values[j['f'] ?? 1],
      );
}

enum Tone { great, good, push, ease }

class Verdict {
  const Verdict(this.tone, this.title, this.detail);
  final Tone tone;
  final String title;
  final String detail;
}

/// Andy's take on one set. [previous] is the same set number last session.
Verdict judgeSet(Exercise e, int amount, Effort effort, {int? previous}) {
  final u = e.unitShort;
  final vs = previous == null
      ? ''
      : amount > previous
          ? ' That is ${amount - previous} more than last time.'
          : amount == previous
              ? ' Same as last time.'
              : '';
  if (amount > e.hi) {
    final up = exercises[e.harder];
    return Verdict(
        Tone.great,
        'Above the range',
        up != null
            ? 'Over ${e.hi} $u means it is getting easy. Next session, move up to ${up.name}.$vs'
            : 'Over ${e.hi} $u means it is getting easy. ${e.harderTip}$vs');
  }
  if (amount >= e.lo) {
    return switch (effort) {
      Effort.easy => Verdict(Tone.push, 'Good, but too comfortable',
          'Muscle grows when the last reps are a fight. Next set, keep going until only 1 or 2 are left.$vs'),
      Effort.hard => Verdict(Tone.great, 'Perfect set',
          'In the range with 1–2 left in the tank. This is the zone that builds visible muscle.$vs'),
      Effort.max => Verdict(Tone.good, 'Strong effort',
          'Going all the way is fine sometimes. Most sets, stop 1 or 2 short so you recover faster.$vs'),
    };
  }
  if (effort == Effort.easy) {
    return Verdict(Tone.push, 'You had more in you',
        'Below ${e.lo} $u and it felt easy. Push closer to the limit on the next set.$vs');
  }
  final down = exercises[e.easier];
  return Verdict(
      Tone.ease,
      'Below the range',
      down != null
          ? 'If your form is breaking down, switch to ${down.name} for now and build up.$vs'
          : 'Rest a little longer between sets and keep the form clean. The reps will come.$vs');
}

class Advice {
  const Advice(this.tone, this.text, {this.switchTo});
  final Tone tone;
  final String text;

  /// An exercise to swap into the plan, if Andy recommends one.
  final String? switchTo;
}

/// What to do next time, from today's sets and the last session's.
Advice recommend(Exercise e, List<SetLog> today, List<SetLog> last) {
  if (today.isEmpty) return const Advice(Tone.push, 'Skipped today.');
  final total = today.fold(0, (a, s) => a + s.amount);
  final allTop = today.every((s) => s.amount >= e.hi);
  final noneInRange = today.every((s) => s.amount < e.lo);
  if (allTop) {
    final up = exercises[e.harder];
    return up != null
        ? Advice(Tone.great,
            'Every set at the top of the range. Time to level up to ${up.name}.',
            switchTo: up.id)
        : Advice(Tone.great, 'Every set at the top of the range. ${e.harderTip}');
  }
  if (noneInRange && today.any((s) => s.effort != Effort.easy)) {
    final down = exercises[e.easier];
    return down != null
        ? Advice(Tone.ease,
            'Every set was under ${e.lo}. Build up on ${down.name}, then come back.',
            switchTo: down.id)
        : Advice(Tone.ease,
            'Under ${e.lo} on every set. Stay with it: clean reps first, more reps next.');
  }
  if (last.isEmpty) {
    return Advice(Tone.good,
        'First time logged: $total ${e.unitShort} in total. This is your number to beat.');
  }
  final before = last.fold(0, (a, s) => a + s.amount);
  if (total > before) {
    return Advice(Tone.great,
        'Up ${total - before} on last time. Keep adding a rep or two each session.');
  }
  if (total == before) {
    return Advice(Tone.good,
        'Same total as last time. Aim for one more rep on each set next session.');
  }
  return Advice(Tone.ease,
      'A little down on last time. Sleep, food and rest days count as training too.');
}
