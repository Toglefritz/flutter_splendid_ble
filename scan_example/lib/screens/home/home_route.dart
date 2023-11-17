import 'package:flutter/material.dart';

import 'home_controller.dart';

/// Displays a FAB used to start or stop the Bluetooth scan and displays BLE devices detected during the scanning
/// process.
class HomeRoute extends StatefulWidget {
  const HomeRoute({super.key});

  @override
  State<HomeRoute> createState() => HomeController();
}