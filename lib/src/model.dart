part of '../fl_mlkit_scanning.dart';

class AnalysisImageModel {
  AnalysisImageModel.fromMap(Map<dynamic, dynamic> data)
      : barcodes = _getBarcodeList(data['barcodes'] as List<dynamic>?),
        height = data['height'] as double?,
        width = data['width'] as double?;

  /// The coordinate points of [corners] and the boundary line of [boundingbox] are
  /// based on width and height
  /// If you need to display the bar code rectangle and coordinate points,
  /// you must calculate it yourself and determine whether it is a full screen preview

  /// The height of the image from which the barcode is currently parsed
  /// The position of the barcode is converted to the screen by high
  double? height;

  /// The width of the image from which the barcode is currently parsed
  /// The position of the barcode is converted to the screen by width
  double? width;

  /// Barcode in image
  List<Barcode>? barcodes;
}

/// Represents a single recognized barcode and its value.
class Barcode {
  /// Create a [Barcode] from native data.
  Barcode.fromMap(Map<dynamic, dynamic> data)
      : corners = _getCorners(data['corners'] as List<dynamic>?),
        format = _getFormat(data['format'] as int?),
        bytes = data['bytes'] as Uint8List?,
        value = data['value'] as String?,
        displayValue = data['displayValue'] as String?,
        boundingBox = _getRect(data['boundingBox'] as Map<dynamic, dynamic>?),
        type = data['type'] != null
            ? BarcodeType.values[data['type'] as int]
            : null,
        calendarEvent =
            _getCalendarEvent(data['calendarEvent'] as Map<dynamic, dynamic>?),
        contactInfo =
            _getContactInfo(data['contactInfo'] as Map<dynamic, dynamic>?),
        driverLicense =
            _getDriverLicense(data['driverLicense'] as Map<dynamic, dynamic>?),
        email = _getEmail(data['email'] as Map<dynamic, dynamic>?),
        geoPoint = _getGeoPoint(data['geoPoint'] as Map<dynamic, dynamic>?),
        phone = _getPhone(data['phone'] as Map<dynamic, dynamic>?),
        sms = _getSMS(data['sms'] as Map<dynamic, dynamic>?),
        url = _getUrl(data['url'] as Map<dynamic, dynamic>?),
        wifi = _getWiFi(data['wifi'] as Map<dynamic, dynamic>?);

  /// Returns four corner points in clockwise direction starting with top-left.
  ///
  /// Due to the possible perspective distortions, this is not necessarily a rectangle.
  ///
  /// Returns null if the corner points can not be determined.
  final List<Offset>? corners;

  /// Returns barcode format
  final BarcodeFormat? format;

  /// Gets the bounding rectangle of the detected barcode.
  ///
  /// Returns null if the bounding rectangle can not be determined.
  final Rect? boundingBox;

  /// Returns raw bytes as it was encoded in the barcode.
  ///
  /// Returns null if the raw bytes can not be determined.
  final Uint8List? bytes;

  /// Returns barcode value as it was encoded in the barcode. Structured values are not parsed, for example: 'MEBKM:TITLE:Google;URL://www.google.com;;'.
  ///
  /// It's only available when the barcode is encoded in the UTF-8 format, and for non-UTF8 ones use [bytes] instead.
  ///
  /// Returns null if the raw value can not be determined.
  final String? value;

  /// Returns barcode value in a user-friendly format.
  /// This method may omit some of the information encoded in the barcode. For example, if getRawValue() returns 'MEBKM:TITLE:Google;URL://www.google.com;;', the display value might be '//www.google.com'.
  /// This value may be multiline, for example, when line breaks are encoded
  /// into the original TEXT barcode value. May include the supplement value.
  ///  Returns null if nothing found.
  final String? displayValue;

