class PasswordValidation {
  static final RegExp _specialCharacterPattern = RegExp(
    r'[!@#\$%\^&*(),.?":{}|<>\[\]\\/\-_+=~`]',
  );

  static final RegExp _digitPattern = RegExp(r'\d');
  static final RegExp _thaiPhonePattern = RegExp(r'^0[689]\d{8}$');
  static final RegExp _otpPattern = RegExp(r'^\d{6}$');

  static bool hasMinLength(String value) => value.length >= 8;

  static bool hasSpecialCharacter(String value) =>
      _specialCharacterPattern.hasMatch(value);

  static bool hasDigit(String value) => _digitPattern.hasMatch(value);

  static String normalizeThaiPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('66') && digits.length == 11) {
      return '0${digits.substring(2)}';
    }
    return digits;
  }

  static bool isValidThaiPhone(String value) =>
      _thaiPhonePattern.hasMatch(normalizeThaiPhone(value));

  static bool matches(String confirmPassword, String password) =>
      confirmPassword.isNotEmpty && confirmPassword == password;

  static String? validateRequiredPassword(
    String? value, {
    String requiredMessage = 'กรุณากรอกรหัสผ่าน',
    String lengthMessage = 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร',
    String specialMessage = 'ต้องมีตัวอักษรพิเศษอย่างน้อย 1 ตัว',
    String digitMessage = 'ต้องมีตัวเลขอย่างน้อย 1 ตัว',
  }) {
    if (value == null || value.isEmpty) {
      return requiredMessage;
    }
    if (!hasMinLength(value)) {
      return lengthMessage;
    }
    if (!hasSpecialCharacter(value)) {
      return specialMessage;
    }
    if (!hasDigit(value)) {
      return digitMessage;
    }
    return null;
  }

  static String? validateConfirmPassword(
    String? value,
    String password, {
    String requiredMessage = 'กรุณายืนยันรหัสผ่านใหม่',
    String mismatchMessage = 'รหัสผ่านไม่ตรงกัน',
  }) {
    if (value == null || value.isEmpty) {
      return requiredMessage;
    }
    if (!matches(value, password)) {
      return mismatchMessage;
    }
    return null;
  }

  static String? validateDifferentFromCurrent(
    String? newPassword,
    String currentPassword, {
    String message = 'รหัสผ่านใหม่ต้องไม่ซ้ำรหัสผ่านเดิม',
  }) {
    if (newPassword == null || newPassword.isEmpty) {
      return null;
    }
    if (currentPassword.isNotEmpty && newPassword == currentPassword) {
      return message;
    }
    return null;
  }

  static String? validateThaiPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกเบอร์โทรศัพท์';
    }
    if (!isValidThaiPhone(value)) {
      return 'กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง';
    }
    return null;
  }

  static String? validateOtpCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกรหัส OTP';
    }
    if (!_otpPattern.hasMatch(value.trim())) {
      return 'OTP ต้องเป็นตัวเลข 6 หลัก';
    }
    return null;
  }
}
