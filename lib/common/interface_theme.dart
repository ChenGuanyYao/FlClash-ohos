import 'package:material_ui/material_ui.dart';

extension InterfaceTheme on ThemeData {
  ThemeData get withInterfaceTheme {
    final dark = brightness == Brightness.dark;
    final pureBlack = dark && colorScheme.surface == Colors.black;
    final surface = pureBlack
        ? Colors.black
        : dark
        ? const Color(0xFF101318)
        : const Color(0xFFF5F6F8);
    final card = dark ? const Color(0xFF1A1E25) : Colors.white;
    final scheme = colorScheme.copyWith(
      surface: surface,
      secondaryContainer: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: dark ? 0.10 : 0.055),
        card,
      ),
      onSecondaryContainer: dark
          ? const Color(0xFFE8EBF1)
          : const Color(0xFF1C2432),
      surfaceContainerLowest: pureBlack ? Colors.black : card,
      surfaceContainerLow: card,
      surfaceContainer: dark
          ? const Color(0xFF20252E)
          : const Color(0xFFF0F2F5),
      surfaceContainerHigh: dark
          ? const Color(0xFF252A33)
          : const Color(0xFFECEEF2),
      surfaceContainerHighest: dark
          ? const Color(0xFF2C323D)
          : const Color(0xFFE5E8EE),
      onSurface: dark ? const Color(0xFFE8EBF1) : const Color(0xFF1C2432),
      onSurfaceVariant: dark
          ? const Color(0xFF9DA6B5)
          : const Color(0xFF687385),
      outline: dark ? const Color(0xFF7E8899) : const Color(0xFF8C95A4),
      outlineVariant: dark ? const Color(0xFF303640) : const Color(0xFFE4E7ED),
    );
    final typography = textTheme.copyWith(
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: textTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
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
      iconButtonTheme: IconButtonThemeData(
        style: (iconButtonTheme.style ?? const ButtonStyle()).merge(
          IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: scheme.onSurfaceVariant,
            iconSize: 21,
            minimumSize: const Size.square(40),
          ),
        ),
      ),
      navigationBarTheme: navigationBarTheme.copyWith(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.08),
      ),
      dividerTheme: dividerTheme.copyWith(
        color: scheme.outlineVariant,
        thickness: 0.6,
      ),
    );
  }
}

extension InterfaceStatusColors on ColorScheme {
  Color get connectionAccent => brightness == Brightness.dark
      ? const Color(0xFF4DCEAA)
      : const Color(0xFF20886A);
}
