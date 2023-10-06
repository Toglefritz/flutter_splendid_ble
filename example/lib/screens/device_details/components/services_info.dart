import 'package:flutter/material.dart';
import 'package:flutter_ble/models/ble_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'characteristic_info.dart';

/// Contains a list of Bluetooth GATT services discovered from a Bluetooth device, each of which is presented in a
/// [ExpansionTile] that can be opened to view a list of Bluetooth characteristics under each service.
class ServicesInfo extends StatelessWidget {
  const ServicesInfo({
    super.key,
    required this.services,
    required this.characteristicOnTap,
  });

  /// A list of [BleService], representing Bluetooth GATT services discovered from a Bluetooth device.
  final List<BleService> services;

  /// A callback invoked when a characteristic is tapped.
  final Function characteristicOnTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(services.isNotEmpty ? 12.0 : 0.0),
          topRight: Radius.circular(services.isNotEmpty ? 12.0 : 0.0),
          bottomLeft: const Radius.circular(12.0),
          bottomRight: const Radius.circular(12.0),
        ),
        color: Theme.of(context).primaryColorLight.withOpacity(0.15),
        border: Border.all(
          color: Theme.of(context).primaryColorLight,
          width: 2.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: services.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  AppLocalizations.of(context)!.servicesNotDiscovered,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.services,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ...List.generate(
                    services.length,
                    (index) => Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.primaryService.toUpperCase(),
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).disabledColor,
                                  ),
                            ),
                            Text(
                              services[index].serviceUuid,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                        iconColor: Theme.of(context).primaryColor,
                        children: List.generate(
                          services[index].characteristics.length,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
                            child: CharacteristicInfo(
                              characteristic: services[index].characteristics[i],
                              characteristicOnTap: characteristicOnTap,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
