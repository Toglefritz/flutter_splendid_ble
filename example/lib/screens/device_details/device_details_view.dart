import 'package:flutter/material.dart';
import 'package:flutter_ble_example/extensions/string_capitalization.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../components/main_app_bar.dart';
import 'components/connect_button.dart';
import 'device_details_controller.dart';

/// View for the [StartScanRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class DeviceDetailsView extends StatelessWidget {
  final DeviceDetailsController state;

  const DeviceDetailsView(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
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
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  state.widget.device.name ?? state.widget.device.address,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12.0),
                      topRight: const Radius.circular(12.0),
                      bottomLeft: Radius.circular(state.isConnected ? 12.0 : 0.0),
                      bottomRight: Radius.circular(state.isConnected ? 12.0 : 0.0),
                    ),
                    color: Theme.of(context).primaryColorLight.withOpacity(0.15),
                    border: Border.all(
                      color: Theme.of(context).primaryColorLight,
                      width: 2.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Table(
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
                                state.widget.device.address,
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
                                state.currentConnectionState.name.capitalize(),
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
                                state.widget.device.rssi.toString(),
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
                                state.widget.device.manufacturerData.toString(),
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!state.isConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConnectButton(state: state),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
