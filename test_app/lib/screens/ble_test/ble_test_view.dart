import 'package:flutter/material.dart';

import '../../l10n/build_context_extension.dart';
import 'ble_test_controller.dart';

/// View for the BLE testing screen.
///
/// This view presents a terminal-style interface with blue text on a dark
/// background for displaying BLE test results and progress.
class BleTestView extends StatelessWidget {
  /// Creates a new BLE test view.
  const BleTestView(this.state, {super.key});

  /// The controller containing the test state and logic.
  final BleTestController state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          context.l10n.bleTestConsoleTitle,
          style: const TextStyle(
            fontFamily: 'monospace',
          ),
        ),
        actions: <Widget>[
          if (!state.isRunning)
            IconButton(
              onPressed: state.startTests,
              icon: const Icon(
                Icons.play_arrow,
                color: Colors.blue,
              ),
              tooltip: context.l10n.startTestsTooltip,
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final String line in state.outputLines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    line,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontFamily: 'monospace',
                      fontSize: 14.0,
                    ),
                  ),
                ),
              if (state.isRunning)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    '█', // Terminal cursor
                    style: TextStyle(
                      color: Colors.blue,
                      fontFamily: 'monospace',
                      fontSize: 14.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
