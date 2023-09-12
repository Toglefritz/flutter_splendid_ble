package com.splendidendeavors.flutter_ble.`interface`

import android.bluetooth.BluetoothGattCharacteristic
import com.splendidendeavors.flutter_ble.connector.BleConnectionHandler
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class BleDeviceInterface(
    private val channel: MethodChannel,
    private val bleConnectionHandler: BleConnectionHandler
) {
    /**
     * Write data to a specific BluetoothGattCharacteristic.
     *
     * @param characteristicUuid The UUID of the characteristic to be written.
     * @param value The data to be written to the characteristic.
     */
    fun writeCharacteristic(
        deviceAddress: String,
        characteristicUuid: UUID,
        value: ByteArray,
        writeType: Int = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
    ) {
        // Fetch the BluetoothGatt instance for the given device address.
        val gatt = bleConnectionHandler.getBluetoothGatt(deviceAddress)
        if (gatt == null) {
            channel.invokeMethod(
                "error",
                "No BluetoothGatt instance found for device address: $deviceAddress"
            )
            return
        }

        val service =
            gatt.services.find { it.characteristics.any { char -> char.uuid == characteristicUuid } }
        val characteristic = service?.getCharacteristic(characteristicUuid)

        if (characteristic != null) {
            try {
                if (android.os.Build.VERSION.SDK_INT >= 33) {
                    // New method introduced in API 33
                    gatt.writeCharacteristic(characteristic, value, writeType)
                } else {
                    // Old method for API levels below 33
                    gatt.writeCharacteristic(characteristic)
                }
            } catch (e: SecurityException) {
                channel.invokeMethod(
                    "error",
                    "Required Bluetooth permissions are missing: ${e.message}"
                )
            }
        }
    }

    // TODO add other methods for reading, subscribing, and doing some other stuff
}
