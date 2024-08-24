import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home/home_route.dart';

/// A [StatelessWidget] that builds the root [MaterialApp] for the Flutter BLE Example App.
///
/// This widget is responsible for creating the main application structure with an app bar and body content. The app
/// bar displays the title 'Flutter Splendid BLE Example App', and the body includes an animated image from a network
/// URL.
///
/// The [SplendidBleExampleApp] is returned by the [runApp] method in main.dart and serves as the starting point for
/// the example application, setting the stage for any additional screens, widgets, or functionalities that might be
/// added.
class SplendidBleExampleApp extends StatelessWidget {
  /// Creates an instance of [SplendidBleExampleApp].
  const SplendidBleExampleApp({super.key});

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
      home: const HomeRoute(),
    );
  }
}
