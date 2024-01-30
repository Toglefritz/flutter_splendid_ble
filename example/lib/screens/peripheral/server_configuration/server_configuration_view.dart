import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter_splendid_ble_example/screens/peripheral/server_configuration/server_configuration_controller.dart';
import '../../components/main_app_bar.dart';
import '../../components/table_button.dart';
import 'components/server_configuration_table.dart';

/// View for the [ServerConfigurationRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class ServerConfigurationView extends StatelessWidget {
  /// A controller for this view that contains business logic.
  final ServerConfigurationController state;

  const ServerConfigurationView(
    this.state, {
    Key? key,
  }) : super(key: key);

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
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  AppLocalizations.of(context)!.serverConfiguration,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12.0),
                      topRight: const Radius.circular(12.0),
                      bottomLeft: Radius.zero,
                      bottomRight: Radius.zero,
                    ),
                    color: Theme.of(context).primaryColorLight.withOpacity(0.15),
                    border: Border.all(
                      color: Theme.of(context).primaryColorLight,
                      width: 2.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ServerConfigurationTable(
                    state: state,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TableButton(
                  onTap: state.onCreateTap,
                  side: ButtonSide.bottom,
                  text: AppLocalizations.of(context)!.create.toUpperCase(),
                  loading: state.creatingServer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
