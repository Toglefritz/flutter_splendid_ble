/// The [ScanSettings] class encapsulates options that can be used to configure Bluetooth Low Energy (BLE) scan
/// behavior.
///
/// Use this class to specify options like the scan mode, report delay, whether to allow duplicates, and the desired
/// callback type.
///
/// On Android 8 (API 26) and above, [legacyMode] controls whether scanning is restricted to legacy PDUs. Setting it to
/// `false` (the default when omitted) enables extended advertising, which is necessary to receive scan response data
/// from devices that split their advertisement payload across two packets.
///
/// Example usage:
/// ```dart
/// var settings = ScanSettings(scanMode: ScanMode.lowPower, legacyMode: false);
/// ```
class ScanSettings {
  /// The mode to be used for the BLE scan.
  ///
  /// This can be one of [ScanMode.lowPower], [ScanMode.balanced], or [ScanMode.lowLatency].
  final ScanMode? scanMode;

  /// The delay in milliseconds for reporting the scan results.
  ///
  /// Defaults to 0, which means results are reported as soon as they are available.
  final int? reportDelayMillis;

  /// Whether the operating system should deliver every advertisement it receives, including repeats from devices it
  /// has already reported.
  ///
  /// Regardless of this setting, the plugin reports each device once when it is first discovered, and again only when
  /// its advertised content (name, manufacturer data, or advertised service UUIDs) changes during the scan. A change in
  /// RSSI alone never produces another report. A result that omits a field, such as an advertisement received without
  /// its scan response, keeps the value last reported for that field.
  ///
  /// This setting controls how often the plugin can notice such changes:
  ///
  /// * **iOS / macOS:** When `true`, CoreBluetooth delivers every advertisement packet, so content changes are noticed
  ///   promptly. When `false` or `null` (the CoreBluetooth default), CoreBluetooth coalesces repeated advertisements
  ///   from a device, and later content changes may be noticed late or not at all. Delivering every packet increases
  ///   power use.
  /// * **Android:** No effect. Android always delivers repeated advertisements to the plugin.
  final bool? allowDuplicates;

  /// Whether to restrict scanning to legacy BLE advertising PDUs.
  ///
  /// When set to `false` on Android 8 (API 26) and above, the scanner operates in non-legacy mode and can receive
  /// extended advertising PDUs. This is required for devices that send additional data in a scan response packet. When
  /// this field is `null`, the Android side defaults to `false` (non-legacy) so that scan response data is always
  /// included when the hardware supports it.
  ///
  /// This field has no effect on iOS or older Android versions.
  final bool? legacyMode;

  /// Constructs a [ScanSettings] instance with the specified scan settings.
  ScanSettings({
    this.scanMode,
    this.reportDelayMillis,
    this.allowDuplicates,
    this.legacyMode,
  });

  /// Converts the [ScanSettings] instance into a map representation.
  ///
  /// This method is useful for sending the settings data across platform channels.
  Map<String, dynamic> toMap() {
    return {
      'scanMode': scanMode?.identifier,
      'reportDelayMillis': reportDelayMillis,
      'allowDuplicates': allowDuplicates,
      if (legacyMode != null) 'legacy': legacyMode,
    };
  }
}

/// Enumeration of BLE scan modes.
///
/// The values correspond to the scan modes provided by Android's BluetoothLeScanner. You can choose from three
/// predefined scan modes:
/// * `lowPower` (0): Balanced scanning, balancing power and latency.
/// * `balanced` (1): Low power scanning to conserve battery.
/// * `lowLatency` (2): Scan with highest duty cycle to discover devices faster.
enum ScanMode {
  /// Balanced scanning, balancing power and latency.
  lowPower(0),

  /// Low power scanning to conserve battery.
  balanced(1),

  /// Scan with highest duty cycle to discover devices faster.
  lowLatency(2);

  /// An identifier for the scan mode for use in interacting with the Android platform implementation of
  /// `BluetoothLeScanner`.
  final int identifier;

  const ScanMode(this.identifier);
}