  /// Returns format type of the barcode value.
  ///
  /// For example, TYPE_TEXT, TYPE_PRODUCT, TYPE_URL, etc.
  ///
  /// If the value structure cannot be parsed, TYPE_TEXT will be returned. If the recognized structure type is not defined in your current version of SDK, TYPE_UNKNOWN will be returned.
  ///
  /// Note that the built-in parsers only recognize a few popular value structures. For your specific use case, you might want to directly consume value and implement your own parsing logic.
  final BarcodeType? type;

  /// Gets parsed calendar event details.
  final CalendarEvent? calendarEvent;

  /// Gets parsed contact details.
  final ContactInfo? contactInfo;

  /// Gets parsed driver license details.
  final DriverLicense? driverLicense;

  /// Gets parsed email details.
  final Email? email;

  /// Gets parsed geo coordinates.
  final GeoPoint? geoPoint;

  /// Gets parsed phone number details.
  final Phone? phone;

  /// Gets parsed SMS details.
  final SMS? sms;

  /// Gets parsed URL bookmark details.
  final UrlBookmark? url;

  /// Gets parsed WiFi AP details.
  final WiFi? wifi;
}

/// A calendar event extracted from QRCode.
class CalendarEvent {
  /// Create a [CalendarEvent] from native data.
  CalendarEvent.fromMap(Map<dynamic, dynamic> data)
      : description = data['description'] as String?,
        start = DateTime.tryParse(data['start'] as String? ?? ''),
        end = DateTime.tryParse(data['end'] as String? ?? ''),
        location = data['location'] as String?,
        organizer = data['organizer'] as String?,
        status = data['status'] as String?,
        summary = data['summary'] as String?;

  /// Gets the description of the calendar event.
  ///
  /// Returns null if not available.
  final String? description;

  /// Gets the start date time of the calendar event.
  ///
  /// Returns null if not available.
  final DateTime? start;

  /// Gets the end date time of the calendar event.
  ///
  /// Returns null if not available.
  final DateTime? end;

  /// Gets the location of the calendar event.
  ///
  /// Returns null if not available.
  final String? location;

  /// Gets the organizer of the calendar event.
  ///
  /// Returns null if not available.
  final String? organizer;

  /// Gets the status of the calendar event.
  ///
  /// Returns null if not available.
  final String? status;

  /// Gets the summary of the calendar event.
  ///
  /// Returns null if not available.
  final String? summary;
}

/// A person's or organization's business card. For example a VCARD.
class ContactInfo {
  /// Create a [ContactInfo] from native data.
  ContactInfo.fromMap(Map<dynamic, dynamic> data)
      : addresses = data['addresses'] != null
            ? List<Address>.unmodifiable((data['addresses'] as List<dynamic>)
                .map<dynamic>(
                    (dynamic e) => Address.fromMap(e as Map<dynamic, dynamic>)))
            : null,
        emails = data['emails'] != null
            ? List<Email>.unmodifiable((data['emails'] as List<dynamic>)
                .map<dynamic>(
                    (dynamic e) => Email.fromMap(e as Map<dynamic, dynamic>)))
            : null,
        name = _getName(data['name'] as Map<dynamic, dynamic>?),
        organization = data['organization'] as String?,
        phones = List<Phone>.unmodifiable((data['phones'] as List<dynamic>)
            .map<dynamic>(
                (dynamic e) => Phone.fromMap(e as Map<dynamic, dynamic>))),
        title = data['title'] as String?,
        urls = List<String>.unmodifiable(data['urls'] as List<dynamic>);

  /// Gets contact person's addresses.
  ///
  /// Returns an empty list if nothing found.
  final List<Address>? addresses;

  /// Gets contact person's emails.
  ///
  /// Returns an empty list if nothing found.
  final List<Email>? emails;

  /// Gets contact person's name.
  ///
  /// Returns null if not available.
  final PersonName? name;

  /// Gets contact person's organization.
  ///
  /// Returns null if not available.
  final String? organization;

  /// Gets contact person's phones.
  ///
  /// Returns an empty list if nothing found.
  final List<Phone>? phones;

  /// Gets contact person's title.
  ///
  /// Returns null if not available.
  final String? title;

