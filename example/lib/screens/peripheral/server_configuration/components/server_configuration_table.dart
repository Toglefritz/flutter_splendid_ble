import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../server_configuration_controller.dart';

/// A [Table] used to display configuration information about the server that will be created by the
/// [ServerConfigurationRoute].
class ServerConfigurationTable extends StatelessWidget {
  /// A controller for this widget that contains business logic.
  final ServerConfigurationController state;

  const ServerConfigurationTable({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            TableCell(
              child: Text(
                AppLocalizations.of(context)!.deviceName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 18.0,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            TableCell(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(
                  right: 32.0,
                  bottom: 8.0,
                ),
                child: TextField(
                  controller: state.serverNameController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.peripheralName,
                  ),
                ),
              ),
            ),
          ],
        ),
        TableRow(
          children: <Widget>[
            TableCell(
              child: Text(
                AppLocalizations.of(context)!.primaryService,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 18.0,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            TableCell(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(
                  right: 32.0,
                  bottom: 8.0,
                ),
                child: TextField(
                  controller: state.primaryServiceController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.primaryServiceLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
        TableRow(
          children: <Widget>[
            TableCell(
              child: Text(
                AppLocalizations.of(context)!.characteristics,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 18.0,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            TableCell(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(
                  right: 32.0,
                  bottom: 8.0,
                ),
                child: TextField(
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.characteristicsFieldLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
