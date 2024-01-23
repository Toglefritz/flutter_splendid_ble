/// The [ScanSettings] class encapsulates options that can be used to configure Bluetooth Low Energy (BLE) scan
/// behavior.
///
/// Use this class to specify options like the scan mode, report delay, whether to allow duplicates, and the desired
/// callback type.
///
/// Example usage:
/// ```dart
/// var settings = ScanSettings(scanMode: ScanMode.lowPower);
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

  /// Whether to report only unique advertisements or to include duplicates.
  ///
  /// If `true`, each advertisement is reported only once. If `false`, advertisements
  /// might be reported multiple times.
  final bool? allowDuplicates;

  /// Constructs a [ScanSettings] instance with the specified scan settings.
  ///
  /// [scanMode] determines the mode used for scanning.
  /// [reportDelayMillis] determines the delay for reporting results.
  /// [allowDuplicates] specifies whether to include duplicate advertisements.
  ScanSettings({
    this.scanMode,
    this.reportDelayMillis,
    this.allowDuplicates,
  });

  /// Converts the [ScanSettings] instance into a map representation.
  ///
  /// This method is useful for sending the settings data across platform channels.
  Map<String, dynamic> toMap() {
    return {
      'scanMode': scanMode,
      'reportDelayMillis': reportDelayMillis,
      'allowDuplicates': allowDuplicates,
    };
  }
}

/// Enumeration of BLE scan modes.
///
/// The values correspond to the scan modes provided by Android's BluetoothLeScanner.
/// You can choose from three predefined scan modes:
///   * `lowPower` (0): Balanced scanning, balancing power and latency.
///   * `balanced` (1): Low power scanning to conserve battery.
///   * `lowLatency` (2): Scan with highest duty cycle to discover devices faster.
enum ScanMode {
  lowPower(0),
  balanced(1),
  lowLatency(2);

  /// An identifier for the scan mode for use in interacting with the Android platform implementation of
  /// `BluetoothLeScanner`.
  final int identifier;

  const ScanMode(this.identifier);
}
