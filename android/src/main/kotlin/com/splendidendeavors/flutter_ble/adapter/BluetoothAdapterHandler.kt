import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import com.splendidendeavors.flutter_ble.adapter.BluetoothStatus

/**
 * The `BluetoothAdapterHandler` class is responsible for managing the Bluetooth adapter status
 * on an Android device. It offers a method to check the status of the Bluetooth adapter, including
 * whether it is supported on the device, and if supported, whether it is currently enabled or disabled.
 *
 * Here's an overview of the functionality:
 *
 * - `checkBluetoothAdapterStatus()`: This method returns a map containing the status and a descriptive
 *   message about the Bluetooth adapter on the device. It can indicate one of the following:
 *   1. "not_supported": Bluetooth is not supported on this device.
 *   2. "enabled": Bluetooth is enabled and ready to use.
 *   3. "disabled": Bluetooth is disabled on this device, and the user should enable it.
 *
 * This class can be utilized within a method channel in a Flutter plugin, allowing the Dart side to query
 * the status of the Bluetooth adapter before starting any Bluetooth-related workflows.
 *
 * Usage:
 * Initialize an instance of the class, passing the context, and then call `checkBluetoothAdapterStatus()`
 * to get the current status of the Bluetooth adapter.
 *
 * Example:
 * ```
 * val bluetoothAdapterHandler = BluetoothAdapterHandler(context)
 * val status = bluetoothAdapterHandler.checkBluetoothAdapterStatus()
 * ```
 */
class BluetoothAdapterHandler(private val context: Context) {
    private val bluetoothManager: BluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

    /**
     * Checks the status of the Bluetooth adapter on the device.
     *
     * This method retrieves the current state of the Bluetooth adapter using the BluetoothManager and returns
     * a value from the [BluetoothStatus] enumeration:
     *
     * - [BluetoothStatus.notAvailable]: Indicates that Bluetooth is not available on the device.
     * - [BluetoothStatus.enabled]: Indicates that Bluetooth is enabled and ready for connections.
     * - [BluetoothStatus.disabled]: Indicates that Bluetooth is disabled and not available for use.
     *
     * @return [BluetoothStatus] representing the current status of the Bluetooth adapter on the device.
     */
    fun checkBluetoothAdapterStatus(): BluetoothStatus {
        val bluetoothAdapter = bluetoothManager.getAdapter()
        return when {
            bluetoothAdapter == null -> BluetoothStatus.notAvailable
            bluetoothAdapter.isEnabled -> BluetoothStatus.enabled
            else -> BluetoothStatus.disabled
        }
    }
}
