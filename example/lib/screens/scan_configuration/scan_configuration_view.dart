import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_splendid_ble/central/models/scan_settings.dart';
import 'package:flutter_splendid_ble_example/screens/scan_configuration/scan_configuration_controller.dart';

import '../components/main_app_bar.dart';

/// View for the [StartScanRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class ScanConfigurationView extends StatelessWidget {
  final ScanConfigurationController state;

  const ScanConfigurationView(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32.0, 16.0, 32.0, 32.0),
        child: Form(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.scanSettings,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                DropdownButtonFormField<ScanMode>(
                  value: state.scanMode,
                  items: [
                    DropdownMenuItem(
                      value: ScanMode.lowPower,
                      child: Text(AppLocalizations.of(context)!.lowPower),
                    ),
                    DropdownMenuItem(
                      value: ScanMode.balanced,
                      child: Text(AppLocalizations.of(context)!.balanced),
                    ),
                    DropdownMenuItem(
                      value: ScanMode.lowLatency,
                      child: Text(AppLocalizations.of(context)!.lowLatency),
                    ),
                  ],
                  onChanged: (value) => state.onScanModeChanged(value),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.scanMode,
                  ),
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.reportDelay,
                  ),
                  validator: (value) => state.validateReportDelay(value),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context)!.allowDuplicates),
                  value: state.allowDuplicates,
                  onChanged: (value) => state.onAllowDuplicatesChanged(value),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    AppLocalizations.of(context)!.scanFilters,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.deviceName,
                  ),
                  onChanged: (value) => state.onDeviceNameChanged(value),
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.manufacturerId,
                  ),
                  onChanged: (value) => state.onManufacturerIdChanged(value),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.serviceUuids,
                  ),
                  onChanged: (value) => state.onServiceUuidsChanged(value),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 64.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).primaryColorLight,
                        width: 2.0,
                      ),
                    ),
                    onPressed: state.onDone,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.done.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontSize: 32,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
