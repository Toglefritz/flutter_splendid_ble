/// Represents the Bluetooth Low Energy physical layer (PHY) options for a connection.
///
/// Different PHYs offer trade-offs between throughput, range, and power consumption.
/// The actual PHY negotiated after a request depends on what both the central and
/// the peripheral support. Requesting a PHY that is unsupported by the peripheral
/// will result in the connection staying on the current PHY.
///
/// PHY selection applies to the LE link layer and is available on BLE 5.0+ hardware.
/// On older hardware, the platform may silently ignore the request.
enum BlePhy {
  /// 1 Mbps Bluetooth Low Energy PHY (LE 1M).
  ///
  /// The original and most widely supported BLE PHY. Offers a reliable balance
  /// of range and throughput. All BLE 4.0+ devices support LE 1M.
  le1m,

  /// 2 Mbps Bluetooth Low Energy PHY (LE 2M).
  ///
  /// Doubles the data rate compared to LE 1M by reducing the symbol interval.
  /// This shortens the time required to transmit the same payload, which is
  /// especially valuable for large data transfers such as firmware image delivery.
  ///
  /// Range is slightly reduced compared to LE 1M. Requires BLE 5.0+ on both
  /// the central and the peripheral.
  le2m,

  /// Coded Bluetooth Low Energy PHY (LE Coded).
  ///
  /// Applies forward error correction to extend the effective range at the cost
  /// of significantly reduced data throughput. Two coding schemes are defined:
  /// S=2 (roughly 500 kbps) and S=8 (roughly 125 kbps). The coding scheme is
  /// chosen by the peripheral.
  ///
  /// Requires BLE 5.0+ on both the central and the peripheral. Not suitable for
  /// high-throughput applications such as OTA firmware transfers.
  leCoded;

  /// The integer identifier used when communicating this PHY over the method channel.
  ///
  /// These values correspond directly to the Android [BluetoothDevice] PHY constants
  /// and are used as-is when calling the native API.
  ///
  /// - LE 1M → 1
  /// - LE 2M → 2
  /// - LE Coded → 3
  int get identifier {
    switch (this) {
      case BlePhy.le1m:
        return 1;
      case BlePhy.le2m:
        return 2;
      case BlePhy.leCoded:
        return 3;
    }
  }

  /// Constructs a [BlePhy] from the integer identifier returned by the platform.
  ///
  /// Falls back to [BlePhy.le1m] for any unrecognised value, which matches the
  /// behaviour of the BLE stack when an unsupported PHY is requested.
  static BlePhy fromIdentifier(int identifier) {
    switch (identifier) {
      case 2:
        return BlePhy.le2m;
      case 3:
        return BlePhy.leCoded;
      default:
        return BlePhy.le1m;
    }
  }
}

