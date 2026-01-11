import 'package:flutter/material.dart';

import '../../l10n/build_context_extension.dart';
import '../../theme/insets.dart';
import '../../theme/terminal_colors.dart';
import 'ble_test_controller.dart';
import 'models/line_style.dart';

/// View for the BLE testing screen.
///
/// This view presents a modern, readable interface for displaying BLE test
/// results with clear visual hierarchy, color coding, and auto-scrolling.
class BleTestView extends StatelessWidget {
  /// Creates a new BLE test view.
  const BleTestView(this.state, {super.key});

  /// The controller containing the test state and logic.
  final BleTestController state;

  @override
  Widget build(BuildContext context) {
    final TerminalColors colors = Theme.of(context).extension<TerminalColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.headerBackground,
        elevation: 0,
        title: Row(
          children: <Widget>[
            Icon(
              Icons.bluetooth_searching,
              color: colors.accent,
              size: 24,
            ),
            Padding(
              padding: const EdgeInsets.only(left: Insets.small),
              child: Text(
                context.l10n.bleTestConsoleTitle,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          if (!state.isRunning)
            Container(
              margin: const EdgeInsets.only(right: Insets.small),
              child: ElevatedButton.icon(
                onPressed: state.startTests,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: Text(context.l10n.runTestsButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.primaryText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: Insets.small),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: Insets.xSmall),
                    child: Text(
                      context.l10n.runningTestsStatus,
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: colors.background,
        child: state.outputLines.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.bluetooth_disabled,
                      size: 64,
                      color: colors.disabledText,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.small),
                      child: Text(
                        context.l10n.readyToRunTestsTitle,
                        style: TextStyle(
                          color: colors.disabledText,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Insets.xSmall),
                      child: Text(
                        context.l10n.tapRunTestsInstruction,
                        style: TextStyle(
                          color: colors.disabledText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: state.scrollController,
                padding: const EdgeInsets.all(Insets.small),
                itemCount: state.outputLines.length + (state.isRunning ? 1 : 0),
                itemBuilder: (BuildContext context, int index) {
                  if (index == state.outputLines.length) {
                    return Container(
                      margin: const EdgeInsets.only(top: Insets.xSmall),
                      child: Row(
                        children: <Widget>[
                          const SizedBox(width: 52),
                          Text('█', style: TextStyle(color: colors.accent, fontSize: 14, fontFamily: 'monospace')),
                        ],
                      ),
                    );
                  }

                  final String line = state.outputLines[index];
                  final String cleanLine = line.trim();

                  // Determine line style based on content
                  final LineStyle style;
                  if (cleanLine.startsWith('TEST ') && cleanLine.contains(':')) {
                    style = LineStyle(color: colors.accent, fontWeight: FontWeight.bold, icon: Icons.science);
                  } else if (cleanLine.startsWith('✓')) {
                    style = LineStyle(color: colors.success, fontWeight: FontWeight.w500, icon: Icons.check_circle);
                  } else if (cleanLine.startsWith('✗')) {
                    style = LineStyle(color: colors.error, fontWeight: FontWeight.w500, icon: Icons.error);
                  } else if (cleanLine.startsWith('ERROR:')) {
                    style = LineStyle(color: colors.error, fontWeight: FontWeight.bold, icon: Icons.warning);
                  } else if (cleanLine.contains('status:') || cleanLine.contains('Permissions:')) {
                    style = LineStyle(color: colors.warning, useMonospace: true);
                  } else if (cleanLine.startsWith('  Found:') || cleanLine.startsWith('  →')) {
                    style = LineStyle(color: colors.deviceFound, useMonospace: true);
                  } else if (cleanLine.startsWith('  Scan completed:')) {
                    style = LineStyle(color: colors.info, fontWeight: FontWeight.w500);
                  } else if (cleanLine.endsWith('...') ||
                      cleanLine.startsWith('Starting') ||
                      cleanLine.startsWith('Running')) {
                    style = LineStyle(color: colors.secondaryText, fontWeight: FontWeight.w500);
                  } else {
                    style = LineStyle(color: colors.mutedText);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: Insets.xxSmall),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 40,
                          child: style.icon != null
                              ? Icon(style.icon, size: 16, color: style.color)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: colors.disabledText,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                        ),
                        Flexible(
                          child: Text(
                            line.trim(),
                            style: TextStyle(
                              color: style.color,
                              fontSize: 14,
                              fontFamily: style.useMonospace ? 'monospace' : null,
                              fontWeight: style.fontWeight,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
