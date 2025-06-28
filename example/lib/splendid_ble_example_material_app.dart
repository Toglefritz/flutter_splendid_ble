import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/home/home_route.dart';

/// A [StatelessWidget] that builds the root [MaterialApp] for the Flutter BLE Example App.
class SplendidBleExampleMaterialApp extends StatelessWidget {
  /// The home route for the application, which is the main entry point of the app.
  final Widget home;

  /// Creates an instance of [SplendidBleExampleMaterialApp].
  const SplendidBleExampleMaterialApp({
    this.home = const HomeRoute(),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      // Why use any other mode?
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            fontFamily: 'MajorMono',
          ),
          displayMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            fontFamily: 'MajorMono',
          ),
          displaySmall: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white,
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
      ],
      home: home,
    );
  }
}
