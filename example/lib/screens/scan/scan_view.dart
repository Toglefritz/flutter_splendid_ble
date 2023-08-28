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
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: Column(
            mainAxisAlignment: state.discoveredDevices.isEmpty ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (state.discoveredDevices.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    AppLocalizations.of(context)!.discoveredDevices,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              if (state.discoveredDevices.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: LoadingIndicator(),
                ),
              if (state.discoveredDevices.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.discoveredDevices.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (state.discoveredDevices[index].name != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: ScanResultTile(
                          device: state.discoveredDevices[index],
                          onTap: () => state.onResultTap(state.discoveredDevices[index]),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
