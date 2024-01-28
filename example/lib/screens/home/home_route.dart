import 'package:flutter/material.dart';

import 'home_controller.dart';

/// A quite simple little screen. It has a button in the middle to start a scan for nearby Bluetooth devices.
class HomeRoute extends StatefulWidget {
  const HomeRoute({Key? key}) : super(key: key);

  @override
  HomeController createState() => HomeController();
}
