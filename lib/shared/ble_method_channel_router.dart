import 'dart:async';

import 'package:flutter/services.dart';

/// Keeps characteristic notifications independent of the current BLE operation's callback handler.
///
/// Flutter permits one incoming handler per method channel. This router reserves characteristic-change events for a
/// shared broadcast stream while preserving the existing handler-replacement behavior for other native callbacks.
class BleMethodChannelRouter {
  /// Installs the native receiver once for this messenger and channel.
  BleMethodChannelRouter._(MethodChannel channel) {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Routers shared across API instances using the same messenger and channel name.
  static final Expando<Map<String, BleMethodChannelRouter>> _routers = Expando<Map<String, BleMethodChannelRouter>>();

  /// Native characteristic changes, before subscribers filter by device address and UUID.
  ///
  /// This controller lives for the messenger's lifetime. Cancelling a derived stream listener releases that listener,
  /// not the shared receiver needed by other characteristics.
  final StreamController<MethodCall> _characteristicChanges = StreamController<MethodCall>.broadcast();

  /// The existing callback owner for events other than characteristic notifications.
  Future<dynamic> Function(MethodCall call)? _operationHandler;

  /// Returns the shared router, installing the native handler on first access.
  factory BleMethodChannelRouter.forChannel(MethodChannel channel) {
    final Map<String, BleMethodChannelRouter> routers =
        _routers[channel.binaryMessenger] ??= <String, BleMethodChannelRouter>{};
    
    return routers.putIfAbsent(channel.name, () => BleMethodChannelRouter._(channel));
  }

  /// Returns all characteristic-change callbacks. Consumers must filter by device address and UUID before decoding.
  Stream<MethodCall> get characteristicChanges => _characteristicChanges.stream;

  /// Changes the non-notification callback owner without interrupting characteristic streams.
  ///
  /// Passing null releases the current operation handler, for example after a characteristic read completes.
  static void setOperationHandler(MethodChannel channel, Future<dynamic> Function(MethodCall call)? handler) {
    BleMethodChannelRouter.forChannel(channel)._operationHandler = handler;
  }

  /// Routes notifications to their stream and delegates other callbacks to the current operation.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onCharacteristicChanged') {
      _characteristicChanges.add(call);
      return null;
    }

    return _operationHandler?.call(call);
  }
}
