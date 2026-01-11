import 'package:flutter/material.dart';

/// Color scheme for terminal/console interfaces.
///
/// Provides VS Code-inspired colors for the BLE test console interface.
/// This theme extension can be accessed via Theme.of(context).extension<TerminalColors>().
@immutable
class TerminalColors extends ThemeExtension<TerminalColors> {
  /// Creates a terminal colors theme extension.
  const TerminalColors({
    required this.background,
    required this.headerBackground,
    required this.accent,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.deviceFound,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.disabledText,
  });

  /// Default terminal colors for dark theme.
  const TerminalColors.dark()
      : background = const Color(0xFF1E1E1E),
        headerBackground = const Color(0xFF2D2D30),
        accent = const Color(0xFF007ACC),
        success = const Color(0xFF4CAF50),
        error = const Color(0xFFF44336),
        warning = const Color(0xFFFFB74D),
        info = const Color(0xFF64B5F6),
        deviceFound = const Color(0xFF81C784),
        primaryText = Colors.white,
        secondaryText = const Color(0xFFE0E0E0),
        mutedText = const Color(0xFFBDBDBD),
        disabledText = const Color(0xFF6A6A6A);

  /// Dark background color for the terminal.
  final Color background;

  /// Slightly lighter background for app bars and headers.
  final Color headerBackground;

  /// Primary accent color (VS Code blue).
  final Color accent;

  /// Success/pass color (green).
  final Color success;

  /// Error/fail color (red).
  final Color error;

  /// Warning color (orange).
  final Color warning;

  /// Info color (light blue).
  final Color info;

  /// Device found color (light green).
  final Color deviceFound;

  /// Primary text color (white).
  final Color primaryText;

  /// Secondary text color (light gray).
  final Color secondaryText;

  /// Muted text color (gray).
  final Color mutedText;

  /// Disabled text color (dark gray).
  final Color disabledText;

  @override
  TerminalColors copyWith({
    Color? background,
    Color? headerBackground,
    Color? accent,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? deviceFound,
    Color? primaryText,
    Color? secondaryText,
    Color? mutedText,
    Color? disabledText,
  }) {
    return TerminalColors(
      background: background ?? this.background,
      headerBackground: headerBackground ?? this.headerBackground,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      deviceFound: deviceFound ?? this.deviceFound,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      mutedText: mutedText ?? this.mutedText,
      disabledText: disabledText ?? this.disabledText,
    );
  }

  @override
  TerminalColors lerp(ThemeExtension<TerminalColors>? other, double t) {
    if (other is! TerminalColors) {
      return this;
    }
    return TerminalColors(
      background: Color.lerp(background, other.background, t)!,
      headerBackground: Color.lerp(headerBackground, other.headerBackground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      deviceFound: Color.lerp(deviceFound, other.deviceFound, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      disabledText: Color.lerp(disabledText, other.disabledText, t)!,
    );
  }
}
