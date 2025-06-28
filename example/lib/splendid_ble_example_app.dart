import 'package:flutter/material.dart';
import 'splendid_ble_example_material_app.dart';

/// A [StatelessWidget] that builds the root [MaterialApp] for the Flutter BLE Example App.
///
/// This widget is responsible for creating the main application structure with an app bar and body content. The app
/// bar displays the title 'Flutter Splendid BLE Example App', and the body includes an animated image from a network
/// URL.
///
/// The [SplendidBleExampleApp] is returned by the [runApp] method in main.dart and serves as the starting point for
/// the example application, setting the stage for any additional screens, widgets, or functionalities that might be
/// added.
class SplendidBleExampleApp extends StatelessWidget {
  /// Creates an instance of [SplendidBleExampleApp].
  const SplendidBleExampleApp({super.key});

  @override
  Widget build(BuildContext context) => const SplendidBleExampleMaterialApp();
}
