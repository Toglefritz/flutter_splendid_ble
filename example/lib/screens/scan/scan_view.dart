import 'package:flutter/material.dart';
import 'package:flutter_ble_example/screens/scan/scan_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../components/loading_indicator.dart';
import '../components/main_app_bar.dart';
import 'components/scan_result_title.dart';

/// View for the [ScanRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class ScanView extends StatelessWidget {
  final ScanController state;

  const ScanView(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        actions: [
          IconButton(
            onPressed: state.onStopPressed,
            icon: const Icon(Icons.stop_outlined),
          ),
          IconButton(
            onPressed: state.onFiltersPressed,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (state.discoveredDevices.isEmpty)
            const SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingIndicator(),
                ],
              ),
            ),
          if (state.discoveredDevices.isNotEmpty)
            SliverList.list(
              children: [
                Text(
                  AppLocalizations.of(context)!.discoveredDevices,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                ...List.generate(
                  state.discoveredDevices.length,
                  (index) => state.discoveredDevices[index].name != null
                      ? ScanResultTile(
                          device: state.discoveredDevices[index],
                          onTap: () => state.onResultTap(state.discoveredDevices[index]),
                        )
                      : const SizedBox.shrink(),
                )
              ],
            ),
        ],
      ),
    );
  }
}
