import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/services.dart';

class VisionText {
  final Map<dynamic, dynamic> _data;

  String get text => _data['text'];
  final Rect rect;
  final List<Point<num>> cornerPoints;

  VisionText._(this._data)
      : rect = Rect.fromLTRB(_data['rect_left'], _data['rect_top'],
            _data['rect_right'], _data['rect_bottom']),
        cornerPoints = _data['points'] == null
            ? null
            : _data['points']
                .map<Point<num>>(
                    (dynamic item) => Point<num>(item['x'], item['y']))
                .toList();
}

class VisionTextBlock extends VisionText {
  final List<VisionTextLine> lines;

  VisionTextBlock._(Map<dynamic, dynamic> data)
      : lines = data['lines'] == null
            ? null
            : data['lines']
                .map<VisionTextLine>((dynamic item) => VisionTextLine._(item))
                .toList(),
        super._(data);
}

class VisionTextLine extends VisionText {
  final List<VisionTextElement> elements;

  VisionTextLine._(Map<dynamic, dynamic> data)
      : elements = data['elements'] == null
            ? null
            : data['elements']
                .map<VisionTextElement>(
                    (dynamic item) => VisionTextElement._(item))
                .toList(),
        super._(data);
}

class VisionTextElement extends VisionText {
  VisionTextElement._(Map<dynamic, dynamic> data) : super._(data);
}

class FirebaseMlkit {
  static const MethodChannel _channel =
      const MethodChannel('plugins.flutter.io/mlkit');

  static FirebaseMlkit instance = new FirebaseMlkit._();

  FirebaseMlkit._() {}

  FirebaseVisionTextDetector getVisionTextDetector() {
    return FirebaseVisionTextDetector.instance;
  }
}

class FirebaseVisionTextDetector {
  static const MethodChannel _channel =
      const MethodChannel('plugins.flutter.io/mlkit');

  static FirebaseVisionTextDetector instance =
      new FirebaseVisionTextDetector._();

  FirebaseVisionTextDetector._() {}

  Future<List<VisionText>> detectFromPath(String filepath) async {
    List<dynamic> texts = await _channel.invokeMethod(
        "FirebaseVisionTextDetector#detectFromPath", {'filepath': filepath});
    List<VisionText> ret = [];
    texts.forEach((dynamic item) {
      final VisionTextBlock text = new VisionTextBlock._(item);
      ret.add(text);
    });
    return ret;
  }
}

class FirebaseVisionBarcodeDetector {
  static const MethodChannel _channel =
      const MethodChannel('plugins.flutter.io/mlkit');

  static FirebaseVisionBarcodeDetector instance =
      new FirebaseVisionBarcodeDetector._();

  FirebaseVisionBarcodeDetector._() {}

  Future<List<VisionBarcode>> detectFromPath(String filepath) async {
    try {
      List<dynamic> barcodes = await _channel.invokeMethod(
          "FirebaseVisionBarcodeDetector#detectFromPath",
          {'filepath': filepath});
      List<VisionBarcode> ret = [];
      barcodes.forEach((dynamic item) {
        print("item : ${item}");
        final VisionBarcode barcode = new VisionBarcode._(item);
        ret.add(barcode);
      });
      return ret;
    } catch (e) {
      print(
          "Error on FirebaseVisionBarcodeDetector#detectFromPath : ${e.toString()}");
    }
    return null;
  }
}

class FirebaseVisionLabelDetector {
  static const MethodChannel _channel =
      const MethodChannel('plugins.flutter.io/mlkit');

  static FirebaseVisionLabelDetector instance =
      new FirebaseVisionLabelDetector._();

  FirebaseVisionLabelDetector._() {}

  Future<List<VisionLabel>> detectFromPath(String filepath) async {
    try {
      List<dynamic> labels = await _channel.invokeMethod(
          "FirebaseVisionLabelDetector#detectFromPath",
          {'filepath': filepath});
      List<VisionLabel> ret = [];
      labels.forEach((dynamic item) {
        print("item : ${item}");
        final VisionLabel label = new VisionLabel._(item);
        ret.add(label);
      });
      return ret;
    } catch (e) {
      print(
          "Error on FirebaseVisionLabelDetector#detectFromPath : ${e.toString()}");
    }
    return null;
  }
}
// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcode
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode
class VisionBarcode {
  final Map<dynamic, dynamic> _data;