  /// Gets contact person's urls.
  ///
  /// Returns an empty list if nothing found.
  final List<String>? urls;
}

/// An address.
class Address {
  /// Create a [Address] from native data.
  Address.fromMap(Map<dynamic, dynamic> data)
      : addressLines =
            List<String>.unmodifiable(data['addressLines'] as List<dynamic>),
        type = data['type'] != null
            ? AddressType.values[data['type'] as int]
            : null;

  /// Gets formatted address, multiple lines when appropriate. This field always contains at least one line.
  final List<String>? addressLines;

  /// Gets type of the address.
  final AddressType? type;
}

/// A person's name, both formatted version and individual name components.
class PersonName {
  /// Create a [PersonName] from native data.
  PersonName.fromMap(Map<dynamic, dynamic> data)
      : first = data['first'] as String?,
        middle = data['middle'] as String?,
        last = data['last'] as String?,
        prefix = data['prefix'] as String?,
        suffix = data['suffix'] as String?,
        formattedName = data['formattedName'] as String?,
        pronunciation = data['pronunciation'] as String?;

  /// Gets first name.
  ///
  /// Returns null if not available.
  final String? first;

  /// Gets middle name.
  ///
  /// Returns null if not available.
  final String? middle;

  /// Gets last name.
  ///
  /// Returns null if not available.
  final String? last;

  /// Gets prefix of the name.
  ///
  /// Returns null if not available.
  final String? prefix;

  /// Gets suffix of the person's name.
  ///
  /// Returns null if not available.
  final String? suffix;

  /// Gets the properly formatted name.
  ///
  /// Returns null if not available.
  final String? formattedName;

  /// Designates a text string to be set as the kana name in the phonebook. Used for Japanese contacts.
  ///
  /// Returns null if not available.
  final String? pronunciation;
}

/// A driver license or ID card.
class DriverLicense {
  /// Create a [DriverLicense] from native data.
  DriverLicense.fromMap(Map<dynamic, dynamic> data)
      : addressCity = data['addressCity'] as String?,
        addressState = data['addressState'] as String?,
        addressStreet = data['addressStreet'] as String?,
        addressZip = data['addressZip'] as String?,
        birthDate = data['birthDate'] as String?,
        documentType = data['documentType'] as String?,
        expiryDate = data['expiryDate'] as String?,
        firstName = data['firstName'] as String?,
        gender = data['gender'] as String?,
        issueDate = data['issueDate'] as String?,
        issuingCountry = data['issuingCountry'] as String?,
        lastName = data['lastName'] as String?,
        licenseNumber = data['licenseNumber'] as String?,
        middleName = data['middleName'] as String?;

  /// Gets city of holder's address.
  ///
  /// Returns null if not available.
  final String? addressCity;

  /// Gets state of holder's address.
  ///
  /// Returns null if not available.
  final String? addressState;

  /// Gets holder's street address.
  ///
  /// Returns null if not available.
  final String? addressStreet;

  /// Gets postal code of holder's address.
  ///
  /// Returns null if not available.
  final String? addressZip;

  /// Gets birth date of the holder.
  ///
  /// Returns null if not available.
  final String? birthDate;

  /// Gets "DL" for driver licenses, "ID" for ID cards.
  ///
  /// Returns null if not available.
  final String? documentType;

  /// Gets expiry date of the license.
  ///
  /// Returns null if not available.
  final String? expiryDate;

  /// Gets holder's first name.
  ///
  /// Returns null if not available.
  final String? firstName;

  /// Gets holder's gender. 1 - male, 2 - female.
  ///
  /// Returns null if not available.
  final String? gender;

  /// Gets issue date of the license.
  ///
  /// The date format depends on the issuing country. MMDDYYYY for the US, YYYYMMDD for Canada.
  ///
  /// Returns null if not available.
  final String? issueDate;

  /// Gets the three-letter country code in which DL/ID was issued.
  ///
  /// Returns null if not available.
  final String? issuingCountry;

