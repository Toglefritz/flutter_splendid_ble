package com.splendidendeavors.flutter_splendid_ble.`interface`

import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * Represents a pending write operation that is waiting for confirmation.
 *
 * This data class tracks write operations that have been initiated on a BLE device
 * but have not yet received their completion callback. The BLE specification requires
 * that only one write operation can be in progress at a time per device.
 *
 * @property deviceAddress The MAC address of the Bluetooth device
 * @property characteristicUuid The UUID of the characteristic being written to
 * @property result The MethodChannel.Result to complete when the write finishes,
 *                  which allows the Dart/Flutter await to properly wait for write completion
 */
data class PendingWrite(
    val deviceAddress: String,
    val characteristicUuid: UUID,
    val result: MethodChannel.Result
)
