import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'state.dart';
import 'theme.dart';

/// Andy's voice: what he says, and when he says it.

const worthReminders = [
  'You are not behind. You are exactly where a person who is still trying should be.',
  'Your worth was settled the day you arrived. Everything on this screen is just maintenance.',
  'Somebody is glad you exist today, even if they forgot to say it.',
  'You have survived every single one of your worst days. That is a perfect record.',
  'You do not have to earn rest. You do not have to earn food. You do not have to earn love.',
  'The version of you from five years ago would be stunned by what you now call normal.',
  'A bad day is a page, not the book. Turn it.',
  'You are allowed to be a masterpiece and a work in progress at the same time.',
  'Discipline is just remembering what you actually want. You want a good life. Act like it.',
  'Nobody else can do your push-ups, call your people, or live your life. That makes you irreplaceable.',
  'Small is not the same as nothing. One glass of water. One text. One walk. It all counts.',
  'You are worth the effort it takes to look after you.',
  'The people who love you are not keeping score. Neither should you.',
  'Your future self is watching you right now through memories. Give them something good.',
  'Being hard on yourself has never once made you better. Being honest has. Know the difference.',
  'You bring something to every room that leaves when you do.',
  'It is not too late and you are not too far gone. That is fear talking, not facts.',
  'Comparison is a thief. Your only competition went to bed in your body last night.',
  'You are somebody\'s proof that it is possible.',
  'Tired is not the same as finished. Rest, then come back.',
  'You have something most people spend years looking for: another chance, starting now.',
  'The goal was never perfect. The goal is to keep showing up for yourself.',
  'You matter on the days you get everything done, and exactly as much on the days you get nothing done.',
  'Look after your body like it belongs to someone you love. It does.',
  'Call them. The friendship is not as fragile as your silence makes it feel.',
  'You are the adult your younger self needed. Keep being that person.',
  'One slip is an event. It only becomes a pattern if you let today copy yesterday.',
  'You are not a project to be fixed. You are a person to be cared for.',
  'Greatness is mostly boring: sleep, food, movement, people. You are doing greatness right now.',
  'Whatever you did or did not do today, you are still worth showing up for tomorrow.',
];

final _rng = Random();

String worthForToday() => worthFor(DateTime.now());

String worthFor(DateTime now) {
  final dayOfYear = now.difference(DateTime(now.year)).inDays;
  return worthReminders[dayOfYear % worthReminders.length];
}

String randomWorth({String? not}) {
  String s;
  do {
    s = worthReminders[_rng.nextInt(worthReminders.length)];
  } while (s == not);
  return s;
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 5) return 'Still up';
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String verdict(int score) {
  if (score >= 85) return 'You showed up for yourself today. Remember this feeling.';
  if (score >= 60) return 'Solid. This is what looking after yourself looks like.';
  if (score >= 30) return 'You are in it. Keep stacking small wins.';
  if (score > 0) return 'A start is a start. Pick the next easy thing.';
  return 'Blank page. Log one thing and the day is already better.';
}

class Nudge {
  Nudge(this.icon, this.color, this.text, this.tab);
  final IconData icon;
  final Color color;
  final String text;
  final int tab; // which tab fixes it
}

/// What Andy thinks deserves attention right now, most pressing first.
List<Nudge> nudgesFor(AppState s) {
  final now = DateTime.now();
  final h = now.hour;
  final out = <Nudge>[];

  // Self first: a low mood outranks every metric.
  final mood = s.moodToday;
  if (mood != null && mood <= 2) {
    out.add(Nudge(
      Icons.favorite_rounded,
      AndyColors.self,
      s.proofs.isEmpty
          ? 'Heavy day. That is allowed. Lower the bar: water, food, one message to someone safe.'
          : 'Heavy day. Remember this, in your own words: "${s.proofs[_rng.nextInt(s.proofs.length)].text}"',
      4,
    ));
  }

  // Food
  final eaten = s.kcalOn(now);
  if (eaten == 0 && h >= 10) {
    out.add(Nudge(Icons.restaurant_rounded, AndyColors.fuel,
        'Nothing logged today. What have you eaten? It takes ten seconds.', 1));
  } else if (eaten > 0 && h >= 20 && eaten < s.kcalGoal * 0.6) {
    out.add(Nudge(Icons.restaurant_rounded, AndyColors.fuel,
        'You are well under your goal. Under-eating is not a win. Eat a proper meal.', 1));
  } else if (eaten > s.kcalGoal * 1.15) {
    out.add(Nudge(Icons.restaurant_rounded, AndyColors.fuel,
        'Over the goal today. No drama, no guilt. Tomorrow is a fresh plate.', 1));
  }

  // Movement
  final since = s.daysSinceWorkout;
  final steps = s.stepsOn(now);
  if (s.isTrainDay(now) && !s.trainedToday) {
    out.add(Nudge(Icons.fitness_center_rounded, AndyColors.move,
        'Workout day: ${s.upcomingRoutine.name}. About 30 minutes, demos included.', 2));
  } else if (h >= 18 && steps > 0 && steps < s.stepGoal / 3) {
    out.add(Nudge(Icons.directions_walk_rounded, AndyColors.move,
        'Only $steps steps so far. A ten minute walk adds about a thousand.', 2));
  } else if (since == null) {
    out.add(Nudge(Icons.directions_run_rounded, AndyColors.move,
        'No workouts yet. A ten minute walk is a workout. Go log your first.', 2));
  } else if (since >= 3) {
    out.add(Nudge(Icons.directions_run_rounded, AndyColors.move,
        '$since days without moving. Your body is not asking for a marathon. Ten minutes.', 2));
  } else if (s.streak >= 3 && s.minutesOn(now) == 0) {
    out.add(Nudge(Icons.local_fire_department_rounded, AndyColors.move,
        '${s.streak} day streak on the line. Do not let today be the gap.', 2));
  }

  // People
  if (s.people.isEmpty) {
    out.add(Nudge(Icons.people_alt_rounded, AndyColors.people,
        'Who matters to you? Add them and I will make sure life does not get in the way.', 3));
  } else {
    for (final p in s.overduePeople.take(2)) {
      final d = p.daysSince;
      out.add(Nudge(
        Icons.chat_bubble_rounded,
        AndyColors.people,
        d == null
            ? 'When did you last speak to ${p.name}? Reach out today.'
            : '$d days since you spoke to ${p.name}. Send a text. Two lines counts.',
        3,
      ));
    }
  }

  // Self care
  if (mood == null) {
    out.add(Nudge(Icons.mood_rounded, AndyColors.self,
        'How are you, really? Check in with yourself.', 4));
  }
  if (h >= 14 && s.waterToday < s.waterGoal / 2) {
    out.add(Nudge(Icons.water_drop_rounded, AndyColors.self,
        'Only ${s.waterToday} glasses of water so far. Drink one now.', 4));
  }
  if (h >= 23 || h < 4) {
    out.add(Nudge(Icons.bedtime_rounded, AndyColors.self,
        'It is late. Nothing good is on that screen. Go to bed. Tomorrow-you says thanks.', 4));
  }
  return out;
}
