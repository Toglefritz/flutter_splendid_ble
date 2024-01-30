import 'package:flutter/material.dart';

import 'loading_indicator.dart';

/// An enumeration of values representing the sides of a neighboring widget, typically a [Table] on which the
/// [TableButton] will appear.
enum ButtonSide {
  top,
  bottom,
}

/// [TableButton] is an outlined button designed to accompany [Table] widgets.
///
/// This button is styled to have rounded bottom corners when placed below a [Table] or rounded top corners when
/// displayed above a [Table]. This allows to button to appear as an extension of the [Table], especially when the
/// [Table] also adapts its border styling to mirror that of this button.
class TableButton extends StatelessWidget {
  const TableButton({
    super.key,
    required this.onTap,
    required this.side,
    required this.text,
    this.loading = false,
  });

  /// A callback invoked when the button is tapped.
  final VoidCallback onTap;

  /// Determines the side of the [Table] or other widget on which the [TableButton] will appear. This parameter can
  /// accept values of [ButtonSide.top] or [ButtonSide.bottom]. If set to [ButtonSide.top], the [TableButton] will
  /// use rounded top corners and square bottom corners. If set to [ButtonSide.bottom], the [TableButton] will
  /// use rounded bottom corners and square top corners.
  final ButtonSide side;

  /// The text label to display on the [TableButton] if [loading] is false.
  final String text;

  /// Determines whether the button should be displayed in a loading state. If true, the content of the button is
  /// a [LoadingIndicator]. If false, the content of the button is the [text]. If a value is not provided, the
  /// [TableButton] will use a value of false by default, meaning the [text] will be displayed on the button.
  final bool? loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: side == ButtonSide.top
                ? const Radius.circular(12.0)
                : Radius.zero,
            topRight: side == ButtonSide.top
                ? const Radius.circular(12.0)
                : Radius.zero,
            bottomLeft: side == ButtonSide.bottom
                ? const Radius.circular(12.0)
                : Radius.zero,
            bottomRight: side == ButtonSide.bottom
                ? const Radius.circular(12.0)
                : Radius.zero,
          ),
        ),
        side: BorderSide(
          color: Theme.of(context).primaryColorLight,
          width: 2.0,
        ),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading == false)
            Text(
              text,
              style: Theme.of(context).textTheme.displaySmall,
            ),
          if (loading == true)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: LoadingIndicator(
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
