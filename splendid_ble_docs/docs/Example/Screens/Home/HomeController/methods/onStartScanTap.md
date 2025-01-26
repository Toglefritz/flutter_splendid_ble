# Method: `onStartScanTap`

## Description

Handles taps on the "start scan" button.

 If Bluetooth scanning permissions have been granted or if the app is running on an iOS device (in which case
 the boolean indicating if permissions have been granted is true by default), navigate to the [ScanRoute].
 Otherwise, show a [SnackBar] to indicate that permissions have not been granted yet.

## Return Type
`void`

