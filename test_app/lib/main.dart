import 'package:flutter/material.dart';
import 'app.dart';

/// Flutter Splendid BLE Test Application entry point.
///
/// This application provides manual testing capabilities for the Flutter Splendid BLE plugin.
/// It runs systematic end-to-end tests against an ESP32 test device while allowing users
/// to naturally handle system-level interactions like Bluetooth pairing dialogs.
///
/// The app presents test results in a terminal-style interface with blue text on a dark
/// background, providing clear visual feedback for each BLE operation tested.
void main() {
  runApp(
    const TestApp(),
  );
}
