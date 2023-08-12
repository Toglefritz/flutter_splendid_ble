import 'package:flutter/material.dart';

/// Draws a text element displayed as a semi-transparent text fill with a full transparency outline.
class FancyOutlinedText extends StatelessWidget {
  const FancyOutlinedText({
    super.key,
    required this.text,
  });

  /// The string value displayed in the text element.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 58,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = Theme.of(context).primaryColorLight,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 58,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColorLight.withOpacity(0.3),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
