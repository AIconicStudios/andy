import 'package:material_ui/material_ui.dart';

class AndyColors {
  static const brand = Color(0xFFE4572E); // ember
  static const fuel = Color(0xFFF2A541); // amber
  static const move = Color(0xFFE4572E); // ember
  static const people = Color(0xFF7C6CF2); // violet
  static const self = Color(0xFF1FA39A); // teal
  static const quarters = [fuel, move, people, self];
}

ThemeData andyTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AndyColors.brand,
    brightness: b,
  ).copyWith(
    primary: AndyColors.brand,
    onPrimary: Colors.white,
    surface: dark ? const Color(0xFF151210) : const Color(0xFFFAF6F1),
    surfaceContainer: dark ? const Color(0xFF211C19) : Colors.white,
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
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AndyColors.brand,
      foregroundColor: Colors.white,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
  );
}
