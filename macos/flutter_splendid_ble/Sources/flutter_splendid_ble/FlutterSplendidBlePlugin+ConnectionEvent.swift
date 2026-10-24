import FlutterMacOS
import CoreBluetooth

/// Connection-event payload construction and error normalization for `FlutterSplendidBlePlugin`.
///
/// ## Purpose
///
/// Connection lifecycle updates are delivered to the Dart side through the `bleConnectionState_<deviceAddress>` method
/// channel call. This extension centralizes the construction of that call's argument payload so that every connection
/// callback — `didConnect`, `didFailToConnect`, and `didDisconnectPeripheral` — emits a consistent, richly-detailed
/// map rather than a bare status string.
///
/// ## Payload contract
///
/// Every connection update sends a `[String: Any?]` map with the following keys:
///
/// * `state` — one of `"connected"`, `"disconnected"`, `"connecting"`, `"disconnecting"`, `"failed"`, `"unknown"`.
/// * `platform` — always `"macos"` on this platform; lets the Dart side interpret `errorCode`/`errorDomain`.
/// * `category` — the normalized `BleConnectionFailureCategory` identifier, present only for failure/unexpected-
///   disconnect payloads.
/// * `errorCode` — the raw `NSError` code, when CoreBluetooth provides an error.
/// * `errorDomain` — the raw `NSError` domain (such as `CBErrorDomain`), when available.
/// * `errorDescription` — the `NSError` `localizedDescription`, when available.
///
/// The error keys are omitted (absent from the map) when no error was supplied. CoreBluetooth frequently delivers a
/// `nil` error on `didFailToConnect`, in which case only `state`, `platform`, and `category` (`"unknown"`) are sent.
extension FlutterSplendidBlePlugin {

    /// The host platform identifier sent in every connection payload from this plugin.
    static let connectionEventPlatform: String = "macos"

    /// Builds the method channel payload for a connection lifecycle update.
    ///
    /// - Parameters:
    ///   - state: The connection state identifier (for example `"connected"` or `"failed"`).
    ///   - error: The `Error?` supplied by the CoreBluetooth callback, if any. When non-nil, its `NSError` code,
    ///     domain, and description are included and a normalized failure `category` is derived from it. When nil and
    ///     [state] is `"failed"`, the `category` is reported as `"unknown"`.
    /// - Returns: A `[String: Any?]` map suitable for passing as the `arguments` of the
    ///   `bleConnectionState_<deviceAddress>` method channel call.
    func makeConnectionEventPayload(state: String, error: Error?) -> [String: Any?] {
        var payload: [String: Any?] = [
            "state": state,
            "platform": FlutterSplendidBlePlugin.connectionEventPlatform,
        ]

        guard let nsError = error as NSError? else {
            // No error object. A "failed" state always represents a failure, so still report a category (CoreBluetooth
            // commonly delivers a nil error here). A "disconnected" state with no error is a clean, intentional
            // disconnect and must carry no failure detail, so nothing further is added.
            if state == "failed" {
                payload["category"] = BleConnectionFailureCategory.unknown.rawValue
            }
            return payload
        }

        payload["errorCode"] = nsError.code
        payload["errorDomain"] = nsError.domain
        payload["errorDescription"] = nsError.localizedDescription
        payload["category"] = BleConnectionFailureCategory.from(nsError: nsError).rawValue

        return payload
    }
}

/// A normalized, platform-agnostic classification of a BLE connection failure.
///
/// Mirrors the Dart `BleConnectionFailureCategory` enum. The raw values must stay in sync with the `identifier`
/// strings defined on the Dart side so that the category round-trips across the method channel.
enum BleConnectionFailureCategory: String {
    case timeout
    case peerTerminated
    case hostTerminated
    case authenticationFailure
    case connectionLimitReached
    case unreachable
    case unknown

    /// Derives a [BleConnectionFailureCategory] from a CoreBluetooth `NSError`.
    ///
    /// Recognizes error codes in `CBErrorDomain` (connection-level failures) and `CBATTErrorDomain` (attribute-level
    /// failures, which can surface during pairing-triggered operations). Any unrecognized code or domain maps to
    /// [unknown], preserving the raw code on the payload for deeper inspection on the Dart side.
    ///
    /// - Parameter nsError: The error reported by a CoreBluetooth connection callback.
    /// - Returns: The normalized category that best describes the failure.
    static func from(nsError: NSError) -> BleConnectionFailureCategory {
        if nsError.domain == CBErrorDomain {
            guard let code = CBError.Code(rawValue: nsError.code) else {
                return .unknown
            }

            switch code {
            case .connectionTimeout:
                return .timeout
            case .peripheralDisconnected:
                return .peerTerminated
            case .connectionLimitReached:
                return .connectionLimitReached
            case .encryptionTimedOut:
                return .authenticationFailure
            case .unknownDevice:
                return .unreachable
            default:
                return .unknown
            }
        }

        if nsError.domain == CBATTErrorDomain {
            guard let code = CBATTError.Code(rawValue: nsError.code) else {
                return .unknown
            }

            switch code {
            case .insufficientAuthentication,
                 .insufficientEncryption,
                 .insufficientAuthorization:
                return .authenticationFailure
            default:
                return .unknown
            }
        }

        return .unknown
    }
}
