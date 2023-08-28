import 'package:flutter/material.dart';
import 'package:flutter_ble_example/screens/components/loading_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../device_details_controller.dart';

/// `ConnectButton` is a stateless widget that creates an outlined button
/// to handle device connections.
///
/// This button is specifically styled to have rounded bottom corners and a
/// custom border styling based on the current theme. The button's
/// behavior changes dynamically based on the `DeviceDetailsController` state.
class ConnectButton extends StatelessWidget {
  const ConnectButton({
    super.key,
    required this.state,
  });

  final DeviceDetailsController state;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
          ),
        ),
        side: BorderSide(
          color: Theme.of(context).primaryColorLight,
          width: 2.0,
        ),
      ),
      onPressed: state.onConnectTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!state.connecting)
            Text(
              AppLocalizations.of(context)!.connect.toUpperCase(),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 32,
                  ),
            ),
          if (state.connecting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: LoadingIndicator(
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}
