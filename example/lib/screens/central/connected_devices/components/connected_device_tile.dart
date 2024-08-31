import 'package:flutter/material.dart';
import 'package:flutter_splendid_ble/central/models/connected_ble_device.dart';

/// Displays information about a Bluetooth device that is currently connected to the host device.
class ConnectedDeviceTile extends StatelessWidget {
  /// Creates an instance of [ConnectedDeviceTile].
  const ConnectedDeviceTile({
    required this.device,
    required this.onTap,
    super.key,
  });

  /// A [ConnectedBleDevice] object containing information about the connected Bluetooth device.
  final ConnectedBleDevice device;

  /// A callback for taps on this scan result.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).primaryColorLight,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(device.name ?? device.address),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
