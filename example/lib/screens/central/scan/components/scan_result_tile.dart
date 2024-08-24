import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_splendid_ble/shared/models/ble_device.dart';

/// Displays information about a Bluetooth device detected by the Bluetooth scan.
///
/// Each [BleDevice] detected by the Bluetooth scan is displayed in a [ListTile], provided the device has a non-null
/// value for its name. The tile also includes the Bluetooth address for the Bluetooth device. Finally, the RSSI
/// of the device is represented as a
class ScanResultTile extends StatelessWidget {
  /// Creates an instance of [ScanResultTile].
  const ScanResultTile({
    required this.device,
    required this.onTap,
    super.key,
  });

  /// A [BleDevice] detected by the Bluetooth scanning process.
  final BleDevice device;

  /// A callback for taps on this scan result.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).primaryColorLight,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
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
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TableCell(
                    child: Text(
                      device.name ?? '--',
                      style: Theme.of(context).textTheme.bodySmall,
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
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TableCell(
                    child: Text(
                      device.address,
                      style: Theme.of(context).textTheme.bodySmall,
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
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TableCell(
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: LinearProgressIndicator(
                        value: (100 - device.rssi.abs()) / 100,
                        borderRadius: BorderRadius.circular(8.0),
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
