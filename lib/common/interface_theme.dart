import 'package:material_ui/material_ui.dart';
import 'constant.dart';

extension InterfaceTheme on ThemeData {
  ThemeData get withInterfaceTheme {
    final dark = brightness == Brightness.dark;
    final pureBlack = dark && colorScheme.surface == Colors.black;
    final surface = pureBlack
        ? Colors.black
        : dark
        ? const Color(0xFF101826)
        : const Color(0xFFEFF2F8);
    final card = dark ? const Color(0xFF263246) : Colors.white;
    final defaultAccent = ColorScheme.fromSeed(
      seedColor: const Color(defaultPrimaryColor),
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.content,
    ).primary;
    final accent = colorScheme.primary == defaultAccent
        ? (dark ? const Color(0xFFA7C2FF) : const Color(0xFF2567D9))
        : colorScheme.primary;
    final scheme = colorScheme.copyWith(
      primary: accent,
      surface: surface,
      secondaryContainer: Color.alphaBlend(
        accent.withValues(alpha: dark ? 0.10 : 0.055),
        card,
      ),
      onSecondaryContainer: dark
          ? const Color(0xFFE8EDF6)
          : const Color(0xFF1B293C),
      surfaceContainerLowest: pureBlack ? Colors.black : card,
      surfaceContainerLow: card,
      surfaceContainer: dark
          ? const Color(0xFF172131)
          : const Color(0xFFE5EAF2),
      surfaceContainerHigh: dark
          ? const Color(0xFF2B3A50)
          : const Color(0xFFE6EBF3),
      surfaceContainerHighest: dark
          ? const Color(0xFF34445B)
          : const Color(0xFFDEE5EF),
      onSurface: dark ? const Color(0xFFE8EDF6) : const Color(0xFF1B293C),
      onSurfaceVariant: dark
          ? const Color(0xFF94A2B8)
          : const Color(0xFF62718A),
      outline: dark ? const Color(0xFF7E8899) : const Color(0xFF8C95A4),
      outlineVariant: dark ? const Color(0xFF354258) : const Color(0xFFDAE1EB),
    );
    final typography = textTheme
        .copyWith(
          headlineSmall: textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
          titleLarge: textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w500,
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
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
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
      cardTheme: cardTheme.copyWith(
        color: card,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow.withValues(alpha: dark ? 0.16 : 0.06),
        elevation: 1,
      ),
      listTileTheme: listTileTheme.copyWith(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: typography.bodyMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: typography.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: inputDecorationTheme.copyWith(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        hintStyle: typography.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: dialogTheme.copyWith(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: typography.titleLarge?.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: typography.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      bottomSheetTheme: bottomSheetTheme.copyWith(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: popupMenuTheme.copyWith(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
      ),
      tabBarTheme: tabBarTheme.copyWith(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: typography.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
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
      ? const Color(0xFF6CD5B4)
      : const Color(0xFF23765F);

  Color get suspendedAccent => brightness == Brightness.dark
      ? const Color(0xFFE7BF80)
      : const Color(0xFF986318);
}

extension InterfaceSurfaces on ColorScheme {
  Color get interfaceSoft => primary == const Color(0xFF2567D9)
      ? const Color(0xFFECF2FC)
      : primary == const Color(0xFFA7C2FF)
      ? const Color(0xFF2C405F)
      : Color.alphaBlend(primary.withValues(alpha: 0.1), surfaceContainerLow);
  LinearGradient get interfaceSelectionGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: primary == const Color(0xFF2567D9)
        ? const [Color(0xFFF3F6FF), Color(0xFFEAF1FE)]
        : primary == const Color(0xFFA7C2FF)
        ? const [Color(0xFF314B70), Color(0xFF243C5B)]
        : [
            Color.alphaBlend(
              primary.withValues(alpha: 0.04),
              surfaceContainerLow,
            ),
            Color.alphaBlend(
              primary.withValues(alpha: 0.1),
              surfaceContainerLow,
            ),
          ],
  );
  LinearGradient interfaceGradient({Color? color, bool raised = false}) {
    final dark = brightness == Brightness.dark;
    final base = color ?? surfaceContainerLow;
    final standardSurface = color == null || color == surfaceContainerLow;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(Colors.white.withValues(alpha: dark ? 0 : 0.22), base),
        standardSurface
            ? (dark ? const Color(0xFF1E293B) : const Color(0xFFF7FAFF))
            : Color.alphaBlend(
                primary.withValues(alpha: raised ? 0.035 : 0.018),
                base,
              ),
      ],
    );
  }

  List<BoxShadow> interfaceShadows({bool raised = false}) {
    final dark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: shadow.withValues(
          alpha: dark
              ? 0.12
              : raised
              ? 0.07
              : 0.04,
        ),
        blurRadius: raised ? 22 : 16,
        offset: Offset(0, raised ? 9 : 5),
      ),
      BoxShadow(
        color: shadow.withValues(alpha: dark ? 0.06 : 0.025),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }
}
