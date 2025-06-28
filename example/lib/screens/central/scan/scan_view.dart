import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../components/loading_indicator.dart';
import '../../components/main_app_bar.dart';
import 'components/scan_result_tile.dart';
import 'scan_controller.dart';
import 'scan_route.dart';

/// View for the [ScanRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class ScanView extends StatelessWidget {
  /// A reference to the controller for the [ScanRoute].
  final ScanController state;

  /// Creates an instance of [ScanView].
  const ScanView(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        actions: [
          IconButton(
            onPressed: state.onActionButtonPressed,
            icon: Icon(
              state.scanInProgress
                  ? Icons.stop_outlined
                  : Icons.play_arrow_outlined,
            ),
          ),
          IconButton(
            onPressed: state.onFiltersPressed,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // If no devices have been discovered, show a loading indicator.
          if (state.discoveredDevices.isEmpty)
            const SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingIndicator(),
                ],
              ),
            ),

          // If devices have been discovered, show them in a list.
          if (state.discoveredDevices.isNotEmpty)
            SliverList.list(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    AppLocalizations.of(context)!.discoveredDevices,
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                ...List.generate(
                  state.discoveredDevices.length,
                  (index) => state.discoveredDevices[index].name != null
                      ? ScanResultTile(
                          device: state.discoveredDevices[index],
                          onTap: () =>
                              state.onResultTap(state.discoveredDevices[index]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
