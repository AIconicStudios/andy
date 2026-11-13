import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'andy_brain.dart';
import 'dictionary.dart';
import 'models.dart';
import 'state.dart';

/// Reminder categories the user can switch off individually.
const reminderCategories = {
  'worth': ('Morning worth reminder', '8:00, every day'),
  'word': ('Word of the day', '9:30, every day'),
  'puzzle': ('Daily puzzle', '11:00, if you have not played'),
  'food': ('Meal logging', 'Lunch and dinner, if you have not logged'),
  'move': ('Movement', 'Early evening, if you have not moved'),
  'people': ('People', 'The day someone is overdue a message'),
  'self': ('Looking after yourself', 'Water, evening check-in, bedtime'),
};

class PlannedReminder {
  PlannedReminder(this.id, this.when, this.title, this.body,
      {this.exact = false});
  final int id;
  final DateTime when;
  final String title;
  final String body;

  /// An alarm the user set for a specific time, so it should not drift.
  final bool exact;
}

const _days = 7;
const _maxPeople = 12;
const _maxMemoryAlarms = 20;

/// iOS keeps at most 64 pending notifications per app.
const maxPending = 64;

/// Works out every reminder for the coming week from what Andy knows now.
///
/// Notifications are scheduled on the device with fixed text, so this is
/// re-run whenever the data changes: log lunch and today's lunch nudge
/// disappears; message Mum and her reminder moves to the next due date.
List<PlannedReminder> planReminders(AppState s, DateTime now,
    {Dictionary? words}) {
  if (!s.onboarded) return [];
  final out = <PlannedReminder>[];
  final today = dayOf(now);
  bool on(String cat) => s.remindersOn && !s.remindersOff.contains(cat);

  void add(int id, DateTime day, int h, int m, String title, String body) {
    final when = DateTime(day.year, day.month, day.day, h, m);
    if (when.isAfter(now)) out.add(PlannedReminder(id, when, title, body));
  }

  bool loggedFoodSince(int hour) => s
      .foodsOn(now)
      .any((f) => f.time.isAfter(today.add(Duration(hours: hour))));

  for (var i = 0; i < _days; i++) {
    final day = today.add(Duration(days: i));
    final isToday = i == 0;
    final id = i * 10;

    if (on('worth')) {
      add(id, day, 8, 0, 'Remember this, ${s.name}', worthFor(day));
    }
    final word = on('word') ? words?.wordOfTheDay(day) : null;
    if (word != null && word.senses.isNotEmpty) {
      add(id + 7, day, 9, 30, 'Word of the day: ${word.word}',
          '${word.senses.first.pos}. ${word.senses.first.definition}');
    }
    if (on('puzzle') && words != null && words.loaded &&
        !(isToday && s.puzzleDoneToday)) {
      add(id + 8, day, 11, 0, 'Daily puzzle',
          'A new word is waiting. Three lives. Keep the streak honest.');
    }
    if (on('food')) {
      if (!(isToday && loggedFoodSince(11))) {
        add(id + 1, day, 13, 0, 'Lunch check',
            'What have you eaten today? Ten seconds to log it.');
      }
      if (!(isToday && loggedFoodSince(17))) {
        add(id + 2, day, 19, 30, 'Dinner check',
            'Log your dinner before the day gets away. Honest beats perfect.');
      }
    }
    if (on('move') && !(isToday && s.minutesOn(now) > 0)) {
      final streak = s.streak;
      add(
        id + 3,
        day,
        17,
        30,
        isToday && streak >= 2 ? '$streak day streak on the line' : 'Move your body',
        isToday && streak >= 2
            ? 'Do not let today be the gap. Ten minutes keeps it alive.'
            : 'You have not moved today. Ten minutes counts. Shoes on.',
      );
    }
    if (on('self')) {
      if (!(isToday && s.waterToday >= s.waterGoal)) {
        add(id + 4, day, 15, 0, 'Water',
            'Drink a glass now. Half of tired is just thirsty.');
      }
      final checkedIn = s.moodToday != null &&
          (s.habits.isEmpty || s.habitsDoneToday == s.habits.length);
      if (!(isToday && checkedIn)) {
        add(id + 5, day, 21, 0, 'How was today, really?',
            'Check in with yourself and tick off your non-negotiables.');
      }
      add(id + 6, day, 22, 45, 'Phone down, ${s.name}',
          'Nothing good is on that screen now. Sleep. Tomorrow-you says thanks.');
    }
  }

  if (on('people')) {
    var n = 0;
    for (final p in s.peopleByDrift.take(_maxPeople)) {
      // First overdue day, or the next 12:15 if they are overdue already.
      var due = p.lastContact == null
          ? today
          : dayOf(p.lastContact!).add(Duration(days: p.everyDays + 1));
      if (due.isBefore(today)) due = today;
      if (!DateTime(due.year, due.month, due.day, 12, 15).isAfter(now)) {
        due = due.add(const Duration(days: 1));
      }
      add(100 + n++, due, 12, 15, 'Reach out to ${p.name}',
          'It has been a while. Send a text. Two lines counts.');
    }
  }

  // Alarms set on memories. These are promises, so they go first and the
  // routine nudges give way if the phone's pending limit is reached.
  final alarms = <PlannedReminder>[];
  final due = s.memories
      .where((m) => m.remindAt != null && m.remindAt!.isAfter(now))
      .toList()
    ..sort((a, b) => a.remindAt!.compareTo(b.remindAt!));
  var a = 0;
  for (final m in due.take(_maxMemoryAlarms)) {
    alarms.add(PlannedReminder(
      200 + a++,
      m.remindAt!,
      m.title,
      m.note.isEmpty ? 'You asked me to remind you about this.' : m.note,
      exact: true,
    ));
  }

  // If the app goes unopened for a week the schedule runs dry, so say so.
  if (s.remindersOn) {
    add(99, today.add(const Duration(days: _days)), 9, 0, 'Andy here',
        'I have gone quiet because you have not opened me. Come back. No guilt, just a fresh day.');
  }
  out.sort((x, y) => x.when.compareTo(y.when));
  return [...alarms, ...out.take(maxPending - alarms.length)];
}

/// Schedules [planReminders] as local notifications. Everything stays on the
/// device: no server, no account, no paid push service.
class Reminders {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Timer? _debounce;

  bool get available => _ready;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
      } catch (_) {
        // Unknown zone name: fall back to UTC rather than lose reminders.
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_andy'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Reminders unavailable: $e');
    }
  }

  /// Asks the OS for permission. Returns whether reminders can be shown.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  /// Rebuilds the schedule shortly after the last change.
  void sync(AppState s) {
    if (!_ready) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _apply(s));
  }

  Future<void> _apply(AppState s) async {
    try {
      await _plugin.cancelAll();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'andy_reminders',
          'Andy\'s reminders',
          channelDescription: 'Nudges for food, movement, people and you',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      );
      final exactOk = await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.canScheduleExactNotifications() ??
          false;
      for (final r in planReminders(s, DateTime.now(), words: dictionary)) {
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          scheduledDate: tz.TZDateTime.from(r.when, tz.local),
          notificationDetails: details,
          // Routine nudges may drift a few minutes; alarms the user set on
          // a memory fire on time where the phone allows it.
          androidScheduleMode: r.exact && exactOk
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Could not schedule reminders: $e');
    }
  }
}

final reminders = Reminders();
