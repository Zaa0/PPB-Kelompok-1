// ============================================================
// Maritime Slate System - palet tema UniTalk (dark & light)
// Prinsip CRAP: kontras jelas, pengulangan konsisten, perataan
// rapi, kedekatan elemen yang berhubungan.
// ============================================================
import 'package:flutter/material.dart';

class UniTalkChatTheme {
  UniTalkChatTheme._();

  // ── Palet gelap (zero eye-strain, elevasi bertingkat) ──
  static const Color darkCanvas = Color(0xFF0B132B); // latar utama chat
  static const Color darkSidebar = Color(0xFF0F1A30); // panel daftar room
  static const Color darkHeader = Color(0xFF0F1A30); // appbar redup elegan
  static const Color darkBubbleOther = Color(0xFF1E293B); // bubble lawan bicara
  static const Color darkBubbleMe = Color(0xFF2563EB); // bubble pesan saya
  static const Color darkInputBg = Color(0xFF16233B); // latar input ketik pesan
  static const Color darkBorder = Color(0xFF273549); // pembatas antar section

  static const Color darkTextPrimary = Color(0xFFF1F5F9); // teks pesan
  static const Color darkTextSecondary = Color(0xFF94A3B8); // jam / subteks
  static const Color darkSenderName = Color(0xFF38BDF8); // nama pengirim (cyan)

  // ── Palet terang (soft off-white, tidak menyilaukan) ──
  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightSidebar = Color(0xFFFFFFFF);
  static const Color lightHeader = Color(0xFFFFFFFF);
  static const Color lightBubbleOther = Color(0xFFF1F5F9);
  static const Color lightBubbleMe = Color(0xFF1D4ED8);
  static const Color lightInputBg = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightSenderName = Color(0xFF0284C7);

  // ── Aksen brand (header terang tetap navy khas UniTalk) ──
  static const Color brandNavy = Color(0xFF1E3A8A);
  static const Color brandBlue = Color(0xFF3B82F6);

  // ── ThemeData lengkap ──
  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF38BDF8),
      brightness: Brightness.dark,
    ).copyWith(
      surface: darkSidebar,
      onSurface: darkTextPrimary,
      onSurfaceVariant: darkTextSecondary,
      primary: darkSenderName,
      outline: darkBorder,
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: darkCanvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkHeader,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(color: darkBorder),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkSenderName),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: darkInputBg,
        contentTextStyle: TextStyle(color: darkTextPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: darkSidebar,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: darkTextPrimary),
      ),
    );
  }

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    ).copyWith(
      surface: lightSidebar,
      onSurface: lightTextPrimary,
      onSurfaceVariant: lightTextSecondary,
      primary: lightSenderName,
      outline: lightBorder,
    );
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: lightCanvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightHeader,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(color: lightBorder),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightSenderName),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: lightSidebar,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: lightTextPrimary),
      ),
    );
  }
}
