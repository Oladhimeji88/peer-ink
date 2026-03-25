import 'package:flutter/material.dart';

class SnaplinkTheme {
  const SnaplinkTheme._();

  static const Color _ink = Color(0xFF12212F);
  static const Color _mist = Color(0xFFF3F7FA);
  static const Color _leaf = Color(0xFF2F7A5E);
  static const Color _amber = Color(0xFFC98A2B);
  static const Color _crimson = Color(0xFFC84A4A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _ink,
      brightness: Brightness.light,
      primary: _ink,
      secondary: _leaf,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _mist,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _ink.withOpacity(0.08)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _mist,
        selectedColor: _leaf.withOpacity(0.14),
        secondarySelectedColor: _amber.withOpacity(0.18),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
        bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: _ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: _ink),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        SnaplinkAccentColors(
          success: _leaf,
          warning: _amber,
          danger: _crimson,
        ),
      ],
    );
  }
}

@immutable
class SnaplinkAccentColors extends ThemeExtension<SnaplinkAccentColors> {
  const SnaplinkAccentColors({
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color success;
  final Color warning;
  final Color danger;

  @override
  SnaplinkAccentColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return SnaplinkAccentColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  SnaplinkAccentColors lerp(
    ThemeExtension<SnaplinkAccentColors>? other,
    double t,
  ) {
    if (other is! SnaplinkAccentColors) {
      return this;
    }
    return SnaplinkAccentColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
    );
  }
}
