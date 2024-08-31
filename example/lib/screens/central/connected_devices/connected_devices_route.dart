import 'package:flutter/material.dart';

import 'connected_devices_controller.dart';

/// Automatically starts a scan for nearby Bluetooth devices and presents the detected devices in a list.
class ConnectedDevicesRoute extends StatefulWidget {
  /// Creates an instance of [ConnectedDevicesRoute].
  const ConnectedDevicesRoute({
    super.key,
  });

  @override
  ConnectedDevicesController createState() => ConnectedDevicesController();
}
