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

## Memory lens

Point Andy at a book, your TV, a gift, anything, and save a note about it.
Point at it again later and the memory pops up. Open it from the focus icon
on the **Today** tab.

Recognition runs entirely on the phone with Google ML Kit (free, no account,
no photo leaves the device). Andy combines three clues: the kind of object,
any words printed on it, and its colours. Things with text on them (book
covers, boxes, branded devices) are told apart reliably; plain objects are
matched on kind and colour, so two near-identical plain things can be
confused. "Not this" on the pop-up lets you correct him, and every confirmed
sighting makes the next one easier.

Packages: `camera`, `google_mlkit_image_labeling`,
`google_mlkit_text_recognition`, `image`, `path_provider`.

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
- `lib/memories.dart` — memory model and the matching rules
- `lib/lens_engine.dart` — camera photo to recognisable clues
- `lib/reminders.dart` — what gets notified and when
- `lib/andy_brain.dart` — Andy's voice: worth reminders and nudge rules
- `lib/screens/` — one file per tab
