import 'package:flutter/material.dart';

/// The app's color palette: the dark theme's ColorScheme inputs, plus the
/// semantic colors widgets reach for by name instead of a raw literal.
abstract final class AppColors {
  // A cyan/teal accent — distinct from the green (income) and red
  // (expense) reserved for money, so the accent never reads as a value.
  static const accent = Color(0xFF00BCD4);
  static const error = Color(0xFFFF453A);
  static const surface = Color(0xFF2C2C2E);
  static const onSurface = Color(0xFFF5F5F7);
  static const scaffoldBackground = Color(0xFF1E1E1E);

  /// One flat neutral used for every "faint structural" role at once —
  /// surfaceContainerHighest, outline, outlineVariant and the app's own
  /// Divider color were already all the same value before this was
  /// extracted, which reads as a deliberate choice for a monochrome dark
  /// theme rather than four coincidentally-identical literals.
  static const neutralContainer = Color(0xFF3A3A3C);

  /// Money in.
  static const income = Color(0xFF30D158);

  /// Money out.
  static const expense = Color(0xFFFF453A);

  /// A destructive action, e.g. deleting a rule.
  static const destructive = Colors.red;

  /// Swatches offered for a user-created category.
  static const categoryPalette = <Color>[
    Color(0xFFFF9F0A),
    Color(0xFF30D158),
    Color(0xFF0A84FF),
    Color(0xFFBF5AF2),
    Color(0xFFFF375F),
    Color(0xFFFFD60A),
    Color(0xFF64D2FF),
    Color(0xFFAC8E68),
  ];
}
