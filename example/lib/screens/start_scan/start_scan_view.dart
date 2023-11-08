import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_splendid_ble/models/bluetooth_status.dart';
import 'package:flutter_splendid_ble_example/screens/start_scan/start_scan_controller.dart';

import '../components/fancy_outlined_text.dart';
import '../components/main_app_bar.dart';

import 'components/error_message.dart';

/// View for the [StartScanRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class StartScanView extends StatelessWidget {
  final StartScanController state;

  const StartScanView(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      extendBodyBehindAppBar: true,
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: state.onStartScanTap,
              child: FancyOutlinedText(
                text: AppLocalizations.of(context)!.startScan.toUpperCase(),
              ),
            ),
            if (state.permissionsGranted == false)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ErrorMessage(
                  error: AppLocalizations.of(context)!.missingPermissions,
                ),
              ),
            if (state.bluetoothStatus != BluetoothStatus.enabled)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ErrorMessage(
                  error: state.bluetoothStatus == BluetoothStatus.disabled
                      ? AppLocalizations.of(context)!.bluetoothDisabled
                      : AppLocalizations.of(context)!.notAvailable,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