  /// Gets holder's last name.
  ///
  /// Returns null if not available.
  final String? lastName;

  /// Gets driver license ID number.
  ///
  /// Returns null if not available.
  final String? licenseNumber;

  /// Gets holder's middle name.
  ///
  /// Returns null if not available.
  final String? middleName;
}

/// An email message from a 'MAILTO:' or similar QRCode type.
class Email {
  /// Create a [Email] from native data.
  Email.fromMap(Map<dynamic, dynamic> data)
      : address = data['address'] as String?,
        body = data['body'] as String?,
        subject = data['subject'] as String?,
        type =
            data['type'] != null ? EmailType.values[data['type'] as int] : null;

  /// Gets email's address.
  ///
  /// Returns null if not available.
  final String? address;

  /// Gets email's body.
  ///
  /// Returns null if not available.
  final String? body;

  /// Gets email's subject.
  ///
  /// Returns null if not available.
  final String? subject;

  /// Gets type of the email.
  ///
  /// See also [EmailType].
  final EmailType? type;
}

/// GPS coordinates from a 'GEO:' or similar QRCode type.
class GeoPoint {
  /// Create a [GeoPoint] from native data.
  GeoPoint.fromMap(Map<dynamic, dynamic> data)
      : latitude = data['latitude'] as double?,
        longitude = data['longitude'] as double?;

  /// Gets the latitude.
  final double? latitude;

  /// Gets the longitude.
  final double? longitude;
}

/// Phone number info.
class Phone {
  /// Create a [Phone] from native data.
  Phone.fromMap(Map<dynamic, dynamic> data)
      : number = data['number'] as String?,
        type =
            data['type'] != null ? PhoneType.values[data['type'] as int] : null;

  /// Gets phone number.
  ///
  /// Returns null if not available.
  final String? number;

  /// Gets type of the phone number.
  ///
  /// See also [PhoneType].
  final PhoneType? type;
}

/// A sms message from a 'SMS:' or similar QRCode type.
class SMS {
  /// Create a [SMS] from native data.
  SMS.fromMap(Map<dynamic, dynamic> data)
      : message = data['message'] as String?,
        phoneNumber = data['phoneNumber'] as String?;

  /// Gets the message content of the sms.
  ///
  /// Returns null if not available.
  final String? message;

  /// Gets the phone number of the sms.
  ///
  /// Returns null if not available.
  final String? phoneNumber;
}

/// A URL and title from a 'MEBKM:' or similar QRCode type.
class UrlBookmark {
  /// Create a [UrlBookmark] from native data.
  UrlBookmark.fromMap(Map<dynamic, dynamic> data)
      : title = data['title'] as String?,
        url = data['url'] as String?;

  /// Gets the title of the bookmark.
  ///
  /// Returns null if not available.
  final String? title;

  /// Gets the url of the bookmark.
  ///
  /// Returns null if not available.
  final String? url;
}

/// A wifi network parameters from a 'WIFI:' or similar QRCode type.
class WiFi {
  /// Create a [WiFi] from native data.
  WiFi.fromMap(Map<dynamic, dynamic> data)
      : encryptionType =
            EncryptionType.values[data['encryptionType'] as int? ?? 0],
        ssid = data['ssid'] as String?,
        password = data['password'] as String?;

  /// Gets the encryption type of the WIFI.
  ///
  /// See all [EncryptionType].
  final EncryptionType? encryptionType;

  /// Gets the ssid of the WIFI.
  ///
  /// Returns null if not available.
  final String? ssid;

  /// Gets the password of the WIFI.
  ///
  /// Returns null if not available.
  final String? password;
}

