import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The main [AppBar] appearing at the top of the app for most pages.
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates an instance of [MainAppBar].
  const MainAppBar({
    this.leading,
    this.actions,
    super.key,
  });

  /// A widget placed on the left side of the [AppBar].
  final Widget? leading;

  /// A list of buttons displayed on the right side of the [AppBar].
  final List<Widget>? actions;

  /// The height of the [AppBar].
  double get _height => 50.0;

  @override
  Size get preferredSize => Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        AppLocalizations.of(context)!.appTitle,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: leading,
      elevation: 0,
      actions: actions,
    );
  }
}
