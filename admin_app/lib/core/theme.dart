import 'package:flutter/material.dart';

class AdminColors {
  static const Color primary = Color(0xFF1E1B4B); // Deep Indigo
  static const Color secondary = Color(0xFF3730A3);
  static const Color accentSubtle = Color(0xFFF1F5F9); // Light Slate
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);
  static const Color bg = Color(0xFFF8FAFC);
  static const Color textPrime = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF475569);
  static const Color textLight = Color(0xFF64748B);

  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

final ThemeData adminTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: ColorScheme.fromSeed(seedColor: AdminColors.primary, background: AdminColors.bg),
  scaffoldBackgroundColor: AdminColors.bg,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: AdminColors.textPrime,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminColors.textPrime, letterSpacing: 0.5),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFF1F5F9)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AdminColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.primary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
  ),
);
