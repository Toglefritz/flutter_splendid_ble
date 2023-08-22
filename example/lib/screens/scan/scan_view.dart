import 'package:flutter/material.dart';
import 'package:flutter_ble_example/screens/scan/scan_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
            onPressed: state.onFiltersPressed,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  AppLocalizations.of(context)!.discoveredDevices,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (state.discoveredDevices.isEmpty)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColorLight,
                      ),
                    ),
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColorLight,
                    ),
                  ],
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
