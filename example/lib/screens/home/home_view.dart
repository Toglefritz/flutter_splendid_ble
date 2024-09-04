import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_splendid_ble/shared/models/bluetooth_status.dart';

import '../components/main_app_bar.dart';

import 'components/error_message.dart';
import 'home_controller.dart';
import 'home_route.dart';
import 'models/home_menu_items.dart';

/// View for the [HomeRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class HomeView extends StatelessWidget {
  /// A reference to the controller for the [HomeRoute].
  final HomeController state;

  /// Creates an instance of [HomeView].
  const HomeView(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        actions: [
          PopupMenuButton<HomeMenuItem>(
            onSelected: state.onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: HomeMenuItem.connectedDevices,
                child: Text(AppLocalizations.of(context)!.showConnectedDevices),
              ),
            ],
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: GestureDetector(
          onTap: state.onStartScanTap,
          onLongPress: state.onStartScanLongPress,
          child: Text(
            AppLocalizations.of(context)!.startScan.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // If permissions are denied, show an error message
            if (state.permissionsGranted == false)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ErrorMessage(
                  error: AppLocalizations.of(context)!.missingPermissions,
                ),
              ),

            // If Bluetooth is disabled or not available, show an error message
            if (state.bluetoothStatus == BluetoothStatus.disabled)
              ErrorMessage(
                error: state.bluetoothStatus == BluetoothStatus.disabled
                    ? AppLocalizations.of(context)!.bluetoothDisabled
                    : AppLocalizations.of(context)!.notAvailable,
              ),

            // If the Bluetooth status is unknown, show a loading indicator
            if (state.bluetoothStatus == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColorLight,
                      ),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.checkingBluetoothStatus,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
