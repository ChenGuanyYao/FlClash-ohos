import 'package:material_ui/material_ui.dart';

extension InterfaceTheme on ThemeData {
  ThemeData get withInterfaceTheme {
    final dark = brightness == Brightness.dark;
    final pureBlack = dark && colorScheme.surface == Colors.black;
    final surface = pureBlack
        ? Colors.black
        : dark
        ? const Color(0xFF0C1220)
        : const Color(0xFFF2F5FA);
    final card = dark ? const Color(0xFF151E2E) : Colors.white;
    final scheme = colorScheme.copyWith(
      surface: surface,
      surfaceContainerLowest: pureBlack ? Colors.black : card,
      surfaceContainerLow: card,
      surfaceContainer: dark
          ? const Color(0xFF1A2537)
          : const Color(0xFFEBF0F8),
      surfaceContainerHigh: dark
          ? const Color(0xFF202D42)
          : const Color(0xFFE5ECF6),
      surfaceContainerHighest: dark
          ? const Color(0xFF29374D)
          : const Color(0xFFDCE5F1),
      outlineVariant: dark ? const Color(0xFF2A374A) : const Color(0xFFDFE7F2),
    );
    final typography = textTheme.copyWith(
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
    return copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: typography,
      appBarTheme: appBarTheme.copyWith(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: typography.titleLarge?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: navigationBarTheme.copyWith(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: dark ? 0.22 : 0.10),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return typography.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: dividerTheme.copyWith(color: scheme.outlineVariant),
    );
  }
}

extension InterfaceStatusColors on ColorScheme {
  Color get connectionAccent => brightness == Brightness.dark
      ? const Color(0xFF34D3A5)
      : const Color(0xFF087F5B);
}
