import 'package:flutter/material.dart';

import '../../l10n/build_context_extension.dart';
import 'ble_test_controller.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark gray background
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D30), // Slightly lighter gray
        elevation: 0,
        title: Row(
          children: <Widget>[
            const Icon(
              Icons.bluetooth_searching,
              color: Color(0xFF007ACC), // VS Code blue
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.bleTestConsoleTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          if (!state.isRunning)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: state.startTests,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Run Tests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007ACC),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007ACC)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Running...',
                    style: TextStyle(
                      color: Color(0xFF007ACC),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _TestOutputView(state: state),
    );
  }
}

/// Widget that displays the test output with auto-scrolling and rich formatting.
class _TestOutputView extends StatefulWidget {
  const _TestOutputView({required this.state});

  final BleTestController state;

  @override
  State<_TestOutputView> createState() => _TestOutputViewState();
}

class _TestOutputViewState extends State<_TestOutputView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TestOutputView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-scroll to bottom when new content is added
    if (widget.state.outputLines.length != oldWidget.state.outputLines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1E1E1E),
      child: widget.state.outputLines.isEmpty ? _buildEmptyState() : _buildOutputList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.bluetooth_disabled,
            size: 64,
            color: Color(0xFF6A6A6A),
          ),
          SizedBox(height: 16),
          Text(
            'Ready to run BLE tests',
            style: TextStyle(
              color: Color(0xFF6A6A6A),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap "Run Tests" to start scanning for devices',
            style: TextStyle(
              color: Color(0xFF6A6A6A),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: widget.state.outputLines.length + (widget.state.isRunning ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == widget.state.outputLines.length) {
          return _buildCursor();
        }

        final String line = widget.state.outputLines[index];
        return _buildOutputLine(line, index);
      },
    );
  }

  Widget _buildOutputLine(String line, int index) {
    final LineStyle style = _getLineStyle(line);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 40,
            child: style.icon != null
                ? Icon(style.icon, size: 16, color: style.color)
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF6A6A6A),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
  }

  Widget _buildCursor() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: const Row(
        children: <Widget>[
          SizedBox(width: 52),
          Text('█', style: TextStyle(color: Color(0xFF007ACC), fontSize: 14, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  LineStyle _getLineStyle(String line) {
    final String cleanLine = line.trim();

    if (cleanLine.startsWith('TEST ') && cleanLine.contains(':')) {
      return const LineStyle(color: Color(0xFF007ACC), fontWeight: FontWeight.bold, icon: Icons.science);
    }
    if (cleanLine.startsWith('✓')) {
      return const LineStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w500, icon: Icons.check_circle);
    }
    if (cleanLine.startsWith('✗')) {
      return const LineStyle(color: Color(0xFFF44336), fontWeight: FontWeight.w500, icon: Icons.error);
    }
    if (cleanLine.startsWith('ERROR:')) {
      return const LineStyle(color: Color(0xFFF44336), fontWeight: FontWeight.bold, icon: Icons.warning);
    }
    if (cleanLine.contains('status:') || cleanLine.contains('Permissions:')) {
      return const LineStyle(color: Color(0xFFFFB74D), useMonospace: true);
    }
    if (cleanLine.startsWith('  Found:') || cleanLine.startsWith('  →')) {
      return const LineStyle(color: Color(0xFF81C784), useMonospace: true);
    }
    if (cleanLine.startsWith('  Scan completed:')) {
      return const LineStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.w500);
    }
    if (cleanLine.endsWith('...') || cleanLine.startsWith('Starting') || cleanLine.startsWith('Running')) {
      return const LineStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w500);
    }
    return const LineStyle(color: Color(0xFFBDBDBD));
  }
}

class LineStyle {
  const LineStyle({
    required this.color,
    this.fontWeight = FontWeight.normal,
    this.useMonospace = false,
    this.icon,
  });

  final Color color;
  final FontWeight fontWeight;
  final bool useMonospace;
  final IconData? icon;
}
