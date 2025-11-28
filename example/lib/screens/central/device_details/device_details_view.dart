import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../components/main_app_bar.dart';
import '../../components/table_button.dart';
import 'components/device_details_table.dart';
import 'components/services_info.dart';
import 'device_details_controller.dart';
import 'device_details_route.dart';

/// View for the [DeviceDetailsRoute]. The view is dumb, and purely declarative. References values on the controller and
/// widget.
class DeviceDetailsView extends StatelessWidget {
  /// A reference to the controller for the [DeviceDetailsRoute].
  final DeviceDetailsController state;

  /// Creates an instance of [DeviceDetailsView].
  const DeviceDetailsView(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        leading: IconButton(
          onPressed: state.onBack,
          icon: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          IconButton(
            onPressed: state.onClose,
            icon: const Icon(Icons.close),
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
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  state.widget.device.name ?? state.widget.device.address,
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12.0),
                      topRight: const Radius.circular(12.0),
                      bottomLeft:
                          Radius.circular(state.isConnected ? 12.0 : 0.0),
                      bottomRight:
                          Radius.circular(state.isConnected ? 12.0 : 0.0),
                    ),
                    color: Theme.of(context)
                        .primaryColorLight
                        .withValues(alpha: 0.15),
                    border: Border.all(
                      color: Theme.of(context).primaryColorLight,
                      width: 2.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: DeviceDetailsTable(
                    device: state.widget.device,
                    connectionState: state.currentConnectionState,
                  ),
                ),
              ),

              // If the device is not connected, show the connect button.
              if (!state.isConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TableButton(
                    onTap: state.onConnectTap,
                    side: ButtonSide.bottom,
                    text: AppLocalizations.of(context)!.connect.toUpperCase(),
                    loading: state.connecting,
                  ),
                ),
              if (state.isConnected)
                const Divider(
                  height: 64.0,
                  thickness: 2.0,
                  indent: 16.0,
                  endIndent: 16.0,
                ),

              // If the device is connected and has no discovered services, show the discover services button.
              if (state.isConnected && state.discoveredServices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TableButton(
                    onTap: state.onDiscoverServicesTap,
                    side: ButtonSide.top,
                    text: AppLocalizations.of(context)!
                        .discoverServices
                        .toUpperCase(),
                    loading: state.discoveringServices,
                  ),
                ),

              // If the device is connected and has discovered services, show the services info.
              if (state.isConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ServicesInfo(
                    services: state.discoveredServices,
                    characteristicOnTap: state.characteristicOnTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