  final Rect rect;
  final String rawValue;
  final String displayValue;
  final VisionBarcodeFormat format;
  final List<Point<num>> cornerPoints;
  final VisionBarcodeValueType valueType;
  final VisionBarcodeEmail email;
  final VisionBarcodePhone phone;
  final VisionBarcodeSMS sms;
  final VisionBarcodeURLBookmark url;
  final VisionBarcodeWiFi wifi;
  final VisionBarcodeGeoPoint geoPoint;
  final VisionBarcodeContactInfo contactInfo;
  final VisionBarcodeCalendarEvent calendarEvent;
  final VisionBarcodeDriverLicense driverLicense;

  VisionBarcode._(this._data)
      : rect = Rect.fromLTRB(_data['rect_left'], _data['rect_top'],
            _data['rect_right'], _data['rect_bottom']),
        rawValue = _data['raw_value'] ?? null,
        displayValue = _data['display_value'] ?? null,
        format = VisionBarcodeFormat._(_data['format']),
        cornerPoints = _data['points'] == null
            ? null
            : _data['points']
                .map<Point<num>>(
                    (dynamic item) => Point<num>(item['x'], item['y']))
                .toList(),
        valueType =
            VisionBarcodeValueType.values.elementAt(_data['value_type']),
        email = _data['email'] == null
            ? null
            : VisionBarcodeEmail._(_data['email']),
        phone = _data['phone'] == null
            ? null
            : VisionBarcodePhone._(_data['phone']),
        sms = _data['sms'] == null ? null : VisionBarcodeSMS._(_data['sms']),
        url = _data['url'] == null
            ? null
            : VisionBarcodeURLBookmark._(_data['url']),
        wifi =
            _data['wifi'] == null ? null : VisionBarcodeWiFi._(_data['wifi']),
        geoPoint = _data['geo_point'] == null
            ? null
            : VisionBarcodeGeoPoint._(_data['geo_point']),
        contactInfo = _data['contact_info'] == null
            ? null
            : VisionBarcodeContactInfo._(_data['contact_info']),
        calendarEvent = _data['calendar_event'] == null
            ? null
            : VisionBarcodeCalendarEvent._(_data['calendar_event']),
        driverLicense = _data['driver_license'] == null
            ? null
            : VisionBarcodeDriverLicense._(_data['driver_license']);
}

// ios:
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Enums/FIRVisionBarcodeFormat
// android:
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.BarcodeFormat
class VisionBarcodeFormat {
  final int value;
  const VisionBarcodeFormat._(int value) : value = value;

  static const All = const VisionBarcodeFormat._(0xFFFF);
  static const UnKnown = const VisionBarcodeFormat._(0);
  static const Code128 = const VisionBarcodeFormat._(0x0001);
  static const Code39 = const VisionBarcodeFormat._(0x0002);
  static const Code93 = const VisionBarcodeFormat._(0x0004);
  static const CodaBar = const VisionBarcodeFormat._(0x0008);
  static const DataMatrix = const VisionBarcodeFormat._(0x0010);
  static const EAN13 = const VisionBarcodeFormat._(0x0020);
  static const EAN8 = const VisionBarcodeFormat._(0x0040);
  static const ITF = const VisionBarcodeFormat._(0x0080);
  static const QRCode = const VisionBarcodeFormat._(0x0100);
  static const UPCA = const VisionBarcodeFormat._(0x0200);
  static const UPCE = const VisionBarcodeFormat._(0x0400);
  static const PDF417 = const VisionBarcodeFormat._(0x0800);
  static const Aztec = const VisionBarcodeFormat._(0x1000);
}

