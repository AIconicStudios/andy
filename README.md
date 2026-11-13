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

Only a name is required. A note is optional, and you can set an **alarm**
on the thing instead (or as well): pick a date and time and Andy notifies you
then, even if all other nudges are switched off.

Recognition runs entirely on the phone with free models; no photo leaves the
device. Andy combines:

- a **visual fingerprint** from a MobileNet V3 image embedder (TensorFlow
  Lite, bundled in `assets/`), taken at four zoom levels of every photo.
  Any zoom of a new photo can match any zoom of a saved one, which is how a
  close-up matches a shot from across the room;
- **words printed on the thing** (ML Kit text recognition), which confirm a
  match or hold back two lookalikes with different titles;
- its colours, and the kind of object (ML Kit labelling) as a fallback.

When Andy is confident he pops the memory up. When something only resembles
a saved thing, or two saved things are close, he says "this could be…" and
lets you pick; every pick teaches him another view of it.

Packages: `camera`, `tflite_flutter`, `google_mlkit_image_labeling`,
`google_mlkit_text_recognition`, `image`, `path_provider`.

## Brain alarm

An alarm with no snooze and no off button. Once it rings, the only way to
silence it is to answer five random questions correctly: number and letter
sequences, mental arithmetic, odd one out, analogies, hidden rules, short
logic problems and classic trick questions. A wrong answer does not count
and brings a new question. Open it from **Tools** on the Today tab; "Try
the quiz" runs a silent practice round.

The alarm rings natively through the free `alarm` package, so it sounds with
the app closed and the screen locked, keeps going if the app is swiped away,
and holds its volume against the volume keys. Alarms can ring once or every
day. Questions are generated on the phone (`lib/quiz.dart`), so there is no
question bank to run out of and nothing to download.

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
- `lib/quiz.dart` — random question generator for the brain alarm
- `lib/alarms.dart` — alarm model and scheduling
- `lib/memories.dart` — memory model and the matching rules
- `lib/lens_engine.dart` — camera photo to recognisable clues
- `lib/reminders.dart` — what gets notified and when
- `lib/andy_brain.dart` — Andy's voice: worth reminders and nudge rules
- `lib/screens/` — one file per tab
