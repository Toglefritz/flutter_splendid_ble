import 'package:flutter/material.dart';
import 'package:flutter_ble/models/ble_device.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Displays information about a Bluetooth device detected by the Bluetooth scan.
///
/// Each [BleDevice] detected by the Bluetooth scan is displayed in a [ListTile], provided the device has a non-null
/// value for its name. The tile also includes the Bluetooth address for the Bluetooth device. Finally, the RSSI
/// of the device is represented as a
class ScanResultTile extends StatelessWidget {
  const ScanResultTile({
    super.key,
    required this.device,
  });

  final BleDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          width: 1,
          color: Theme.of(context).primaryColorLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    device.name ?? '--',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.address,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    device.address,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.rssi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    device.rssi.toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
