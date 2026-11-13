import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/foundation.dart';

import 'state.dart';

/// A wake-up alarm. It cannot be switched off while ringing: the only way
/// to silence it is to answer five quiz questions correctly.
class WakeAlarm {
  WakeAlarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.daily = true,
    this.enabled = true,
  });

  /// Small positive integer; also the id of the system alarm.
  final int id;
  int hour;
  int minute;
  String label;

  /// Rings every day. Otherwise it rings once and switches itself off.
  bool daily;
  bool enabled;

  String get timeText =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// The next moment this alarm should ring, strictly after [now].
  DateTime next(DateTime now) {
    var t = DateTime(now.year, now.month, now.day, hour, minute);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'daily': daily,
        'enabled': enabled,
      };

  static WakeAlarm fromJson(Map<String, dynamic> j) => WakeAlarm(
        id: j['id'],
        hour: j['hour'],
        minute: j['minute'],
        label: j['label'] ?? '',
        daily: j['daily'] ?? true,
        enabled: j['enabled'] ?? true,
      );
}

/// "in 7 h 12 min"
String untilText(DateTime at, DateTime now) {
  final m = (at.difference(now).inSeconds + 59) ~/ 60; // round up
  if (m < 60) return 'in $m min';
  return 'in ${m ~/ 60} h ${m % 60} min';
}

/// Keeps the phone's real alarms in step with the list in [AppState].
///
/// The ringing itself is done natively by the free `alarm` package, so it
/// sounds when the app is closed and the screen is locked.
class AlarmService {
  bool _ready = false;
  StreamSubscription<AlarmSet>? _sub;

  bool get available => _ready;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await Alarm.init();
      _ready = true;
    } catch (e) {
      debugPrint('Alarms unavailable: $e');
    }
  }

  /// Calls [onRing] with the id of any alarm that starts (or is already)
  /// ringing.
  void listen(void Function(int id) onRing) {
    if (!_ready) return;
    _sub?.cancel();
    _sub = Alarm.ringing.listen((set) {
      for (final a in set.alarms) {
        onRing(a.id);
      }
    });
  }

  /// Schedules every enabled alarm and clears the rest. Safe to call often.
  Future<void> sync(AppState s) async {
    if (!_ready) return;
    try {
      final now = DateTime.now();
      final wanted = {for (final a in s.alarms.where((a) => a.enabled)) a.id: a};
      for (final set in await Alarm.getAlarms()) {
        // Never cut off an alarm that is ringing: only the quiz may do that.
        if (!wanted.containsKey(set.id) && !await Alarm.isRinging(set.id)) {
          await Alarm.stop(set.id);
        }
      }
      for (final a in wanted.values) {
        if (await Alarm.isRinging(a.id)) continue;
        final at = a.next(now);
        final existing = await Alarm.getAlarm(a.id);
        if (existing != null && existing.dateTime == at) continue;
        await Alarm.set(alarmSettings: _settings(a, at));
      }
    } catch (e) {
      debugPrint('Could not schedule alarms: $e');
    }
  }

  AlarmSettings _settings(WakeAlarm a, DateTime at) => AlarmSettings(
        id: a.id,
        dateTime: at,
        assetAudioPath: 'assets/alarm.wav',
        loopAudio: true,
        vibrate: true,
        // Keep ringing if the app is swiped away, and do not let the volume
        // keys turn it down. The quiz is the only off switch.
        androidStopAlarmOnTermination: false,
        warningNotificationOnKill: defaultTargetPlatform == TargetPlatform.iOS,
        volumeSettings: VolumeSettings.fade(
          volume: 0.9,
          fadeDuration: const Duration(seconds: 6),
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: a.label.isEmpty ? 'Wake up' : a.label,
          body: 'Open Andy and solve 5 questions to stop the alarm.',
          icon: 'ic_stat_andy',
          androidStopAlarmOnDismiss: false,
        ),
      );

  /// Called once the quiz is beaten.
  Future<void> silence(int id) async {
    if (!_ready) return;
    try {
      await Alarm.stop(id);
    } catch (e) {
      debugPrint('Could not stop alarm: $e');
    }
  }
}

final alarmService = AlarmService();
