import 'package:flutter/material.dart';

/// Central color constants for the Trippy Customer app.
/// Use these instead of raw hex literals to ensure consistency.
class AppColors {
  AppColors._(); // prevent instantiation

  // Brand
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0x1A6C63FF); // 10% opacity
  static const Color primaryDark = Color(0x336C63FF);  // 20% opacity

  // Dark theme backgrounds
  static const Color darkBg = Color(0xFF13151B);
  static const Color darkCard = Color(0xFF1C1E26);
  static const Color darkCardDeep = Color(0xFF252833);

  // Light theme
  static const Color lightBg = Colors.white;

  // Status
  static const Color success = Colors.green;
  static const Color error = Colors.redAccent;
  static const Color warning = Colors.orange;
  static const Color sos = Colors.red;
}
