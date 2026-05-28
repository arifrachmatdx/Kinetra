import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0A0E14);
  static const surface = Color(0xFF161B22);
  static const surfaceLight = Color(0xFF1E2630);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0BEC5);
  static const accentCyan = Color(0xFF00D4FF);
  static const accentGreen = Color(0xFF00E676);
  static const error = Color(0xFFFF5252);
  static const poseValid = Color(0xFF00E676);
  static const poseInvalid = Color(0xFFFF5252);

  static const gradient = LinearGradient(
    colors: [accentCyan, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
