package com.splendidendeavors.flutter_splendid_ble.permissions

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Handles Bluetooth permission requests and status reporting for different Android versions.
 *
 * This class manages the complexity of Bluetooth permissions across Android versions:
 * - Android 12+ (API 31+): Requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT permissions
 * - Android 10-11 (API 29-30): Requires ACCESS_FINE_LOCATION permission
 * - Android 6-9 (API 23-28): Requires ACCESS_COARSE_LOCATION or ACCESS_FINE_LOCATION
 */
class BluetoothPermissionsHandler(
    private val channel: MethodChannel,
    private val context: Context
) : PluginRegistry.RequestPermissionsResultListener {

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
        
        // Permission status strings that match the Dart enum
        private const val STATUS_GRANTED = "granted"
        private const val STATUS_DENIED = "denied"
    }

    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null

    /**
     * Sets the activity reference needed for requesting permissions.
     */
    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    /**
     * Requests Bluetooth permissions appropriate for the current Android version.
     *
     * @param result The MethodChannel.Result to return the permission status
     */
    fun requestBluetoothPermissions(result: MethodChannel.Result) {
        val requiredPermissions = getRequiredPermissions()
        
        // Check if all required permissions are already granted
        if (arePermissionsGranted(requiredPermissions)) {
            result.success(STATUS_GRANTED)
            return
        }

        // Check if we have an activity to request permissions
        if (activity == null) {
            result.error(
                "NO_ACTIVITY",
                "Cannot request permissions without an activity context",
                null
            )
            return
        }

        // Store the result to respond after permission request completes
        pendingResult = result

        // Request the permissions
        ActivityCompat.requestPermissions(
            activity!!,
            requiredPermissions,
            PERMISSION_REQUEST_CODE
        )
    }

    /**
     * Emits the current Bluetooth permission status to the Dart side.
     * 
     * This method immediately checks the current permission status and emits it
     * via the method channel. Listeners on the Dart side should be set up before
     * calling this method to ensure they receive the initial status emission.
     */
    fun emitCurrentPermissionStatus() {
        val status = getCurrentPermissionStatus()
        channel.invokeMethod("permissionStatusUpdated", status)
    }

    /**
     * Gets the current permission status without requesting permissions.
     *
     * @return The current permission status as a string ("granted" or "denied")
     */
    private fun getCurrentPermissionStatus(): String {
        val requiredPermissions = getRequiredPermissions()
        return if (arePermissionsGranted(requiredPermissions)) {
            STATUS_GRANTED
        } else {
            STATUS_DENIED
        }
    }

    /**
     * Returns the list of permissions required for the current Android version.
     */
    private fun getRequiredPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ (API 31+)
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10-11 (API 29-30)
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        } else {
            // Android 6-9 (API 23-28)
            // ACCESS_COARSE_LOCATION is sufficient for BLE scanning on older versions
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }

    /**
     * Checks if all specified permissions are granted.
     *
     * @param permissions Array of permission strings to check
     * @return true if all permissions are granted, false otherwise
     */
    private fun arePermissionsGranted(permissions: Array<String>): Boolean {
        return permissions.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == 
                PackageManager.PERMISSION_GRANTED
        }
    }

    /**
     * Handles the result of a permission request.
     *
     * This method is called by the Flutter plugin when permission results are received.
     */
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) {
            return false
        }

        val result = pendingResult ?: return false
        pendingResult = null

        // Check if all permissions were granted
        val allGranted = grantResults.isNotEmpty() && 
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }

        val status = if (allGranted) STATUS_GRANTED else STATUS_DENIED
        result.success(status)

        // Emit the updated permission status
        emitCurrentPermissionStatus()

        return true
    }
}
