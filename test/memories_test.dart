import 'dart:math';
import 'dart:typed_data';

import 'package:andy/memories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

img.Image solid(int r, int g, int b, {int w = 120, int h = 160}) =>
    img.Image(width: w, height: h)..clear(img.ColorRgb8(r, g, b));

Signature sig(String label, String text, img.Image picture,
        {List<Int8List> embeds = const []}) =>
    Signature(
      labels: label.isEmpty ? {} : {label: 0.9},
      words: wordsFrom(text),
      colors: colorHistogram(picture),
      embeds: embeds,
    );

Memory? best(List<Memory> saved, Signature seen) {
  final found = recognise(saved, seen);
  return isClearWinner(found) ? found.first.memory : null;
}

/// A made-up fingerprint: [seed] picks the object, [noise] how different
/// this view of it looks (0 = identical photo).
Int8List look(int seed, [double noise = 0, int view = 0]) {
  final base = Random(seed), jitter = Random(seed * 1000 + view);
  return quantize([
    for (var i = 0; i < 1024; i++)
      base.nextDouble() * 2 - 1 + noise * (jitter.nextDouble() * 2 - 1)
  ]);
}

Memory memory(String title, Signature s) => Memory(
    id: title,
    title: title,
    note: 'note',
    photo: '',
    created: DateTime(2026),
    signatures: [s]);

void main() {
  test('colour fingerprint ignores brightness and photo rotation', () {
    final red = colorHistogram(solid(200, 20, 20));
    final dimRed = colorHistogram(solid(120, 12, 12));
    final sideways = colorHistogram(solid(200, 20, 20, w: 160, h: 120));
    final blue = colorHistogram(solid(20, 20, 200));
    expect(red, dimRed);
    expect(red, sideways);
    expect(red, isNot(blue));
    expect(red.reduce((a, b) => a + b), closeTo(1, 1e-9));
  });

  test('tells two books apart by the words on the cover', () {
    final atomic = sig('Book', 'ATOMIC HABITS James Clear', solid(230, 220, 190));
    final alchemist = sig('Book', 'The Alchemist Paulo Coelho', solid(230, 220, 190));
    final saved = [memory('Atomic Habits', atomic), memory('The Alchemist', alchemist)];

    // Seen again: partly misread title, slightly different light.
    final again = sig('Book', 'ATOMIC HABITS Jarnes', solid(210, 200, 170));
    expect(best(saved, again)?.title, 'Atomic Habits');

    final stranger = sig('Book', 'Deep Work Cal Newport', solid(230, 220, 190));
    expect(best(saved, stranger), isNull);
  });

  test('without words, matches on kind and colour', () {
    final mug = sig('Cup', '', solid(20, 60, 200));
    final saved = [memory('Blue mug', mug)];
    expect(best(saved, sig('Cup', '', solid(15, 45, 150)))?.title, 'Blue mug');
    expect(best(saved, sig('Cup', '', solid(200, 30, 30))), isNull);
    expect(best(saved, sig('Shoe', '', solid(20, 60, 200))), isNull);
  });

  test('memories survive a round trip through JSON', () {
    final m = memory('TV', sig('Television', 'SAMSUNG smart', solid(10, 10, 10)));
    final back = Memory.fromJson(m.toJson());
    expect(back.title, 'TV');
    expect(similarity(back.signatures.first, m.signatures.first), greaterThan(0.99));
  });

  final grey = solid(128, 128, 128);

  test('matches near and far shots through any shared zoom level', () {
    // Saved close up: zoom levels show the object (7), then its details.
    final saved = [
      memory('Guitar', sig('', '', grey, embeds: [look(7), look(70), look(71)])),
      memory('Lamp', sig('', '', grey, embeds: [look(9), look(90), look(91)])),
    ];
    // Seen from across the room: wide view is the room (500); only the
    // tightest zoom shows the guitar, from a slightly different angle.
    final far = sig('', '', grey, embeds: [look(500), look(501), look(7, 0.6, 1)]);
    expect(best(saved, far)?.title, 'Guitar');
    // Something never saved.
    final other = sig('', '', grey, embeds: [look(600), look(601), look(602)]);
    expect(recognise(saved, other), isEmpty);
  });

  test('a weak resemblance is offered as "could be", not announced', () {
    final saved = [memory('Guitar', sig('', '', grey, embeds: [look(7)]))];
    final vague = sig('', '', grey, embeds: [look(7, 1.9, 2)]);
    final found = recognise(saved, vague);
    expect(found.single.memory.title, 'Guitar');
    expect(found.single.sure, false);
    expect(isClearWinner(found), false);
  });

  test('two close candidates make Andy ask instead of guess', () {
    final saved = [
      memory('Left speaker', sig('', '', grey, embeds: [look(7)])),
      memory('Right speaker', sig('', '', grey, embeds: [look(7, 0.2, 5)])),
    ];
    final found = recognise(saved, sig('', '', grey, embeds: [look(7, 0.3, 6)]));
    expect(found.length, 2);
    expect(found.every((m) => m.sure), true);
    expect(isClearWinner(found), false);
  });

  test('clashing words hold back lookalike books; matching words confirm', () {
    final saved = [
      memory('Atomic Habits',
          sig('Book', 'ATOMIC HABITS James Clear', grey, embeds: [look(3)]))
    ];
    final lookalike = sig('Book', 'Deep Work Cal Newport', grey,
        embeds: [look(3, 1.05, 4)]);
    final same = sig('Book', 'ATOMIC HABITS James Clear', grey,
        embeds: [look(3, 1.05, 4)]);
    expect(similarity(same, saved.first.signatures.first),
        greaterThan(similarity(lookalike, saved.first.signatures.first) + 0.2));
    expect(best(saved, same)?.title, 'Atomic Habits');
    expect(best(saved, lookalike), isNull);
    expect(recognise(saved, lookalike).single.sure, false);
  });

  test('fingerprints and alarms survive a round trip through JSON', () {
    final m = memory('Passport', sig('', '', grey, embeds: [look(1), look(2)]))
      ..remindAt = DateTime(2027, 3, 1, 9, 30);
    final back = Memory.fromJson(m.toJson());
    expect(back.remindAt, DateTime(2027, 3, 1, 9, 30));
    expect(back.signatures.first.embeds.length, 2);
    expect(back.signatures.first.embeds.first, look(1));
  });
}
