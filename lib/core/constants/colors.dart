import 'package:flutter/material.dart';

class AppColors {
  // Official FTH Brand Design Tokens
  static const Color emeraldGreen = Color(0xFF0F4C3A);
  static const Color emeraldDark = Color(0xFF0A3629);
  static const Color emeraldLight = Color(0xFF176B52);
  static const Color emeraldSurface = Color(0xFFECFDF5);

  static const Color slateNavy = Color(0xFF1E2E45);
  static const Color slateNavyDark = Color(0xFF131E2E);
  static const Color slateNavyLight = Color(0xFF2C4263);

  // Backward-compatible aliases so existing widgets work seamlessly while using Emerald/Slate branding
  static const Color primaryNavy = emeraldGreen;
  static const Color primaryNavyLight = emeraldLight;
  static const Color primaryNavyDark = slateNavy;

  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFBF3D5);
  static const Color goldDark = Color(0xFFA6851E);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFDBEAFE);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleBg = Color(0xFFEDE9FE);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF0F4C3A).withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
