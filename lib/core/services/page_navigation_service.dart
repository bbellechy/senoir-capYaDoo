
import 'package:flutter/material.dart';

class PageNavigationService {
  // Singleton instance
  static final PageNavigationService _instance = PageNavigationService._internal();

  factory PageNavigationService() {
    return _instance;
  }

  PageNavigationService._internal();

  // ValueNotifier to track current tab index
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  void setIndex(int index) {
    currentIndex.value = index;
  }
}
