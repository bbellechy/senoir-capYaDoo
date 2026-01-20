import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CapYaDoo',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.initialRoute,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
      locale: const Locale('th', 'TH'),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Sarabun',
      ),
    );
  }
}
