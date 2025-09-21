import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveTheme();
    notifyListeners();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  void _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C3AED),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF7C3AED),
      secondary: const Color(0xFFEC4899),
      tertiary: const Color(0xFF06B6D4),
      surface: const Color(0xFFFDF2F8),
      surfaceVariant: const Color(0xFFF3E8FF),
      onSurface: const Color(0xFF1F2937),
      onSurfaceVariant: const Color(0xFF374151),
      background: const Color(0xFFFFFBFE),
      onBackground: const Color(0xFF1F2937),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFFDF2F8),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: const Color(0xFFFDF2F8).withOpacity(0.7),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFDF2F8),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Color(0xFF1F2937),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.1),
      elevation: 8,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    fontFamily: 'SF Pro Display',
    // Optimized scroll behavior for 120Hz displays
    scrollbarTheme: const ScrollbarThemeData(
      radius: Radius.circular(4),
      thickness: MaterialStatePropertyAll(6),
      thumbVisibility: MaterialStatePropertyAll(false),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF8B5CF6),
      secondary: const Color(0xFFF472B6),
      tertiary: const Color(0xFF22D3EE),
      surface: const Color(0xFF0F0B1A),
      surfaceVariant: const Color(0xFF1E1B2E),
      onSurfaceVariant: const Color(0xFFA78BFA),
      background: const Color(0xFF050315),
      onBackground: const Color(0xFFF3F4F6),
    ),
    scaffoldBackgroundColor: const Color(0xFF050315),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: const Color(0xFF0F0B1A).withOpacity(0.8),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF050315),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Color(0xFFF3F4F6),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0F0B1A).withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.2),
      elevation: 8,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    fontFamily: 'SF Pro Display',
    // Optimized scroll behavior for 120Hz displays
    scrollbarTheme: const ScrollbarThemeData(
      radius: Radius.circular(4),
      thickness: MaterialStatePropertyAll(6),
      thumbVisibility: MaterialStatePropertyAll(false),
    ),
  );
}