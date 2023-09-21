package com.splendidendeavors.flutter_ble.`interface`

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import com.splendidendeavors.flutter_ble.connector.BleConnectionHandler
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * Provides an interface for interacting with a connected Bluetooth Low Energy (BLE) peripheral device.
 *
 * This class encapsulates operations for reading from and writing to BluetoothGattCharacteristics and
 * manages GATT callbacks for these operations. It utilizes a MethodChannel for communication between
 * Flutter and native Android code and employs an instance of BleConnectionHandler to maintain a map
 * of device addresses to their respective BluetoothGatt instances.
 *
 * The class gracefully handles error scenarios by invoking specific methods via the MethodChannel,
 * thereby allowing the Flutter application to handle these errors. Future versions may include additional
 * features such as subscribing to characteristics, batch reading, and writing descriptors.
 *
 * @property channel The MethodChannel through which Flutter and native Android code communicate.
 * @property bleConnectionHandler An instance of BleConnectionHandler that maintains a mapping of device
 *                                addresses to corresponding BluetoothGatt instances.
 */
class BleDeviceInterface(
    private val channel: MethodChannel,
    private val bleConnectionHandler: BleConnectionHandler
) : BluetoothGattCallback() {
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

    /**
     * Read the value of a specific BluetoothGattCharacteristic.
     *
     * @param deviceAddress The address of the device containing the characteristic.
     * @param characteristicUuid The UUID of the characteristic to be read.
     * @return The data read from the characteristic as a list of integers.
     */
    fun readCharacteristic(deviceAddress: String, characteristicUuid: UUID) {
        val gatt = bleConnectionHandler.getBluetoothGatt(deviceAddress)
        if (gatt == null) {
            channel.invokeMethod(
                "error",
                "No BluetoothGatt instance found for device address: $deviceAddress"
            )
        }

        val service =
            gatt?.services?.find { it.characteristics.any { char -> char.uuid == characteristicUuid } }
        val characteristic = service?.getCharacteristic(characteristicUuid)

        if (characteristic != null) {
            try {
                gatt.readCharacteristic(characteristic)
            } catch (e: SecurityException) {
                channel.invokeMethod(
                    "error",
                    "Required Bluetooth permissions are missing: ${e.message}"
                )
            }
        } else {
            channel.invokeMethod(
                "error",
                "Characteristic with UUID $characteristicUuid not found."
            )
        }
    }

    /**
     * Callback triggered as a result of a characteristic read operation.
     *
     * @param gatt GATT client invoked readCharacteristic
     * @param characteristic Characteristic that was read from the associated remote device.
     * @param status GATT operation status.
     */
    override fun onCharacteristicRead(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        value: ByteArray,
        status: Int
    ) {
        super.onCharacteristicRead(gatt, characteristic, value, status)

        if (status == BluetoothGatt.GATT_SUCCESS) {
            val valueList = value.map { byte -> byte.toInt() }
            channel.invokeMethod(
                "onCharacteristicRead", mapOf(
                    "deviceAddress" to gatt.device?.address,
                    "characteristicUuid" to characteristic.uuid.toString(),
                    "value" to valueList
                )
            )
        } else {
            channel.invokeMethod(
                "error",
                "Failed to read characteristic with UUID ${characteristic.uuid}"
            )
        }
    }

    // TODO add other methods for reading, subscribing, and doing some other stuff
}
