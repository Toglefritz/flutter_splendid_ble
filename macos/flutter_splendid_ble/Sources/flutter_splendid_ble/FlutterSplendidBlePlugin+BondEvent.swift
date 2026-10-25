import Foundation
import CoreBluetooth

/// Bonding diagnostics for `FlutterSplendidBlePlugin` on macOS.
///
/// ## A known platform limitation
///
/// Like iOS, macOS does **not** expose a bonding (pairing) API, a bond-state callback, or a bonding failure reason to
/// apps. CoreBluetooth deliberately hides the pairing process behind the operating system: an app can only *provoke*
/// bonding by interacting with an encrypted characteristic, and the OS performs the pairing exchange out of band. There
/// is no `didBond` / `didFailToBond` delegate method, and no way to read a device's bond state.
///
/// As a result, the bonding visibility this plugin can offer on macOS is intentionally limited and best-effort. The
/// only observable proxy is the lifecycle of an operation on an encrypted characteristic:
///
/// * When such an operation begins, the OS may transparently initiate pairing — reported here as `"bonding"`.
/// * When the operation succeeds, any required bond is in place — reported here as `"bonded"`.
/// * When the operation fails with an authentication/encryption `CBATTError` (or a `CBError`), the bond could not be
///   established — reported here as `"failed"` with whatever `NSError` detail CoreBluetooth provided.
///
/// This keeps the plugin's bonding interaction contract similar across platforms (the Dart `observeBondState` stream
/// emits `BleBondEvent`s on both), while being honest that the *detail* available on macOS is far coarser than the
/// unbond-reason codes Android provides. See the Dart `BleBondFailure` documentation for the consumer-facing note.
extension FlutterSplendidBlePlugin {

    /// The host platform identifier sent in every bonding payload from this plugin.
    static let bondEventPlatform: String = "macos"

    /// Builds the method channel payload for a bonding lifecycle update.
    ///
    /// - Parameters:
    ///   - state: The bonding state identifier (`"none"`, `"bonding"`, `"bonded"`, or `"failed"`).
    ///   - error: The `Error?` supplied by the CoreBluetooth callback, if any. When non-nil, its `NSError` code,
    ///     domain, and description are included and a normalized failure `category` is derived from it. When nil and
    ///     [state] is `"failed"`, the `category` is reported as `"unknown"`.
    /// - Returns: A `[String: Any?]` map suitable for passing as the `arguments` of the
    ///   `bleBondState_<deviceAddress>` method channel call.
    func makeBondEventPayload(state: String, error: Error?) -> [String: Any?] {
        var payload: [String: Any?] = [
            "state": state,
            "platform": FlutterSplendidBlePlugin.bondEventPlatform,
        ]

        guard let nsError = error as NSError? else {
            // No error object. A "failed" state still represents a failure, so report a category (CoreBluetooth often
            // supplies no error detail for bonding-related failures). Non-failure states carry no failure detail.
            if state == "failed" {
                payload["category"] = BleBondFailureCategory.unknown.rawValue
            }
            return payload
        }

        payload["errorCode"] = nsError.code
        payload["errorDomain"] = nsError.domain
        payload["errorDescription"] = nsError.localizedDescription
        payload["category"] = BleBondFailureCategory.from(nsError: nsError).rawValue

        return payload
    }

    /// Emits a bonding lifecycle update for the given device to the Dart side.
    ///
    /// Sends a `bleBondState_<deviceAddress>` method channel call whose arguments are built by
    /// `makeBondEventPayload(state:error:)`. This is the single funnel through which all macOS bonding updates reach
    /// Dart.
    ///
    /// - Parameters:
    ///   - deviceAddress: The peripheral identifier (UUID string) this update concerns.
    ///   - state: The bonding state identifier.
    ///   - error: The optional error associated with a `"failed"` state.
    func emitBondState(deviceAddress: String, state: String, error: Error?) {
        let payload = makeBondEventPayload(state: state, error: error)
        centralChannel.invokeMethod("bleBondState_\(deviceAddress)", arguments: payload)
    }
}

/// A normalized, platform-agnostic classification of a BLE bonding failure.
///
/// Mirrors the Dart `BleBondFailureCategory` enum. The raw values must stay in sync with the `identifier` strings
/// defined on the Dart side so that the category round-trips across the method channel.
///
/// On macOS the only failures observable in the bonding path are attribute-level (`CBATTError`) or connection-level
/// (`CBError`) errors from an operation on an encrypted characteristic, so in practice this resolves to
/// `authenticationFailure` or `unknown`. The richer categories defined on the Dart side (rejected, timeout, remote
/// device down, removed) are Android-only because macOS does not report those reasons.
enum BleBondFailureCategory: String {
    case authenticationFailure
    case authenticationRejected
    case authenticationTimeout
    case remoteDeviceDown
    case removed
    case unknown

    /// Derives a [BleBondFailureCategory] from a CoreBluetooth `NSError`.
    ///
    /// Recognizes the authentication/encryption codes in `CBATTErrorDomain` (which surface when an operation on an
    /// encrypted characteristic cannot be secured) and `CBErrorDomain` (`encryptionTimedOut`). Any unrecognized code or
    /// domain maps to [unknown], preserving the raw code on the payload for deeper inspection on the Dart side.
    ///
    /// - Parameter nsError: The error reported by a CoreBluetooth callback in the encrypted-operation path.
    /// - Returns: The normalized category that best describes the failure.
    static func from(nsError: NSError) -> BleBondFailureCategory {
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

        if nsError.domain == CBErrorDomain {
            guard let code = CBError.Code(rawValue: nsError.code) else {
                return .unknown
            }

            switch code {
            case .encryptionTimedOut:
                return .authenticationFailure
            default:
                return .unknown
            }
        }

        return .unknown
    }
}
