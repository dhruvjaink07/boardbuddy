import 'package:flutter/material.dart';

class AppColors {
  // Base Colors
  static const Color primary = Color(0xFFFF6A00); // Orange
  static const Color background = Color(0xFF121212); // Dark Background
  static const Color surface = Color(
    0xFF1E1E1E,
  ); // Slightly lighter than background
  static final Color? secondary = Colors.grey[600];

  // Home-specific
  static const Color card = Color(0xFF23232A);
  static const Color filterSelected = Color(0xFF2D255A);
  static const Color filterUnselected = card;

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;

  // Borders / Outline
  static const Color border = Color(0xFF333333);

  // Others
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);

  // New theme/accent colors (for CreateBoardPage themes & gradients)
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFB794F4);
  static const Color pink = Color(0xFFEC4899);
  static const Color skyBlue = Color(0xFF38BDF8);
  // subtle selection glow
  static const Color selectionGlow = Color(0xFF7C3AED);

  static Color info = Colors.grey;
}
