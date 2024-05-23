import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_splendid_ble/shared/models/bluetooth_status.dart';

import '../components/main_app_bar.dart';

import 'components/error_message.dart';
import 'home_controller.dart';

/// View for the [HomeRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class HomeView extends StatelessWidget {
  final HomeController state;

  const HomeView(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.permissionsGranted == false)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ErrorMessage(
                  error: AppLocalizations.of(context)!.missingPermissions,
                ),
              ),
            if (state.bluetoothStatus != BluetoothStatus.enabled)
              ErrorMessage(
                error: state.bluetoothStatus == BluetoothStatus.disabled
                    ? AppLocalizations.of(context)!.bluetoothDisabled
                    : AppLocalizations.of(context)!.notAvailable,
              ),
          ],
        ),
      ),
    );
  }
}
