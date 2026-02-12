import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:capyadoo/core/routing/app_router.dart';
import 'package:capyadoo/core/constants/app_colors.dart';
import 'package:capyadoo/core/providers/providers.dart';

class App extends StatelessWidget {
  final String initialRoute;
  const App({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders,
      child: MaterialApp(
        title: 'CapYaDoo',
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: initialRoute,
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
      ),
    );
  }
}
