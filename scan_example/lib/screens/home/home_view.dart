import 'package:flutter/material.dart';
import 'package:scan_example/screens/home/home_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'components/scan_result_title.dart';
import 'home_route.dart';

/// View for the [HomeRoute].
class HomeView extends StatelessWidget {
  final HomeController state;

  const HomeView(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scanning Example'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          if (state.discoveredDevices.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        ' ¯\\_(ツ)_/¯',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.noDevices,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).primaryColorLight,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          if (state.discoveredDevices.isNotEmpty)
            SliverList.list(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    AppLocalizations.of(context)!.discoveredDevices,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).primaryColorLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ...List.generate(
                  state.discoveredDevices.length,
                  (index) => state.discoveredDevices[index].name != null
                      ? ScanResultTile(
                          device: state.discoveredDevices[index],
                        )
                      : const SizedBox.shrink(),
                )
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.scanInProgress ? state.stopScan : state.startScan,
        tooltip: 'Start scan',
        child: state.scanInProgress ? const Icon(Icons.stop_outlined) : const Icon(Icons.play_arrow_outlined),
      ),
    );
  }
}
