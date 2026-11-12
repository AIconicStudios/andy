# Andy

*Keep it handy with Andy.* A Flutter life assistant for Android and iPhone.

Andy watches four things and rolls them into one daily score out of 100:

| Tab | What it does |
| --- | --- |
| **Today** | A daily reminder of your worth, the four-ring life score, and Andy's nudges for whatever is slipping |
| **Food** | Log meals in seconds (quick picks or your own), calories left against your goal, 7-day chart |
| **Move** | Log workouts, weekly minutes against your goal, streak, estimated calories burned |
| **People** | The people who matter and how often you want to speak; Andy flags anyone you are drifting from |
| **Me** | Mood check-in, water, daily non-negotiables, and the proof jar: your own evidence of your worth, read back to you on low days |

Everything is stored on the device. No account, no server.

## Reminders

Andy sends notifications even when the app is closed: a morning worth reminder,
lunch and dinner logging nudges, a movement nudge, water, an evening check-in,
bedtime, and a message the day someone in your circle becomes overdue. A nudge
for today is dropped as soon as you have done the thing. Switch any category
off from the bell on the **Me** tab.

These are local notifications scheduled on the phone, a week ahead, and
refreshed every time the app is opened or data changes. There is no push
server and nothing to pay for. Packages used, all free and open source:
`flutter_local_notifications`, `timezone`, `flutter_timezone`,
`shared_preferences`.

## Run

```bash
flutter pub get
flutter run
```

## Build

```bash
flutter build apk --release
```

```bash
flutter build ios --release
```

The iOS build needs a Mac with Xcode.

## Layout

- `lib/state.dart` — all data, persistence and the life score
- `lib/reminders.dart` — what gets notified and when
- `lib/andy_brain.dart` — Andy's voice: worth reminders and nudge rules
- `lib/screens/` — one file per tab
