import 'package:flutter/material.dart';

import 'app_localizations.dart';

/// Extension on [BuildContext] to provide convenient access to localized strings.
///
/// This extension eliminates the need to repeatedly call [AppLocalizations.of(context)] throughout the application,
/// making localization access more concise and readable.
///
/// Usage:
/// ```dart
/// Text(context.l10n.bleTestConsoleTitle)
/// ```
///
/// Instead of:
/// ```dart
/// Text(AppLocalizations.of(context)!.bleTestConsoleTitle)
/// ```
extension BuildContextL10n on BuildContext {
  /// Provides access to the app's localized strings.
  ///
  /// This getter returns the [AppLocalizations] instance for the current context, allowing convenient access to all
  /// localized strings throughout the app.
  ///
  /// Throws an [AssertionError] if localization is not properly configured.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
