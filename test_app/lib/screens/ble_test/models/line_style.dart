import 'package:flutter/material.dart';

/// Defines the visual styling for a line of text in the BLE test console.
///
/// This class encapsulates all the visual properties needed to render
/// a line of test output with appropriate color coding, typography,
/// and iconography based on the line's content and meaning.
///
/// Used by the BLE test view to apply consistent styling to different
/// types of test output (success, error, info, etc.).
class LineStyle {
  /// Creates a line style with the specified visual properties.
  ///
  /// The [color] parameter is required and determines the text color.
  /// All other parameters are optional and have sensible defaults.
  const LineStyle({
    required this.color,
    this.fontWeight = FontWeight.normal,
    this.useMonospace = false,
    this.icon,
  });

  /// The color to use for the text and icon.
  ///
  /// This color should be chosen to convey the semantic meaning
  /// of the line (e.g., green for success, red for errors).
  final Color color;

  /// The font weight to apply to the text.
  ///
  /// Defaults to [FontWeight.normal]. Use [FontWeight.bold] or
  /// [FontWeight.w500] to emphasize important lines like test
  /// headers or critical messages.
  final FontWeight fontWeight;

  /// Whether to use a monospace font for the text.
  ///
  /// Defaults to false. Set to true for technical output like
  /// device addresses, UUIDs, or structured data that benefits
  /// from fixed-width character alignment.
  final bool useMonospace;

  /// Optional icon to display alongside the text.
  ///
  /// When provided, this icon is displayed in the left margin
  /// instead of the line number. The icon uses the same [color]
  /// as the text for visual consistency.
  ///
  /// Common icons include:
  /// - [Icons.check_circle] for successful operations
  /// - [Icons.error] for failed operations
  /// - [Icons.warning] for warnings
  /// - [Icons.science] for test headers
  final IconData? icon;
}
