/// Represents the connection priority (connection interval preference) for a BLE link.
///
/// Connection priority controls how frequently the central and peripheral exchange packets on the link layer. A shorter
/// connection interval increases throughput and reduces latency at the cost of higher power consumption on both
/// devices.
///
/// On Android this maps directly to the [BluetoothGatt.requestConnectionPriority] constants. On iOS, the connection
/// interval is managed entirely by the OS and requests from the central are not supported, so calls using this type are
/// no-ops on that platform.
enum BleConnectionPriority {
  /// Balanced connection interval (the default).
  ///
  /// The OS selects an interval that trades off latency and battery consumption in a way suited to typical interactive
  /// applications. This corresponds to roughly 30–50 ms on most Android devices.
  ///
  /// On Android, this maps to [BluetoothGatt.CONNECTION_PRIORITY_BALANCED] (value 0).
  balanced,

  /// High-priority (short) connection interval.
  ///
  /// Requests the shortest connection interval the platform will allow, reducing round-trip latency and increasing
  /// effective throughput. This is the correct choice before initiating a large data transfer such as an OTA firmware
  /// image delivery.
  ///
  /// Both the central and the peripheral consume more power while this priority is active. It is good practice to
  /// revert to [balanced] after the transfer completes.
  ///
  /// On Android, this maps to [BluetoothGatt.CONNECTION_PRIORITY_HIGH] (value 1), which typically yields a 11.25–15 ms
  /// connection interval.
  high,

  /// Low-power (long) connection interval.
  ///
  /// Requests a longer connection interval to minimise radio wake-ups and reduce power consumption. Throughput and
  /// latency are reduced accordingly. Suitable when the connection is mostly idle.
  ///
  /// On Android, this maps to [BluetoothGatt.CONNECTION_PRIORITY_LOW_POWER] (value 2).
  lowPower;

  /// The integer identifier used when communicating this priority over the method channel.
  ///
  /// The values match the Android [BluetoothGatt] CONNECTION_PRIORITY_* constants.
  ///
  /// - balanced  → 0
  /// - high      → 1
  /// - lowPower  → 2
  int get identifier {
    switch (this) {
      case BleConnectionPriority.balanced:
        return 0;
      case BleConnectionPriority.high:
        return 1;
      case BleConnectionPriority.lowPower:
        return 2;
    }
  }
}

