/// Root application widget for the test_app Flutter application.
///
/// This file contains the main application widget that configures the Flutter app with Material Design theming and sets
/// up the initial route to the home screen following MVC architecture patterns.
library;

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'screens/ble_test/ble_test_route.dart';
import 'theme/terminal_colors.dart';

part 'theme/app_theme.dart';

/// Root application widget that configures the Flutter app.
///
/// This widget serves as the top-level container for the entire application and is responsible for:
/// * Setting up the Material Design theme and color scheme
/// * Configuring the app title and debug settings
/// * Defining the initial route (home screen)
/// * Enabling Material 3 design system
///
/// The widget follows the StatelessWidget pattern as it contains no mutable state and serves purely as a configuration
/// container.
class TestApp extends StatelessWidget {
  /// Creates the root application widget.
  const TestApp({super.key});

  /// Builds the widget tree for the root application.
  ///
  /// Returns a [MaterialApp] configured with:
  /// * App title derived from the project name
  /// * Light and dark themes from [_AppTheme]
  /// * Home route pointing to the main screen
  /// * Debug banner disabled for cleaner presentation
  /// * Localization support for multiple languages
  ///
  /// The [MaterialApp] provides the foundation for Material Design components and navigation throughout the
  /// application. Theme switching is handled automatically based on system preferences.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      debugShowCheckedModeBanner: false,

      // Themes with accessibility support
      theme: _AppTheme.lightTheme,
      darkTheme: _AppTheme.darkTheme,
      home: const BleTestRoute(),

      // Localizations
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
