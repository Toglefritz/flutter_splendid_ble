import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations returned by
/// `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's `localizationDelegates` list, and the
/// locales they support in the app's `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
/// localizationsDelegates: AppLocalizations.localizationsDelegates,
/// supportedLocales: AppLocalizations.supportedLocales,
/// home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following packages:
///
/// ```yaml
/// dependencies:
/// # Internationalization support.
/// flutter_localizations:
/// sdk: flutter
/// intl: any # Use the pinned version from flutter_localizations
///
/// # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported locales, in an Info.plist file that is built
/// into the application bundle. To configure the locales supported by your app, you’ll need to edit this file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file. Then, in the Project Navigator, open the
/// Info.plist file under the Runner project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the Editor menu, then select Localizations
/// from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each locale your application supports, add a new
/// item and select the locale you wish to add from the pop-up menu in the Value field. This list should be consistent
/// with the languages listed in the AppLocalizations.supportedLocales property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, and
  /// GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in MaterialApp. This list does not have to be used at
  /// all if a custom list of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// An address field label
  ///
  /// In en, this message translates to: **'Address'**
  String get address;

  /// A label for the form field for setting the Bluetooth scan reporting delay
  ///
  /// In en, this message translates to: **'Allow Duplicates'**
  String get allowDuplicates;

  /// A title for the flutter_ble plugin example app
  ///
  /// In en, this message translates to: **'Splendid BLE Example App'**
  String get appTitle;

  /// Balanced Bluetooth scanning mode
  ///
  /// In en, this message translates to: **'Balanced'**
  String get balanced;

  /// An error message indicating that the Bluetooth adapter is disabled
  ///
  /// In en, this message translates to: **'Bluetooth is disabled'**
  String get bluetoothDisabled;

  /// Title for the CharacteristicInteractionView
  ///
  /// In en, this message translates to: **'Characteristic Interaction'**
  String get characteristicInteraction;

  /// A label for the text field used to supply characteristic UUIDs
  ///
  /// In en, this message translates to: **'Characteristics'**
  String get characteristics;

  /// Instructions for the text field used to supply characteristic UUIDs
  ///
  /// In en, this message translates to: **'List of UUIDs'**
  String get characteristicsFieldLabel;

  /// Text for the button used to start the connection process
  ///
  /// In en, this message translates to: **'Connect'**
  String get connect;

  /// A label for the connection status row of the device details table
  ///
  /// In en, this message translates to: **'Connection Status'**
  String get connectionStatus;

  /// Used on a button for submitting a BLE peripheral server
  ///
  /// In en, this message translates to: **'Create'**
  String get create;

  /// Used on a button allowing the user to create an BLE server
  ///
  /// In en, this message translates to: **'Create\nserver'**
  String get createServer;

  /// Label used for the device address filter form field
  ///
  /// In en, this message translates to: **'Device address'**
  String get deviceAddress;

  /// Label used for the device name filter form field and for a server characteristic text field
  ///
  /// In en, this message translates to: **'Device name'**
  String get deviceName;

  /// The title of the Bluetooth scan list page
  ///
  /// In en, this message translates to: **'Discovered Devices'**
  String get discoveredDevices;

  /// Text for the button used to trigger the service discovery process
  ///
  /// In en, this message translates to: **'Discover Services'**
  String get discoverServices;

  /// A generic label for a CTA button
  ///
  /// In en, this message translates to: **'Done'**
  String get done;

  /// An error message indicating that a BLE write operation failed
  ///
  /// In en, this message translates to: **'Writing to the Bluetooth device failed'**
  String get errorWriting;

  /// Low latency Bluetooth scanning mode
  ///
  /// In en, this message translates to: **'Low Latency'**
  String get lowLatency;

  /// Low power Bluetooth scanning mode
  ///
  /// In en, this message translates to: **'Low Power'**
  String get lowPower;

  /// Label used for the device manufacturer data row of the device details table
  ///
  /// In en, this message translates to: **'Manufacturer Data'**
  String get manufacturerData;

  /// Label used for the device manufacturer ID filter form field
  ///
  /// In en, this message translates to: **'Manufacturer ID'**
  String get manufacturerId;

  /// A short warning that Bluetooth permissions have not been granted
  ///
  /// In en, this message translates to: **'Missing permissions'**
  String get missingPermissions;

  /// A name field label
  ///
  /// In en, this message translates to: **'Name'**
  String get name;

  /// An error message indicating that Bluetooth is not available on the host device
  ///
  /// In en, this message translates to: **'Bluetooth not available'**
  String get notAvailable;

  /// A message indicating that no BLE devices are currently connected
  ///
  /// In en, this message translates to: **'No connected devices'**
  String get noConnectedDevices;

  /// Its just the word "or" in English
  ///
  /// In en, this message translates to: **'or'**
  String get or;

  /// An error message to indicate that permissions have not been granted
  ///
  /// In en, this message translates to: **'The request for Bluetooth permissions was denied. Without those permissions,
  /// none of this will work.'**
  String get permissionsError;

  /// Instructions for the BLE peripheral name field
  ///
  /// In en, this message translates to: **'Peripheral name'**
  String get peripheralName;

  /// Field name for informational widgets and for a text field
  ///
  /// In en, this message translates to: **'Primary service'**
  String get primaryService;

  /// Instructions for the primary service UUID text field
  ///
  /// In en, this message translates to: **'UUID for primary service'**
  String get primaryServiceLabel;

  /// Title used for the Bluetooth scan filters form
  ///
  /// In en, this message translates to: **'Scan Filters'**
  String get scanFilters;

  /// Label used for the scan mode form field
  ///
  /// In en, this message translates to: **'Scan Mode'**
  String get scanMode;

  /// Title for the Bluetooth scan settings form
  ///
  /// In en, this message translates to: **'Scan Settings'**
  String get scanSettings;

  /// A label for the BLE peripheral server configuration page
  ///
  /// In en, this message translates to: **'Server configuration'**
  String get serverConfiguration;

  /// A label for the list of services presented for a Bluetooth device
  ///
  /// In en, this message translates to: **'Services'**
  String get services;

  /// A message indicating that service discovery has not yet been performed
  ///
  /// In en, this message translates to: **'Services not discovered'**
  String get servicesNotDiscovered;

  /// Label used for the scan service UUIDs form field
  ///
  /// In en, this message translates to: **'Service UUIDs (comma-separated)'**
  String get serviceUuids;

  /// A label for a menu item that will show connected BLE devices
  ///
  /// In en, this message translates to: **'Show connected devices'**
  String get showConnectedDevices;

  /// Used on a button allowing the user to start a Bluetooth scan
  ///
  /// In en, this message translates to: **'Start\nscan'**
  String get startScan;

  /// Label used for the report delay form field
  ///
  /// In en, this message translates to: **'Report Delay (milliseconds)'**
  String get reportDelay;

  /// An RSSI field label
  ///
  /// In en, this message translates to: **'RSSI'**
  String get rssi;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
