part of '../fl_mlkit_scanning.dart';

Size toSize(Map<dynamic, dynamic> data) {
  final double? width = data['width'] as double?;
  final double? height = data['height'] as double?;
  return Size(width ?? 0, height ?? 0);
}

List<Offset>? toCorners(List<dynamic>? data) => data != null
    ? List<Offset>.unmodifiable(data.map<dynamic>((dynamic e) {
        final double x = e['x'] as double? ?? 0;
        final double y = e['y'] as double? ?? 0;
        return Offset(x, y);
      }))
    : null;

BarcodeFormat toFormat(int? value) {
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
      return BarcodeFormat.code_bar;
    case 16:
      return BarcodeFormat.data_matrix;
    case 32:
      return BarcodeFormat.ean13;
    case 64:
      return BarcodeFormat.ean8;
    case 128:
      return BarcodeFormat.itf;
    case 256:
      return BarcodeFormat.qr_code;
    case 512:
      return BarcodeFormat.upc_a;
    case 1024:
      return BarcodeFormat.upc_e;
    case 2048:
      return BarcodeFormat.pdf417;
    case 4096:
      return BarcodeFormat.aztec;
    default:
      return BarcodeFormat.unknown;
  }
}

CalendarEvent? toCalendarEvent(Map<dynamic, dynamic>? data) =>
    data != null ? CalendarEvent.fromMap(data) : null;

DateTime? toDateTime(Map<dynamic, dynamic>? data) {
  if (data != null) {
    final int year = data['year'] as int? ?? 0;
    final int month = data['month'] as int? ?? 0;
    final int day = data['day'] as int? ?? 0;
    final int hour = data['hours'] as int? ?? 0;
    final int minute = data['minutes'] as int? ?? 0;
    final int second = data['seconds'] as int? ?? 0;
    final bool isUtc = data['isUtc'] as bool? ?? false;
    return isUtc
        ? DateTime.utc(year, month, day, hour, minute, second)
        : DateTime(year, month, day, hour, minute, second);
  } else {
    return null;
  }
}

ContactInfo? toContactInfo(Map<dynamic, dynamic>? data) =>
    data != null ? ContactInfo.fromMap(data) : null;

PersonName? toName(Map<dynamic, dynamic>? data) =>
    data != null ? PersonName.fromMap(data) : null;

DriverLicense? toDriverLicense(Map<dynamic, dynamic>? data) =>
    data != null ? DriverLicense.fromMap(data) : null;

Email? toEmail(Map<dynamic, dynamic>? data) =>
    data != null ? Email.fromMap(data) : null;

GeoPoint? toGeoPoint(Map<dynamic, dynamic>? data) =>
    data != null ? GeoPoint.fromMap(data) : null;

Phone? toPhone(Map<dynamic, dynamic>? data) =>
    data != null ? Phone.fromMap(data) : null;

SMS? toSMS(Map<dynamic, dynamic>? data) =>
    data != null ? SMS.fromMap(data) : null;

UrlBookmark? toUrl(Map<dynamic, dynamic>? data) =>
    data != null ? UrlBookmark.fromMap(data) : null;

WiFi? toWiFi(Map<dynamic, dynamic>? data) =>
    data != null ? WiFi.fromMap(data) : null;
