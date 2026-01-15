import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/services/storage/token_storage.dart';

void main() {
  bootstrap(() async {
      // ✅ SAVE TOKEN ชั่วคราว
  await TokenStorage.saveToken(
    'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyMSIsImlhdCI6MTc2Nzk4Mjg4NiwiZXhwIjoxNzcwNTc0ODg2fQ.DxYbFCxHFJYwVBCB0O7uZjX0uBlevLteL4b3hhMM5eg'
  );
  final token = await TokenStorage.getToken();
  debugPrint('USING TOKEN => $token');

    runApp(const App());
  });
}
