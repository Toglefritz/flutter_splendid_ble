import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../components/main_app_bar.dart';
import 'characteristic_interaction_controller.dart';
import 'characteristic_interaction_route.dart';
import 'models/message_source.dart';

/// View for the [CharacteristicInteractionRoute]. The view is dumb, and purely declarative. References values
/// on the controller and widget.
class CharacteristicInteractionView extends StatelessWidget {
  /// A reference to the controller for the [CharacteristicInteractionRoute].
  final CharacteristicInteractionController state;

  /// Creates an instance of [CharacteristicInteractionView].
  const CharacteristicInteractionView(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
          maxWidth: MediaQuery.of(context).size.width,
          minHeight: MediaQuery.of(context).size.height,
          maxHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                AppLocalizations.of(context)!.characteristicInteraction,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Text(
                state.widget.characteristic.uuid,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            ListView.builder(
              itemCount: state.messages.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                // TODO(Toglefritz): update widget
                return Card(
                  margin: EdgeInsets.only(
                    left: state.messages[index].source == MessageSource.mobile
                        ? 48.0
                        : 16.0,
                    right:
                        state.messages[index].source == MessageSource.peripheral
                            ? 48.0
                            : 16.0,
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
                          state.messages[index].source == MessageSource.mobile
                              ? Icons.upload
                              : Icons.download,
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
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // TextField with rounded top left and bottom left corners.
                        Container(
                          width: 600,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12.0),
                            ),
                          ),
                          child: TextField(
                            controller: state.controller,
                            minLines: 1,
                            maxLines: null,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 10.0,
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: GestureDetector(
                                onTap: state.onEntrySubmitted,
                                child: Icon(
                                  Icons.send,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                            cursorColor: Theme.of(context).primaryColor,
                            onSubmitted: (value) => state.onEntrySubmitted,
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
