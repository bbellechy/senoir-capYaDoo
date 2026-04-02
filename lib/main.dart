import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/routing/app_router.dart';
import 'core/services/storage/token_storage.dart';
import 'features/profile/presentation/widgets/pin_service.dart';

void main() {
  bootstrap(() async {
    final token = await TokenStorage.getToken();
    final hasToken = token != null && token.isNotEmpty;
    final pinEnabled = hasToken && await PinService.isPinEnabled();
    final hasPin = pinEnabled && await PinService.hasPin();

    final String initialRoute = !hasToken
        ? AppRouter.loginRoute
        : (hasPin ? AppRouter.pinUnlockRoute : AppRouter.mainRoute);

    runApp(App(initialRoute: initialRoute));
  });
}
