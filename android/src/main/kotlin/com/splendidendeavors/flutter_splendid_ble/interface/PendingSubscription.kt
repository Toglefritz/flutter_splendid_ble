package com.splendidendeavors.flutter_splendid_ble.`interface`

import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * Represents a pending subscription operation that is waiting for confirmation.
 *
 * This data class tracks subscription operations (enabling/disabling notifications)
 * that have been initiated on a BLE device but have not yet received their completion
 * callback via onDescriptorWrite. Subscription operations involve writing to the
 * Client Characteristic Configuration Descriptor (CCCD) to enable or disable
 * notifications from the device.
 *
 * @property deviceAddress The MAC address of the Bluetooth device
 * @property characteristicUuid The UUID of the characteristic being subscribed to
 * @property enable Whether this is enabling (true) or disabling (false) notifications
 * @property result The MethodChannel.Result to complete when the subscription confirms,
 *                  which allows the Dart/Flutter await to properly wait for subscription completion
 */
data class PendingSubscription(
    val deviceAddress: String,
    val characteristicUuid: UUID,
    val enable: Boolean,
    val result: MethodChannel.Result
)

