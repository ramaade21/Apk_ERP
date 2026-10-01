import 'package:flutter/material.dart';

class AppTheme {
  static const profitColor = Color(0xFF2E7D32);
  static const lossColor = Color(0xFFC62828);
  static const expenseColor = Color(0xFFEF6C00);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB71C1C),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
