import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/services/storage/token_storage.dart';
import 'core/routing/app_router.dart';

void main() {
  bootstrap(() async {
    final token = await TokenStorage.getToken();
    final String initialRoute = (token != null && token.isNotEmpty)
        ? AppRouter.mainRoute
        : AppRouter.loginRoute;

    runApp(App(initialRoute: initialRoute));
  });
}