enum VisionBarcodeValueType {
  /**
   * Unknown Barcode value types.
   */
  Unknown,
  /**
   * Barcode value type for contact info.
   */
  ContactInfo,
  /**
   * Barcode value type for email addresses.
   */
  Email,
  /**
   * Barcode value type for ISBNs.
   */
  ISBN,
  /**
   * Barcode value type for phone numbers.
   */
  Phone,
  /**
   * Barcode value type for product codes.
   */
  Product,
  /**
   * Barcode value type for SMS details.
   */
  SMS,
  /**
   * Barcode value type for plain text.
   */
  Text,
  /**
   * Barcode value type for URLs/bookmarks.
   */
  URL,
  /**
   * Barcode value type for Wi-Fi access point details.
   */
  WiFi,
  /**
   * Barcode value type for geographic coordinates.
   */
  GeographicCoordinates,
  /**
   * Barcode value type for calendar events.
   */
  CalendarEvent,
  /**
   * Barcode value type for driver's license data.
   */
  DriversLicense,
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcodeEmail
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.Email
class VisionBarcodeEmail {
  VisionBarcodeEmail._(Map<dynamic, dynamic> data)
      : type = VisionBarcodeEmailType.values.elementAt(data['type']),
        address = data['address'] ?? null,
        body = data['body'] ?? null,
        subject = data['subject'] ?? null;

  final String address;
  final String body;
  final String subject;
  final VisionBarcodeEmailType type;
}

enum VisionBarcodeEmailType {
  /**
   * Unknown email type.
   */
  Unknown,
  /**
   * Barcode work email type.
   */
  Work,
  /**
   * Barcode home email type.
   */
  Home,
}

class VisionBarcodePhone {
  final String number;
  final VisionBarcodePhoneType type;
  VisionBarcodePhone._(Map<dynamic, dynamic> data)
      : number = data['number'] ?? null,
        type = VisionBarcodePhoneType.values.elementAt(data['type']);
}

enum VisionBarcodePhoneType {
  /**
   * Unknown phone type.
   */
  Unknown,
  /**
   * Barcode work phone type.
   */
  Work,
  /**
   * Barcode home phone type.
   */
  Home,
  /**
   * Barcode fax phone type.
   */
  Fax,
  /**
   * Barcode mobile phone type.
   */
  Mobile,
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcodeURLBookmark
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.Sms
class VisionBarcodeSMS {
  VisionBarcodeSMS._(Map<dynamic, dynamic> data)
      : message = data['message'] ?? null,
        phoneNumber = data['phone_number'] ?? null;
  final String message;
  final String phoneNumber;
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcodeURLBookmark
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.UrlBookmark
class VisionBarcodeURLBookmark {
  VisionBarcodeURLBookmark._(Map<dynamic, dynamic> data)
      : title = data['title'] ?? null,
        url = data['url'] ?? null;
  final String title;
  final String url;
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcodeWiFi
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.WiFi
class VisionBarcodeWiFi {
  VisionBarcodeWiFi._(Map<dynamic, dynamic> data)
      : ssid = data['ssid'],
        password = data['password'],
        encryptionType = VisionBarcodeWiFiEncryptionType.values
            .elementAt(data['encryption_type']);