Rect? _getRect(Map<dynamic, dynamic>? data) {
  if (data == null) {
    return null;
  } else {
    if (_isAndroid) {
      final int left = (data['left'] as int?) ?? 0;
      final int top = (data['top'] as int?) ?? 0;
      final int right = (data['right'] as int?) ?? 0;
      final int bottom = (data['bottom'] as int?) ?? 0;
      return Rect.fromLTRB(
          left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
    } else if (_isIOS) {
      final double x = (data['x'] as double?) ?? 0;
      final double y = (data['y'] as double?) ?? 0;
      final double width = (data['width'] as double?) ?? 0;
      final double height = (data['height'] as double?) ?? 0;
      return Rect.fromPoints(Offset(x, y), Offset(x + width, y + height));
    }
  }
}

List<Barcode>? _getBarcodeList(List<dynamic>? data) => data
    ?.map((dynamic item) => Barcode.fromMap(item as Map<dynamic, dynamic>))
    .toList();

List<Offset>? _getCorners(List<dynamic>? data) => data != null
    ? List<Offset>.unmodifiable(data.map<dynamic>(
        (dynamic e) => Offset(e['x'] as double? ?? 0, e['y'] as double? ?? 0)))
    : null;

BarcodeFormat _getFormat(int? value) {
  switch (value) {
    case 0:
      return BarcodeFormat.all;
    case 1:
      return BarcodeFormat.code128;
    case 2:
      return BarcodeFormat.code39;
    case 4:
      return BarcodeFormat.code93;
    case 8:
      return BarcodeFormat.codeBar;
    case 16:
      return BarcodeFormat.dataMatrix;
    case 32:
      return BarcodeFormat.ean13;
    case 64:
      return BarcodeFormat.ean8;
    case 128:
      return BarcodeFormat.itf;
    case 256:
      return BarcodeFormat.qrCode;
    case 512:
      return BarcodeFormat.upcA;
    case 1024:
      return BarcodeFormat.upcE;
    case 2048:
      return BarcodeFormat.pdf417;
    case 4096:
      return BarcodeFormat.aztec;
    default:
      return BarcodeFormat.unknown;
  }
}

CalendarEvent? _getCalendarEvent(Map<dynamic, dynamic>? data) =>
    data != null ? CalendarEvent.fromMap(data) : null;

// DateTime? _getDateTime(Map<dynamic, dynamic>? data) {
//   if (data != null) {
//     final int year = data['year'] as int? ?? 0;
//     final int month = data['month'] as int? ?? 0;
//     final int day = data['day'] as int? ?? 0;
//     final int hour = data['hours'] as int? ?? 0;
//     final int minute = data['minutes'] as int? ?? 0;
//     final int second = data['seconds'] as int? ?? 0;
//     final bool isUtc = data['isUtc'] as bool? ?? false;
//     return isUtc
//         ? DateTime.utc(year, month, day, hour, minute, second)
//         : DateTime(year, month, day, hour, minute, second);
//   } else {
//     return null;
//   }
// }

ContactInfo? _getContactInfo(Map<dynamic, dynamic>? data) =>
    data != null ? ContactInfo.fromMap(data) : null;

PersonName? _getName(Map<dynamic, dynamic>? data) =>
    data != null ? PersonName.fromMap(data) : null;

DriverLicense? _getDriverLicense(Map<dynamic, dynamic>? data) =>
    data != null ? DriverLicense.fromMap(data) : null;

Email? _getEmail(Map<dynamic, dynamic>? data) =>
    data != null ? Email.fromMap(data) : null;

GeoPoint? _getGeoPoint(Map<dynamic, dynamic>? data) =>
    data != null ? GeoPoint.fromMap(data) : null;

Phone? _getPhone(Map<dynamic, dynamic>? data) =>
    data != null ? Phone.fromMap(data) : null;

SMS? _getSMS(Map<dynamic, dynamic>? data) =>
    data != null ? SMS.fromMap(data) : null;

UrlBookmark? _getUrl(Map<dynamic, dynamic>? data) =>
    data != null ? UrlBookmark.fromMap(data) : null;

WiFi? _getWiFi(Map<dynamic, dynamic>? data) =>
    data != null ? WiFi.fromMap(data) : null;
