import 'package:andy/memories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

img.Image solid(int r, int g, int b, {int w = 120, int h = 160}) =>
    img.Image(width: w, height: h)..clear(img.ColorRgb8(r, g, b));

Signature sig(String label, String text, img.Image picture) => Signature(
      labels: label.isEmpty ? {} : {label: 0.9},
      words: wordsFrom(text),
      colors: colorHistogram(picture),
    );

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
    expect(bestMatch(saved, again)?.memory.title, 'Atomic Habits');

    final stranger = sig('Book', 'Deep Work Cal Newport', solid(230, 220, 190));
    expect(bestMatch(saved, stranger), isNull);
  });

  test('without words, matches on kind and colour', () {
    final mug = sig('Cup', '', solid(20, 60, 200));
    final saved = [memory('Blue mug', mug)];
    expect(bestMatch(saved, sig('Cup', '', solid(15, 45, 150)))?.memory.title,
        'Blue mug');
    expect(bestMatch(saved, sig('Cup', '', solid(200, 30, 30))), isNull);
    expect(bestMatch(saved, sig('Shoe', '', solid(20, 60, 200))), isNull);
  });

  test('memories survive a round trip through JSON', () {
    final m = memory('TV', sig('Television', 'SAMSUNG smart', solid(10, 10, 10)));
    final back = Memory.fromJson(m.toJson());
    expect(back.title, 'TV');
    expect(similarity(back.signatures.first, m.signatures.first), greaterThan(0.99));
  });
}
