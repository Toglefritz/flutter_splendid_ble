import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../components/fancy_outlined_text.dart';
import '../components/main_app_bar.dart';
import '../components/static_pattern_background.dart';
import 'package:flutter_ble_example/screens/start_scan/start_scan_controller.dart';

/// View for the [StartScanRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class StartScanView extends StatelessWidget {
  final StartScanController state;

  const StartScanView(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      extendBodyBehindAppBar: true,
      body: StaticPatternBackground(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: state.onStartScanTap,
                child: FancyOutlinedText(
                  text: AppLocalizations.of(context)!.startScan.toUpperCase(),
                ),
              ),
              if (state.permissionsGranted == false)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red[900],
                          size: 22,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.missingPermissions,
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
