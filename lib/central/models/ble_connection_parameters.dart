import 'ble_phy.dart';

/// A snapshot of the active BLE link parameters for a connected device.
///
/// Populated by [SplendidBleCentral.readConnectionParameters]. On Android, PHY values come from the
/// [BluetoothGattCallback.onPhyRead] callback, and connection interval values come from
/// [BluetoothGattCallback.onConnectionUpdated]. Both callbacks fire automatically during connection setup, so by the
/// time the dashboard is displayed the cache should be populated.
///
/// On iOS, Core Bluetooth does not expose these link-layer parameters to the central role, so
/// [SplendidBleCentral.readConnectionParameters] returns null on that platform.
class BleConnectionParameters {
  /// Creates a [BleConnectionParameters] instance.
  const BleConnectionParameters({
    required this.txPhy,
    required this.rxPhy,
    this.connectionIntervalMs,
    this.slaveLatency,
    this.supervisionTimeoutMs,
  });

  /// The PHY currently in use for the outgoing (TX) link direction.
  final BlePhy txPhy;

  /// The PHY currently in use for the incoming (RX) link direction.
  final BlePhy rxPhy;

  /// Current connection interval in milliseconds.
  ///
  /// Derived from the BLE `connInterval` parameter, where each raw unit equals 1.25 ms. Null if the platform has not
  /// yet reported a connection parameter update event for this device.
  final double? connectionIntervalMs;

  /// The peripheral latency (slave latency) in number of connection events.
  ///
  /// The number of consecutive connection events the peripheral is allowed to skip without losing the connection. Zero
  /// means the peripheral must respond to every event.
  final int? slaveLatency;

  /// Supervision timeout in milliseconds.
  ///
  /// The maximum time the central waits without receiving data before declaring the connection lost. Derived from the
  /// BLE `supervisionTimeout` parameter, where each raw unit equals 10 ms.
  final int? supervisionTimeoutMs;

  /// Constructs a [BleConnectionParameters] from the map returned by the native platform over the method channel.
  ///
  /// The `txPhy` and `rxPhy` keys are required integers using the Android [BluetoothDevice] PHY constant values (1 = LE
  /// 1M, 2 = LE 2M, 3 = Coded). The remaining keys are optional and may be absent when the corresponding native
  /// callback has not yet fired.
  factory BleConnectionParameters.fromMap(Map<dynamic, dynamic> map) {
    return BleConnectionParameters(
      txPhy: BlePhy.fromIdentifier(map['txPhy'] as int),
      rxPhy: BlePhy.fromIdentifier(map['rxPhy'] as int),
      connectionIntervalMs: map['connectionIntervalMs'] != null
          ? (map['connectionIntervalMs'] as num).toDouble()
          : null,
      slaveLatency: map['slaveLatency'] as int?,
      supervisionTimeoutMs: map['supervisionTimeoutMs'] as int?,
    );
  }
}

