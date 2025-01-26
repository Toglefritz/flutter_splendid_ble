# Method: `_requestAndroidPermissions`

## Description

Requests Bluetooth and location permissions.

 The user will be prompted to allow the app to use various Bluetooth features of their mobile device. These
 permissions must be granted for the app to function since its whole deal is doing Bluetooth stuff. The app
 will also request location permissions, which are necessary for performing a Bluetooth scan.

## Return Type
`Future<void>`

