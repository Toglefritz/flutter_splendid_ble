part of '../app.dart';

/// Provides theme configuration for the application.
class _AppTheme {
  /// The primary seed color used for generating the color scheme.
  static const Color _seedColor = Colors.blueAccent;

  /// Light theme configuration for the application.
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
      ),
      useMaterial3: true,
      extensions: const <ThemeExtension<dynamic>>[
        TerminalColors.dark(),
      ],
    );
  }

  /// Dark theme configuration for the application.
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      extensions: const <ThemeExtension<dynamic>>[
        TerminalColors.dark(),
      ],
    );
  }
}
