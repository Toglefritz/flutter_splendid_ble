import 'dart:async';

import 'package:flutter/services.dart';

/// Fans native callbacks out to every Dart listener so that BLE operations never replace each other's receivers.
///
/// Flutter permits one incoming handler per method channel, and all central callbacks share a single channel. This
/// router installs that one handler and republishes every incoming [MethodCall] on a shared broadcast stream.
/// Each operation (scan, connect, service discovery, adapter status, and so on) derives its own stream by filtering
/// on the callback's method name. Starting one operation therefore never silences the stream returned by another.
///
/// ## Untargeted `error` callbacks
///
/// The native layers report some failures with a bare `error` callback that names neither a device nor an operation.
/// Because the Dart side cannot tell which operation such an error belongs to, it is delivered only to the stream of
/// the most recently started operation that reports errors (see [operationCalls]). This matches the routing these
/// errors had before per-method fan-out existed.
class BleMethodChannelRouter {
  /// Installs the native receiver once for this messenger and channel.
  BleMethodChannelRouter._(MethodChannel channel) {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Returns the shared router, installing the native handler on first access.
  factory BleMethodChannelRouter.forChannel(MethodChannel channel) {
    final Map<String, BleMethodChannelRouter> routers =
        _routers[channel.binaryMessenger] ??=
            <String, BleMethodChannelRouter>{};

    return routers.putIfAbsent(
      channel.name,
      () => BleMethodChannelRouter._(channel),
    );
  }

  /// Routers shared across API instances using the same messenger and channel name.
  static final Expando<Map<String, BleMethodChannelRouter>> _routers =
      Expando<Map<String, BleMethodChannelRouter>>();

  /// The method name native code uses for failures that identify neither a device nor an operation.
  static const String errorMethod = 'error';

  /// Every native callback received on this channel, before subscribers filter by method name.
  ///
  /// This controller lives for the messenger's lifetime. Cancelling a derived stream listener releases that listener,
  /// not the shared receiver needed by other operations.
  final StreamController<MethodCall> _calls =
      StreamController<MethodCall>.broadcast();

  /// Identifies the operation that currently receives untargeted `error` callbacks.
  ///
  /// Replaced each time [operationCalls] is called. Null until the first such call.
  Object? _errorOwner;

  /// Returns native callbacks whose method name equals [method].
  ///
  /// Use this for streams that do not consume untargeted `error` callbacks, such as characteristic notifications,
  /// characteristic reads, and adapter or permission status updates. The returned stream is a broadcast stream.
  Stream<MethodCall> callsNamed(String method) {
    return _calls.stream.where((MethodCall call) => call.method == method);
  }

  /// Returns native callbacks named [method], plus untargeted `error` callbacks while this is the newest operation.
  ///
  /// Calling this makes the new stream the recipient of `error` callbacks, taking that role from any earlier stream.
  /// Callbacks named [method] keep reaching every earlier stream regardless. Consumers distinguish the two by checking
  /// whether [MethodCall.method] equals [errorMethod]. The returned stream is a broadcast stream.
  Stream<MethodCall> operationCalls(String method) {
    final Object owner = Object();
    _errorOwner = owner;

    return _calls.stream.where(
      (MethodCall call) =>
          call.method == method ||
          (call.method == errorMethod && identical(_errorOwner, owner)),
    );
  }

  /// Republishes a native callback to all derived streams.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    _calls.add(call);

    return null;
  }
}
