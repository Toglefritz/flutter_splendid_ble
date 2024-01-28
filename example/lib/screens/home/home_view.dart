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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: state.onStartScanTap,
              onLongPress: state.onStartScanLongPress,
              child: Text(
                AppLocalizations.of(context)!.startScan.toUpperCase(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: Theme.of(context).textTheme.bodyLarge?.fontSize,
                      width: MediaQuery.of(context).size.width * 0.2,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 4.0,
                          ),
                          bottom: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        AppLocalizations.of(context)!.or.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Container(
                      height: Theme.of(context).textTheme.bodyLarge?.fontSize,
                      width: MediaQuery.of(context).size.width * 0.2,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2.0,
                          ),
                          bottom: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 4.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: state.onCreateServerTap,
              onLongPress: state.onStartScanLongPress,
              child: Text(
                AppLocalizations.of(context)!.createServer.toUpperCase(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            if (state.permissionsGranted == false)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ErrorMessage(
                  error: AppLocalizations.of(context)!.missingPermissions,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: state.bluetoothStatus != BluetoothStatus.enabled
          ? SafeArea(
              child: ErrorMessage(
                error: state.bluetoothStatus == BluetoothStatus.disabled
                    ? AppLocalizations.of(context)!.bluetoothDisabled
                    : AppLocalizations.of(context)!.notAvailable,
              ),
            )
          : null,
    );
  }
}
