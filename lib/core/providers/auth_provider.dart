import 'package:flutter/foundation.dart';
import 'package:capyadoo/core/model/user.dart';
import 'package:capyadoo/core/services/auth_service.dart';

/// เก็บ state ผู้ใช้ที่ล็อกอินไว้ทั้งแอป
/// ใช้ร่วมกับ LoginPage, HomePage, ProfilePage — state ไม่หายเมื่อเปลี่ยนหน้า
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoadingProfile = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoadingProfile => _isLoadingProfile;

  /// โหลดโปรไฟล์จาก API แล้วอัปเดต state (เรียกหลัง login สำเร็จ หรือเมื่อเปิด Home)
  Future<void> loadProfile() async {
    if (_isLoadingProfile) return;
    _isLoadingProfile = true;
    notifyListeners();

    try {
      final profile = await AuthService.getProfile();
      if (profile != null) {
        _user = profile;
      } else {
        _user = null;
      }
    } catch (e) {
      _user = null;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  /// ตั้งค่า user โดยตรง (ใช้หลัง login ถ้า API คืน user มา)
  void setUser(User? user) {
    if (_user == user) return;
    _user = user;
    notifyListeners();
  }

  /// ออกจากระบบ: ล้าง token + แจ้งเตือน + เคลียร์ user
  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }
}
