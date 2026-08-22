// lib/core/theme/theme_extensions.dart

import 'package:flutter/material.dart';
import 'app_theme.dart';

extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor =>
      isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  Color get cardColor => isDark ? AppColors.cardDark : Colors.white;

  Color get textPrimary => isDark ? Colors.white : Colors.black87;

  Color get textSecondary =>
      isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54;

  Color get textMuted =>
      isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black45;

  Color get dividerColor =>
      isDark ? Colors.white12 : Colors.grey.shade100;

  Color get iconMuted =>
      isDark ? Colors.white38 : Colors.black38;
}