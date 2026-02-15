import 'package:flutter/material.dart';

class PageNavigationService {
  // Singleton instance
  static final PageNavigationService _instance =
      PageNavigationService._internal();

  factory PageNavigationService() {
    return _instance;
  }

  PageNavigationService._internal();

  // ValueNotifier to track current tab index
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  // ValueNotifier to track if app is in Caregiver Mode
  final ValueNotifier<bool> isCaregiverMode = ValueNotifier<bool>(false);

  void setIndex(int index) {
    currentIndex.value = index;
  }

  void setCaregiverMode(bool value) {
    isCaregiverMode.value = value;
  }
}
