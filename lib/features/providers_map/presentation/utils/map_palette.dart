import 'package:flutter/material.dart';
import 'package:algohary_project/core/theme/app_colors.dart';

/// Palette resolving colors with high contrast for both light and dark themes.
class MapPalette {
  final bool isDark;
  final Color surface;
  final Color border;
  final Color shadow;
  final Color onSurface;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color highlight;

  static const Color online = Color(0xFF2EBA68);

  const MapPalette({
    required this.isDark,
    required this.surface,
    required this.border,
    required this.shadow,
    required this.onSurface,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.highlight,
  });

  factory MapPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const MapPalette(
        isDark: true,
        surface: Color(0xFF131D26),
        border: Color(0xFF223242),
        shadow: Color(0x73000000),
        onSurface: AppColors.offWhite,
        muted: Color(0xFF90A3B4),
        accent: AppColors.lightYellow,
        onAccent: Color(0xFF1C242C),
        highlight: AppColors.orange,
      );
    }
    return const MapPalette(
      isDark: false,
      surface: Colors.white,
      border: Color(0xFFE2E8F0),
      shadow: Color(0x1F000000),
      onSurface: Color(0xFF0F172A),
      muted: Color(0xFF64748B),
      accent: AppColors.primaryBlue,
      onAccent: Colors.white,
      highlight: AppColors.orange,
    );
  }
}
