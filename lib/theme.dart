import 'package:material_ui/material_ui.dart';

/// A colour theme: the accent used for buttons and highlights, and the
/// gradient behind the daily worth reminder.
class AndyPalette {
  const AndyPalette(this.id, this.name, this.brand, this.gradient);
  final String id;
  final String name;
  final Color brand;
  final List<Color> gradient;
}

const palettes = [
  AndyPalette('ember', 'Ember', Color(0xFFE4572E),
      [Color(0xFFF2A541), Color(0xFFE4572E), Color(0xFFB8336A)]),
  AndyPalette('ocean', 'Ocean', Color(0xFF1E7FD6),
      [Color(0xFF29B6C9), Color(0xFF1E7FD6), Color(0xFF3B4CC0)]),
  AndyPalette('forest', 'Forest', Color(0xFF2E8B57),
      [Color(0xFF9BC53D), Color(0xFF2E8B57), Color(0xFF17635B)]),
  AndyPalette('grape', 'Grape', Color(0xFF7B4FD6),
      [Color(0xFFB07CF2), Color(0xFF7B4FD6), Color(0xFF4A2FA0)]),
  AndyPalette('rose', 'Rose', Color(0xFFD6336C),
      [Color(0xFFF58FA8), Color(0xFFD6336C), Color(0xFF8E2A6B)]),
  AndyPalette('gold', 'Gold', Color(0xFFC98A0C),
      [Color(0xFFF2C14E), Color(0xFFC98A0C), Color(0xFF8A5A0B)]),
  AndyPalette('teal', 'Lagoon', Color(0xFF0E9AA7),
      [Color(0xFF5AD1C0), Color(0xFF0E9AA7), Color(0xFF1B5E8C)]),
  AndyPalette('slate', 'Slate', Color(0xFF55606E),
      [Color(0xFF8A96A6), Color(0xFF55606E), Color(0xFF2C3440)]),
];

AndyPalette paletteById(String id) =>
    palettes.firstWhere((p) => p.id == id, orElse: () => palettes.first);

class AndyColors {
  /// The theme in use. Set from the saved choice before the app builds.
  static AndyPalette palette = palettes.first;

  static Color get brand => palette.brand;
  static List<Color> get gradient => palette.gradient;

  // The four life areas keep their own colours in every theme, so the rings
  // always read the same way.
  static const fuel = Color(0xFFF2A541); // amber
  static const move = Color(0xFFE4572E); // ember
  static const people = Color(0xFF7C6CF2); // violet
  static const self = Color(0xFF1FA39A); // teal
  static const quarters = [fuel, move, people, self];
}

/// [black] swaps the dark theme's charcoal for true black (kinder to OLED
/// screens and to eyes at night).
ThemeData andyTheme(Brightness b, {bool black = false}) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AndyColors.brand,
    brightness: b,
  ).copyWith(
    primary: AndyColors.brand,
    onPrimary: Colors.white,
    surface: dark
        ? (black ? Colors.black : const Color(0xFF151210))
        : const Color(0xFFFAF6F1),
    surfaceContainer: dark
        ? (black ? const Color(0xFF121212) : const Color(0xFF211C19))
        : Colors.white,
    surfaceContainerHighest:
        dark ? const Color(0xFF2E2723) : const Color(0xFFF0E9E1),
    onSurface: dark ? const Color(0xFFF5EEE7) : const Color(0xFF1F1A17),
    onSurfaceVariant: dark ? const Color(0xFFB3A79D) : const Color(0xFF6F655D),
    outlineVariant: dark ? const Color(0xFF3A322D) : const Color(0xFFE6DDD3),
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
      headlineMedium: base.textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineSmall: base.textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleLarge:
          base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium:
          base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: AndyColors.brand.withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      height: 68,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AndyColors.brand,
      foregroundColor: Colors.white,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
  );
}
