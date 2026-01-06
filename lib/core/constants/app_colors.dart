import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF1D7AD8);
  static const Color subBlue = Color(0xFFAFD7FF);

  static const Color background = Color(0xFFFFFEF8);
  static const Color white = Colors.white;

  static const Color textPrimary = Color(0xFF1D2530);
  static const Color textSub = Color(0xFF606061);
  static const Color textSublest = Color(0xFFD7D7D7);

  static const Color error = Color(0xFFFF0000);
  static const Color success = Color(0xFF28BD5A);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // Gradients
  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, subBlue],
    stops: [0.24, 1.0],
  );
}
