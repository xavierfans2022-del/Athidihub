import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Palette ─────────────────────────────────────────
  static const primary = Color(0xFF6C63FF);      // Violet
  static const primaryLight = Color(0xFF8B85FF);
  static const primaryDark = Color(0xFF4A42D6);
  static const secondary = Color(0xFF00D4AA);    // Teal accent
  static const accent = Color(0xFFFF6B6B);       // Coral

  // ── Background Scale ──────────────────────────────────────
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF111118);
  static const surfaceElevated = Color(0xFF1A1A24);
  static const surfaceHighest = Color(0xFF222232);

  // ── Light Background Scale ────────────────────────────────
  static const lightBackground = Color(0xFFF7F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFF2F3F8);
  static const lightSurfaceHighest = Color(0xFFE9EAF2);

  // ── Text ──────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF0F0F5);
  static const textSecondary = Color(0xFF9090A8);
  static const textMuted = Color(0xFF52525E);

  // ── Light Text ────────────────────────────────────────────
  static const lightTextPrimary = Color(0xFF1B1B21);
  static const lightTextSecondary = Color(0xFF4B4B5E);
  static const lightTextMuted = Color(0xFF7A7A8C);

  // ── Neutral ───────────────────────────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const white70 = Color(0xB3FFFFFF);
  static const white60 = Color(0x99FFFFFF);
  static const white20 = Color(0x33FFFFFF);
  static const black = Color(0xFF000000);
  static const black08 = Color(0x14000000);
  static const black30 = Color(0x4D000000);
  static const black60 = Color(0x99000000);
  static const transparent = Color(0x00000000);

  // ── Border ────────────────────────────────────────────────
  static const border = Color(0xFF1E1E2C);
  static const borderLight = Color(0xFF2A2A3A);
  static const lightBorder = Color(0xFFE1E2EA);

  // ── Status ────────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const successBg = Color(0xFF0F2818);
  static const successBgLight = Color(0xFFE9F7EF);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFF271E08);
  static const warningBgLight = Color(0xFFFFF3E0);
  static const error = Color(0xFFEF4444);
  static const errorBg = Color(0xFF2A1010);
  static const errorBgLight = Color(0xFFFFEBEE);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0xFF0E1A30);
  static const infoBgLight = Color(0xFFE8F1FF);

  // ── Bed Status ────────────────────────────────────────────
  static const bedAvailable = Color(0xFF22C55E);
  static const bedOccupied = Color(0xFFEF4444);
  static const bedReserved = Color(0xFFF59E0B);
  static const bedMaintenance = Color(0xFF6B7280);

  // ── Chart ─────────────────────────────────────────────────
  static const chartPrimary = Color(0xFF6C63FF);
  static const chartSecondary = Color(0xFF00D4AA);
  static const chartTertiary = Color(0xFFFF6B6B);
  static const chartQuaternary = Color(0xFFF59E0B);

  // ── Gradient ──────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4A42D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCard = LinearGradient(
    colors: [Color(0xFF1A1A24), Color(0xFF111118)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSuccess = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
