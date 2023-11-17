import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_splendid_ble/models/ble_device.dart';

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

  /// A [BleDevice] detected by the Bluetooth scanning process.
  final BleDevice device;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: 2,
          color: Theme.of(context).primaryColorLight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          columnWidths: const <int, TableColumnWidth>{
            0: FlexColumnWidth(),
            1: FlexColumnWidth(3),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: <TableRow>[
            TableRow(
              children: <Widget>[
                TableCell(
                  child: Text(
                    AppLocalizations.of(context)!.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColorLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                TableCell(
                  child: Text(
                    device.name ?? '--',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColorLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            TableRow(
              children: <Widget>[
                TableCell(
                  child: Text(
                    AppLocalizations.of(context)!.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColorLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                TableCell(
                  child: Text(
                    device.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColorLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            TableRow(
              children: <Widget>[
                TableCell(
                  child: Text(
                    AppLocalizations.of(context)!.rssi,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColorLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                TableCell(
                  child: Text(
                    device.rssi.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColorLight,
                        ),
                    textAlign: TextAlign.center,
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
