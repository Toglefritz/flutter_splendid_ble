import 'message_source.dart';

/// Represents a message sent between the host mobile device and a Bluetooth peripheral, in either direction.
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
