import 'package:flutter/material.dart';

class AppColors {
  // Base seed colors for Material You 3
  static const Color defaultSeed = Color(0xFF10B981); // Emerald green
  
  // Predefined accent color options users can choose from
  static const List<Color> accentOptions = [
    Color(0xFF84CC16), // Lime
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Violet  
    Color(0xFFF43F5E), // Rose
    Color(0xFFF97316), // Orange
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFEC4899), // Pink
  ];

  // Brand
  static const primary = Color(0xFF10B981); // Emerald
  static const darkBackground = Color(0xFF0D0D0D);
  static const lightBackground = Color(0xFFF8F8F8);

  // Semantic colors (shared across themes)
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFEAB308);
  static const premiumGold = Color(0xFFF59E0B);
  static const streakOrange = Color(0xFFF97316);

  // Backward compatibility getters (Will be phased out, use Theme.of(context).colorScheme instead)
  static const darkAccent = defaultSeed;
  static const lightAccent = defaultSeed;
  static const darkTextPrimary = Colors.white;
  static const lightTextPrimary = Colors.black87;
  static const darkTextMuted = Colors.white54;
  static const lightTextMuted = Colors.black54;
  static const darkSurfaceElevated = Color(0xFF1A1A1A);
  static const lightSurfaceElevated = Colors.white;
  static const darkSurface = Color(0xFF121212);
  static const lightSurface = Color(0xFFF5F5F5);
  static const darkBorder = Colors.white10;
  static const lightBorder = Colors.black12;
  static const darkTextSecondary = Colors.white70;
  static const lightTextSecondary = Colors.black54;
}
