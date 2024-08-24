import 'package:flutter/material.dart';

/// An error message displayed to the user.
class ErrorMessage extends StatelessWidget {
  /// Creates an instance of [ErrorMessage].
  const ErrorMessage({
    required this.error,
    super.key,
  });

  /// The error message to display.
  final String error;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            Icons.error_outline,
            color: Colors.red[900],
            size: 22,
          ),
        ),
        Text(
          error,
          style: TextStyle(
            color: Colors.red[900],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
