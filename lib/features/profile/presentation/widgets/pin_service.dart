import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  PinService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _pinEnabledKey = 'app_pin_enabled';
  static const String _pinCodeKey = 'app_pin_code';

  static Future<bool> isPinEnabled() async {
    final value = await _storage.read(key: _pinEnabledKey);
    return value == 'true';
  }

  static Future<void> setPinEnabled(bool enabled) async {
    await _storage.write(key: _pinEnabledKey, value: enabled.toString());
  }

  static Future<String?> getPinCode() async {
    return _storage.read(key: _pinCodeKey);
  }

  static Future<bool> hasPin() async {
    final pin = await getPinCode();
    return pin != null && pin.length == 6;
  }

  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinCodeKey, value: pin);
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _pinCodeKey);
  }

  static Future<bool> verifyPin(String inputPin) async {
    final savedPin = await getPinCode();
    return savedPin == inputPin;
  }
}
