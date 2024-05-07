import 'message_source.dart';

/// Represents a message sent between the host mobile device and a Bluetooth peripheral or central device, in either
/// direction. In other words, this class is used regardless of whether the app is acting as a Bluetooth peripheral or
/// central device.
class Message {
  /// The contents of the message in string format.
  final String contents;

  /// The originator of the message, either the mobile device or the Bluetooth peripheral.
  final MessageSource source;

  Message({
    required this.contents,
    required this.source,
  });
}
