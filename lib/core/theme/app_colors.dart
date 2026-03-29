import 'package:flutter/material.dart';

/// Single source of truth for every color token in the app.
/// Inspired by Linear's monochrome-with-accent palette.
abstract final class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const primary = Color(0xFF6366F1);
  static const primaryDim = Color(0xFFEEF2FF);

  // ── Surface ───────────────────────────────────────────────────────────────
  static const background = Color(0xFFF7F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  // ── Status chips ─────────────────────────────────────────────────────────
  static const todoFg = Color(0xFF64748B);
  static const todoBg = Color(0xFFF1F5F9);

  static const inProgressFg = Color(0xFFF59E0B);
  static const inProgressBg = Color(0xFFFFFBEB);

  static const doneFg = Color(0xFF10B981);
  static const doneBg = Color(0xFFECFDF5);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const danger = Color(0xFFEF4444);
  static const dangerSurface = Color(0xFFFEE2E2);
  static const overdue = Color(0xFFEF4444);
  static const blocked = Color(0xFFF59E0B);
  static const blockedSurface = Color(0xFFFEF3C7);
}
