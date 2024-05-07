import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_splendid_ble_example/screens/peripheral/server_interaction/server_interaction_controller.dart';

import '../../components/main_app_bar.dart';
import '../../models/message_source.dart';

/// View for the [CharacteristicInteractionRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class ServerInteractionView extends StatelessWidget {
  final ServerInteractionController state;

  const ServerInteractionView(this.state, {Key? key}) : super(key: key);

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
      body: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
          maxWidth: MediaQuery.of(context).size.width,
          minHeight: MediaQuery.of(context).size.height,
          maxHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                AppLocalizations.of(context)!.serverInteraction,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            Card(
              margin: EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 48.0),
                    child: Text(
                      AppLocalizations.of(context)!.enableAdvertising,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 48.0),
                    child: Switch(
                      value: state.isAdvertising,
                      onChanged: state.onAdvertisingSwitchChanged,
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              itemCount: state.messages.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                // TODO update widget
                return Card(
                  margin: EdgeInsets.only(
                    left: state.messages[index].source == MessageSource.mobile ? 48.0 : 16.0,
                    right: state.messages[index].source == MessageSource.peripheral ? 48.0 : 16.0,
                    top: 8.0,
                    bottom: 8.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 0.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.messages[index].contents,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Icon(
                          state.messages[index].source == MessageSource.mobile ? Icons.upload : Icons.download,
                          color: Theme.of(context).disabledColor,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // TextField with rounded top left and bottom left corners.
                        Container(
                          width: 300,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2.0,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12.0),
                              bottomLeft: Radius.circular(12.0),
                            ),
                          ),
                          child: TextField(
                            controller: state.controller,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 10.0,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                            cursorColor: Theme.of(context).primaryColor,
                            onSubmitted: (value) => state.onEntrySubmitted,
                          ),
                        ),
                        // OutlinedButton with rounded top right and bottom right corners.
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2.0,
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12.0),
                              bottomRight: Radius.circular(12.0),
                            ),
                          ),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide.none, // No border as it's already set by Container.
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12.0),
                                  bottomRight: Radius.circular(12.0),
                                ),
                              ),
                            ),
                            onPressed: state.onEntrySubmitted,
                            child: Icon(
                              Icons.send,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
