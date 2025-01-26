# Method: `onEntrySubmitted`

## Description

Handles submission of entries into the text field used to input values to be sent to the Bluetooth peripheral.

 First, this method will attempt to write the string provided in the [TextField] to the Bluetooth characteristic
 provided to this route. If that write fails, a [SnackBar] will be displayed alerting the user of the failure. If
 it is successful, the message will be added to [messages] so that it will be displayed in the list, and the
 [TextField] will be cleared.

## Return Type
`Future<void>`