  final String ssid;
  final String password;
  final VisionBarcodeWiFiEncryptionType encryptionType;
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Enums/FIRVisionBarcodeWiFiEncryptionType
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.WiFi.EncryptionType
enum VisionBarcodeWiFiEncryptionType {
  /**
   * Barcode unknown Wi-Fi encryption type.
   */
  Unknown,
  /**
   * Barcode open Wi-Fi encryption type.
   */
  Open,
  /**
   * Barcode WPA Wi-Fi encryption type.
   */
  WPA,
  /**
   * Barcode WEP Wi-Fi encryption type.
   */
  WEP,
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcodeGeoPoint
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.GeoPoint
class VisionBarcodeGeoPoint {
  VisionBarcodeGeoPoint._(Map<dynamic, dynamic> data)
      : latitude = data['latitude'],
        longitude = data['longitude'];
  final double latitude;
  final double longitude;
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcodeContactInfo
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.ContactInfo
class VisionBarcodeContactInfo {
  VisionBarcodeContactInfo._(Map<dynamic, dynamic> data)
      : addresses = data['addresses'] == null
            ? null
            : data['addresses']
                .map<VisionBarcodeAddress>(
                    (dynamic item) => VisionBarcodeAddress._(item))
                .toList(),
        emails = data['emails'] == null
            ? null
            : data['emails']
                .map<VisionBarcodeEmail>(
                    (dynamic item) => VisionBarcodeEmail._(item))
                .toList(),
        name = data['name'] == null
            ? null
            : VisionBarcodePersonName._(data['name']),
        phones = data['phones'] == null
            ? null
            : data['phones']
                .map<VisionBarcodePhone>(
                    (dynamic item) => VisionBarcodePhone._(item))
                .toList(),
        urls = data['urls'] == null
            ? null
            : data['urls'].map<String>((dynamic item) => item).toList(),
        jobTitle = data['job_title'] ?? null,
        organization = data['organization'] ?? null;
  final List<VisionBarcodeAddress> addresses;
  final List<VisionBarcodeEmail> emails;
  final VisionBarcodePersonName name;
  final List<VisionBarcodePhone> phones;
  final List<String> urls;
  final String jobTitle;
  final String organization;
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcodeAddress
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.Address
class VisionBarcodeAddress {
  VisionBarcodeAddress._(Map<dynamic, dynamic> data)
      : addressLines =
            data['address_lines'].map<String>((dynamic item) => item).toList(),
        type = VisionBarcodeAddressType.values.elementAt(data['type']);
  final List<String> addressLines;
  final VisionBarcodeAddressType type;
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Enums/FIRVisionBarcodeAddressType
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.Address.AddressType
enum VisionBarcodeAddressType {
  /**
   * Barcode unknown address type.
   */
  Unknown,
  /**
   * Barcode work address type.
   */
  Work,
  /**
   * Barcode home address type.
   */
  Home,
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcodePersonName
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.PersonName
class VisionBarcodePersonName {
  VisionBarcodePersonName._(Map<dynamic, dynamic> data)
      : formattedName = data['formatted_name'] ?? null,
        first = data['first'] ?? null,
        last = data['last'] ?? null,
        middle = data['middle'] ?? null,
        prefix = data['prefix'] ?? null,
        pronounciation = data['pronounciation'] ?? null,
        suffix = data['suffix'] ?? null;
  final String formattedName;
  final String first;
  final String last;
  final String middle;
  final String prefix;
  final String pronounciation;
  final String suffix;
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcodeCalendarEvent
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.CalendarEvent
class VisionBarcodeCalendarEvent {
  VisionBarcodeCalendarEvent._(Map<dynamic, dynamic> data)
      : eventDescription = data['event_description'] ?? null,
        location = data['location'] ?? null,
        organizer = data['organizer'] ?? null,
        status = data['status'] ?? null,
        summary = data['summary'] ?? null,
        start = data['start'] ?? null,
        end = data['end'] ?? null;
  final String eventDescription;
  final String location;
  final String organizer;
  final String status;
  final String summary;
  final DateTime start;
  final DateTime end;
}

// ios
//   https://firebase.google.com/docs/reference/ios/firebasemlvision/api/reference/Classes/FIRVisionBarcodeDriverLicense
// android
//   https://firebase.google.com/docs/reference/android/com/google/firebase/ml/vision/barcode/FirebaseVisionBarcode.DriverLicense
class VisionBarcodeDriverLicense {
  VisionBarcodeDriverLicense._(Map<dynamic, dynamic> data)
      : firstName = data['first_name'] ?? null,
        middleName = data['middle_name'] ?? null,
        lastName = data['last_name'] ?? null,
        gender = data['gender'] ?? null,
        addressCity = data['address_city'] ?? null,
        addressState = data['address_state'] ?? null,
        addressZip = data['address_zip'] ?? null,
        birthDate = data['birth_date'] ?? null,
        documentType = data['document_type'] ?? null,
        licenseNumber = data['license_number'] ?? null,
        expiryDate = data['expiry_date'] ?? null,
        issuingDate = data['issuing_date'] ?? null,
        issuingCountry = data['issuing_country'] ?? null;
  final String firstName;
  final String middleName;
  final String lastName;
  final String gender;
  final String addressCity;
  final String addressState;
  final String addressZip;
  final String birthDate;
  final String documentType;
  final String licenseNumber;
  final String expiryDate;
  final String issuingDate;
  final String issuingCountry;
}

// ios
// https://firebase.google.com/docs/reference/swift/firebasemlvision/api/reference/Classes/VisionLabel
class VisionLabel{
  final Map<dynamic,dynamic> _data;
  final Rect rect;
  final String entityID;
  final double confidence;
  final String label;

  VisionLabel._(this._data) 
      : rect = Rect.fromLTRB(_data['rect_left'] ?? 0.0, _data['rect_top'] ?? 0.0,
            _data['rect_right'] ?? 0.0, _data['rect_bottom'] ?? 0.0),
        entityID = _data['entityID'],
        confidence = _data['confidence'],
        label = _data['label'];
}
