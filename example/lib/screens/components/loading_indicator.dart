import 'package:flutter/material.dart';

/// An indicator used to indicate that something that needs to load is loading.
class LoadingIndicator extends StatelessWidget {
  /// Creates an instance of [LoadingIndicator].
  const LoadingIndicator({
    super.key,
    this.size,
  });

  /// The width and height of the [SizedBox] surrounding the [CircularProgressIndicator], which determines the size of
  /// the [CircularProgressIndicator]. If null, the size defaults to 48 x 48.
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size ?? 48,
          height: size ?? 48,
          child: CircularProgressIndicator(
            strokeCap: StrokeCap.round,
            strokeWidth: 3,
            color: Theme.of(context).primaryColorLight,
          ),
        ),
        RotatedBox(
          quarterTurns: 2,
          child: CircularProgressIndicator(
            strokeCap: StrokeCap.round,
            strokeWidth: 2,
            color: Theme.of(context).primaryColorLight,
          ),
        ),
      ],
    );
  }
}
