import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_splendid_ble/models/ble_connection_state.dart';
import 'package:flutter_splendid_ble/models/ble_device.dart';
import 'package:flutter_splendid_ble_example/extensions/string_capitalization.dart';

/// A [Table] used to display information about the given [device], which is an instance of [BleDevice].
class DeviceDetailsTable extends StatelessWidget {
  const DeviceDetailsTable({
    required this.device,
    required this.connectionState,
    super.key,
  });

  /// The [BleDevice] about which the [DeviceDetailsTable] displays information.
  final BleDevice device;

  /// The [BleConnectionState] representing the state of the connection between the [device] and the host
  /// mobile device.
  final BleConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            TableCell(
              child: Container(
                height: 40.0,
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context)!.address,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18.0,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            TableCell(
              child: Container(
                height: 40.0,
                alignment: Alignment.center,
                child: Text(
                  device.address,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        TableRow(
          children: <Widget>[
            TableCell(
              child: Container(
                height: 40.0,
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context)!.connectionStatus,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18.0,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            TableCell(
              child: Container(
                height: 40.0,
                alignment: Alignment.center,
                child: Text(
                  connectionState.name.capitalize(),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        TableRow(
          children: <Widget>[
            TableCell(
              child: Container(
                height: 40.0,
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context)!.rssi,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18.0,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            TableCell(
              child: Container(
                height: 40.0,
                alignment: Alignment.center,
                child: Text(
                  device.rssi.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        TableRow(
          children: <Widget>[
            TableCell(
              child: Container(
                height: 40.0,
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context)!.manufacturerData,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18.0,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            TableCell(
              child: Container(
                height: 40.0,
                alignment: Alignment.center,
                child: Text(
                  device.manufacturerData.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
