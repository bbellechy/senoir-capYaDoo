import 'package:flutter/foundation.dart';

/// Global app state ที่เก็บไว้ที่ root ของแอป
/// State จะไม่หายเมื่อเปลี่ยนหน้า หรือเมื่อ widget ถูก rebuild
///
/// ใช้เป็นตัวอย่างโครงสร้าง — สามารถเพิ่ม field / method ตามความต้องการ
class AppStateProvider extends ChangeNotifier {
  AppStateProvider();

  // --- ตัวอย่าง state (แก้ไขได้ตามความต้องการ) ---

  int _counter = 0;
  String _sharedMessage = '';

  int get counter => _counter;
  String get sharedMessage => _sharedMessage;

  void incrementCounter() {
    _counter++;
    notifyListeners();
  }

  void decrementCounter() {
    _counter--;
    notifyListeners();
  }

  void setCounter(int value) {
    if (_counter == value) return;
    _counter = value;
    notifyListeners();
  }

  void setSharedMessage(String message) {
    if (_sharedMessage == message) return;
    _sharedMessage = message;
    notifyListeners();
  }

  void reset() {
    _counter = 0;
    _sharedMessage = '';
    notifyListeners();
  }
}
