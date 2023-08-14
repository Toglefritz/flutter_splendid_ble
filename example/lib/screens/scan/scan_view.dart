import 'package:flutter/material.dart';
import 'package:flutter_ble_example/screens/scan/scan_controller.dart';

import '../components/main_app_bar.dart';

/// View for the [ScanRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class ScanView extends StatelessWidget {
  final ScanController state;

  const ScanView(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      extendBodyBehindAppBar: true,
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network('https://media.giphy.com/media/KEYEpIngcmXlHetDqz/giphy.gif'),
          ],
        ),
      ),
    );
  }
}
