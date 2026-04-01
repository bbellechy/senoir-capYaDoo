import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF1D7AD8);
  static const Color subBlue = Color(0xFFAFD7FF);
  static const Color blueBorder = Color(0xFFB8D0E9);
  static const Color blueEmpty = Color(0xFFDEE9F4);

  static const Color background = Color(0xFFFFFEF8);
  static const Color white = Colors.white;
  static const Color offwhite = Color(0xFFFFFEF8);
  static const Color whitelist = Color(0xFFF0F8FF);

  static const Color textPrimary = Color(0xFF1D2530);
  static const Color textSub = Color(0xFF606061);
  static const Color textSublest = Color(0xFFD7D7D7);

  static const Color error = Color(0xFFFF0000);
  static const Color red = Color(0xFFCA2525);
  static const Color success = Color(0xFF28BD5A);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  static const Color morning = Color(0xFFFFFFD4);
  static const Color morningBorder = Color(0xFFF3F394);
  static const Color morningIcon = Color(0xFFFFC341);
  static const Color primaryYellow = Color(0xFFF9C31F);

  static const Color noon = Color(0xFFFFE2C2);
  static const Color noonBorder = Color(0xFFF9CC99);
  static const Color noonIcon = Color(0xFFE37900);

  static const Color dinner = Color(0xFFC7E3FF);
  static const Color dinnerBorder = Color(0xFFA6D2FF);

  static const Color sleep = Color(0xFFD5D2FF);
  static const Color sleepBorder = Color(0xFFB1ACFF);
  static const Color sleepIcon = Color(0xFF493DF3);
  

  // Gradients
  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, subBlue],
    stops: [0.24, 1.0],
  );
}
