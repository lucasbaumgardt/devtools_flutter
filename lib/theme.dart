import 'package:flutter/material.dart';

const _seed = Color(0xFF0F766E); // teal

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    inputDecorationTheme: const InputDecorationThemeData(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    // Selected segments are filled *and* bold, so the state is not shown by
    // color alone (the check icon is off because it made labels wrap).
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

/// Monospace text for code. The font is bundled (pubspec.yaml) so it looks the
/// same on every platform, including web.
TextStyle codeStyle(BuildContext context, {double fontSize = 13}) => TextStyle(
  fontFamily: 'LiberationMono',
  fontSize: fontSize,
  height: 1.5,
  color: Theme.of(context).colorScheme.onSurface,
);
