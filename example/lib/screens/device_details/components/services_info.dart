import 'package:flutter/material.dart';
import 'package:flutter_ble/models/ble_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Contains a list of Bluetooth GATT services discovered from a Bluetooth device, each of which is presented in a
/// [ExpansionTile] that can be opened to view a list of Bluetooth characteristics under each service.
// TODO make the characteristic lists buttons to enable interaction with the characteristics
class ServicesInfo extends StatelessWidget {
  const ServicesInfo({
    super.key,
    required this.services,
  });

  /// A list of [BleService], representing Bluetooth GATT services discovered from a Bluetooth device.
  final List<BleService> services;

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
                        title: Text(
                          services[index].serviceUuid,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        iconColor: Theme.of(context).primaryColor,
                        children: List.generate(
                          services[index].characteristics.length,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              services[index].characteristics[i].uuid,
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
