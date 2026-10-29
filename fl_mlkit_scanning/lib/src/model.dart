part of '../fl_mlkit_scanning.dart';

/// 一次扫码的结果。
///
/// [width] / [height] 为识别原图的宽高（单位像素），
/// [barcodes] 中所有坐标都是基于该尺寸的坐标系。
/// 如果需要把条码位置绘制到屏幕上，请自行按照预览的缩放与裁剪方式换算。
class AnalysisImageModel {
  /// 从原生返回的 Map 创建结果。
  AnalysisImageModel.fromMap(Map<dynamic, dynamic> data)
    : barcodes = _getBarcodeList(data['barcodes'] as List<dynamic>?),
      height = (data['height'] as num?)?.toDouble(),
      width = (data['width'] as num?)?.toDouble();

  /// 识别原图的宽度（像素）。
  final double? width;

  /// 识别原图的高度（像素）。
  final double? height;

  /// 图片中识别到的条码列表。
  final List<Barcode>? barcodes;

  /// 条码列表，空值安全版本。
  List<Barcode> get barcodeList => barcodes ?? const <Barcode>[];

  /// 是否没有识别到任何条码。
  bool get isEmpty => barcodeList.isEmpty;

  @override
  String toString() => 'AnalysisImageModel(width: $width, height: $height, barcodes: $barcodes)';
}

/// 单个条码及其解析结果。
class Barcode {
  /// 从原生返回的 Map 创建条码数据。
  Barcode.fromMap(Map<dynamic, dynamic> data)
    : corners = _getCorners(data['corners'] as List<dynamic>?),
      format = _getFormat(data['format'] as int?),
      bytes = data['bytes'] as Uint8List?,
      value = data['value'] as String?,
      displayValue = data['displayValue'] as String?,
      boundingBox = _getRect(data['boundingBox'] as Map<dynamic, dynamic>?),
      type = _getBarcodeType(data['type'] as int?),
      calendarEvent = _getCalendarEvent(data['calendarEvent'] as Map<dynamic, dynamic>?),
      contactInfo = _getContactInfo(data['contactInfo'] as Map<dynamic, dynamic>?),
      driverLicense = _getDriverLicense(data['driverLicense'] as Map<dynamic, dynamic>?),
      email = _getEmail(data['email'] as Map<dynamic, dynamic>?),
      geoPoint = _getGeoPoint(data['geoPoint'] as Map<dynamic, dynamic>?),
      phone = _getPhone(data['phone'] as Map<dynamic, dynamic>?),
      sms = _getSMS(data['sms'] as Map<dynamic, dynamic>?),
      url = _getUrl(data['url'] as Map<dynamic, dynamic>?),
      wifi = _getWiFi(data['wifi'] as Map<dynamic, dynamic>?);

  /// 四个角点，按顺时针方向从左上角开始。
  ///
  /// 由于可能存在透视变形，四个点不一定构成矩形。
  final List<Offset>? corners;

  /// 条码格式。
  final BarcodeFormat? format;

  /// 条码的外接矩形。
  final Rect? boundingBox;

  /// 条码中编码的原始字节。
  final Uint8List? bytes;

  /// 条码中编码的原始字符串。
  ///
  /// 仅在条码使用 UTF-8 编码时可用，其他编码请使用 [bytes]。
  final String? value;

  /// 适合展示的条码内容。
  ///
  /// 可能会省略部分编码信息，例如 MEBKM 会被解析为网址。可能包含换行。
  final String? displayValue;

  /// 条码内容的类型，例如文本、网址、WiFi 等。
  final BarcodeType? type;

  /// 解析后的日历事件。
  final CalendarEvent? calendarEvent;

  /// 解析后的联系人信息。
  final ContactInfo? contactInfo;

  /// 解析后的驾照 / 身份证信息。
  final DriverLicense? driverLicense;

  /// 解析后的邮件信息。
  final Email? email;

  /// 解析后的地理位置。
  final GeoPoint? geoPoint;

  /// 解析后的电话号码。
  final Phone? phone;

  /// 解析后的短信信息。
  final SMS? sms;

  /// 解析后的网址书签。
  final UrlBookmark? url;

  /// 解析后的 WiFi 信息。
  final WiFi? wifi;

  @override
  String toString() => 'Barcode(format: ${format?.name}, value: $value, type: ${type?.name})';
}

/// 二维码中的日历事件。
class CalendarEvent {
  /// 从原生返回的 Map 创建日历事件。
  CalendarEvent.fromMap(Map<dynamic, dynamic> data)
    : description = data['description'] as String?,
      start = DateTime.tryParse(data['start'] as String? ?? ''),
      end = DateTime.tryParse(data['end'] as String? ?? ''),
      location = data['location'] as String?,
      organizer = data['organizer'] as String?,
      status = data['status'] as String?,
      summary = data['summary'] as String?;

  /// 事件描述。
  final String? description;

  /// 开始时间。
  final DateTime? start;

  /// 结束时间。
  final DateTime? end;

  /// 事件地点。
  final String? location;

  /// 组织者。
  final String? organizer;

  /// 事件状态。
  final String? status;

  /// 事件标题。
  final String? summary;
}

/// 名片 / 联系人信息，通常来自 VCARD。
class ContactInfo {
  /// 从原生返回的 Map 创建联系人信息。
  ContactInfo.fromMap(Map<dynamic, dynamic> data)
    : addresses = _getList<Address>(data['addresses'], Address.fromMap),
      emails = _getList<Email>(data['emails'], Email.fromMap),
      name = data['name'] != null ? PersonName.fromMap(data['name'] as Map<dynamic, dynamic>) : null,
      organization = data['organization'] as String?,
      phones = _getList<Phone>(data['phones'], Phone.fromMap),
      title = data['title'] as String?,
      urls = _getStringList(data['urls']);

  /// 地址列表。
  final List<Address>? addresses;

  /// 邮箱列表。
  final List<Email>? emails;

  /// 姓名。
  final PersonName? name;

  /// 组织 / 公司名称。
  final String? organization;

  /// 电话列表。
  final List<Phone>? phones;

  /// 职位。
  final String? title;

  /// 网址列表。
  final List<String>? urls;
}

/// 地址信息。
class Address {
  /// 从原生返回的 Map 创建地址。
  Address.fromMap(Map<dynamic, dynamic> data)
    : addressLines = _getStringList(data['addressLines']),
      type = _getEnumValue(AddressType.values, data['type'] as int?);

  /// 多行地址文本。
  final List<String>? addressLines;

  /// 地址类型。
  final AddressType? type;
}

/// 姓名信息。
class PersonName {
  /// 从原生返回的 Map 创建姓名。
  PersonName.fromMap(Map<dynamic, dynamic> data)
    : first = data['first'] as String?,
      middle = data['middle'] as String?,
      last = data['last'] as String?,
      prefix = data['prefix'] as String?,
      suffix = data['suffix'] as String?,
      formattedName = data['formattedName'] as String?,
      pronunciation = data['pronunciation'] as String?;

  /// 名。
  final String? first;

  /// 中间名。
  final String? middle;

  /// 姓。
  final String? last;

  /// 前缀（如 Mr.）。
  final String? prefix;

  /// 后缀（如 Jr.）。
  final String? suffix;

  /// 格式化后的完整姓名。
  final String? formattedName;

  /// 读音，主要用于日文联系人。
  final String? pronunciation;
}

/// 驾照 / 身份证信息。
class DriverLicense {
  /// 从原生返回的 Map 创建证件信息。
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

  /// 城市。
  final String? addressCity;

  /// 州 / 省。
  final String? addressState;

  /// 街道地址。
  final String? addressStreet;

  /// 邮编。
  final String? addressZip;

  /// 出生日期。
  final String? birthDate;

  /// 证件类型："DL" 表示驾照，"ID" 表示身份证。
  final String? documentType;

  /// 过期日期。
  final String? expiryDate;

  /// 名。
  final String? firstName;

  /// 性别：1 男，2 女。
  final String? gender;

  /// 签发日期。
  final String? issueDate;

  /// 签发国家（三位国家代码）。
  final String? issuingCountry;

  /// 姓。
  final String? lastName;

  /// 证件号码。
  final String? licenseNumber;

  /// 中间名。
  final String? middleName;
}

/// 邮件信息，通常来自 MAILTO。
class Email {
  /// 从原生返回的 Map 创建邮件信息。
  Email.fromMap(Map<dynamic, dynamic> data)
    : address = data['address'] as String?,
      body = data['body'] as String?,
      subject = data['subject'] as String?,
      type = _getEnumValue(EmailType.values, data['type'] as int?);

  /// 邮箱地址。
  final String? address;

  /// 正文。
  final String? body;

  /// 主题。
  final String? subject;

  /// 邮箱类型。
  final EmailType? type;
}

/// 地理位置，通常来自 GEO。
class GeoPoint {
  /// 从原生返回的 Map 创建地理位置。
  GeoPoint.fromMap(Map<dynamic, dynamic> data)
    : latitude = (data['latitude'] as num?)?.toDouble(),
      longitude = (data['longitude'] as num?)?.toDouble();

  /// 纬度。
  final double? latitude;

  /// 经度。
  final double? longitude;
}

/// 电话号码信息。
class Phone {
  /// 从原生返回的 Map 创建电话信息。
  Phone.fromMap(Map<dynamic, dynamic> data)
    : number = data['number'] as String?,
      type = _getEnumValue(PhoneType.values, data['type'] as int?);

  /// 电话号码。
  final String? number;

  /// 电话类型。
  final PhoneType? type;
}

/// 短信信息，通常来自 SMS。
class SMS {
  /// 从原生返回的 Map 创建短信信息。
  SMS.fromMap(Map<dynamic, dynamic> data)
    : message = data['message'] as String?,
      phoneNumber = data['phoneNumber'] as String?;

  /// 短信内容。
  final String? message;

  /// 目标号码。
  final String? phoneNumber;
}

/// 网址书签，通常来自 MEBKM。
class UrlBookmark {
  /// 从原生返回的 Map 创建书签信息。
  UrlBookmark.fromMap(Map<dynamic, dynamic> data) : title = data['title'] as String?, url = data['url'] as String?;

  /// 标题。
  final String? title;

  /// 网址。
  final String? url;
}

/// WiFi 信息，通常来自 WIFI。
class WiFi {
  /// 从原生返回的 Map 创建 WiFi 信息。
  WiFi.fromMap(Map<dynamic, dynamic> data)
    : encryptionType = _getEnumValue(EncryptionType.values, data['encryptionType'] as int?),
      ssid = data['ssid'] as String?,
      password = data['password'] as String?;

  /// 加密类型。
  final EncryptionType? encryptionType;

  /// WiFi 名称。
  final String? ssid;

  /// WiFi 密码。
  final String? password;
}

Rect? _getRect(Map<dynamic, dynamic>? data) {
  if (data == null) return null;
  if (_isAndroid) {
    final int left = (data['left'] as num?)?.toInt() ?? 0;
    final int top = (data['top'] as num?)?.toInt() ?? 0;
    final int right = (data['right'] as num?)?.toInt() ?? 0;
    final int bottom = (data['bottom'] as num?)?.toInt() ?? 0;
    return Rect.fromLTRB(left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
  }
  if (_isIOS) {
    final double x = (data['x'] as num?)?.toDouble() ?? 0;
    final double y = (data['y'] as num?)?.toDouble() ?? 0;
    final double width = (data['width'] as num?)?.toDouble() ?? 0;
    final double height = (data['height'] as num?)?.toDouble() ?? 0;
    return Rect.fromLTWH(x, y, width, height);
  }
  return null;
}

List<Barcode>? _getBarcodeList(List<dynamic>? data) =>
    data?.map((dynamic item) => Barcode.fromMap(item as Map<dynamic, dynamic>)).toList(growable: false);

List<Offset>? _getCorners(List<dynamic>? data) => data != null
    ? List<Offset>.unmodifiable(
        data.map<Offset>((dynamic item) {
          final Map<dynamic, dynamic> corner = item as Map<dynamic, dynamic>;
          return Offset((corner['x'] as num?)?.toDouble() ?? 0, (corner['y'] as num?)?.toDouble() ?? 0);
        }),
      )
    : null;

List<String>? _getStringList(dynamic data) =>
    data is List<dynamic> ? List<String>.unmodifiable(data.map<String>((dynamic item) => item.toString())) : null;

List<T>? _getList<T>(dynamic data, T Function(Map<dynamic, dynamic>) fromMap) => data is List<dynamic>
    ? List<T>.unmodifiable(data.map<T>((dynamic item) => fromMap(item as Map<dynamic, dynamic>)))
    : null;

T? _getEnumValue<T>(List<T> values, int? index) {
  if (index == null || index < 0 || index >= values.length) return null;
  return values[index];
}

BarcodeFormat _getFormat(int? value) {
  // 注意：iOS 的 BarcodeFormatUnknown 为 0，Android 为 -1；单条码结果不会返回 all。
  switch (value) {
    case 1:
      return BarcodeFormat.code128;
    case 2:
      return BarcodeFormat.code39;
    case 4:
      return BarcodeFormat.code93;
    case 8:
      return BarcodeFormat.codaBar;
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

BarcodeType? _getBarcodeType(int? value) => _getEnumValue(BarcodeType.values, value);

CalendarEvent? _getCalendarEvent(Map<dynamic, dynamic>? data) => data != null ? CalendarEvent.fromMap(data) : null;

ContactInfo? _getContactInfo(Map<dynamic, dynamic>? data) => data != null ? ContactInfo.fromMap(data) : null;

DriverLicense? _getDriverLicense(Map<dynamic, dynamic>? data) => data != null ? DriverLicense.fromMap(data) : null;

Email? _getEmail(Map<dynamic, dynamic>? data) => data != null ? Email.fromMap(data) : null;

GeoPoint? _getGeoPoint(Map<dynamic, dynamic>? data) => data != null ? GeoPoint.fromMap(data) : null;

Phone? _getPhone(Map<dynamic, dynamic>? data) => data != null ? Phone.fromMap(data) : null;

SMS? _getSMS(Map<dynamic, dynamic>? data) => data != null ? SMS.fromMap(data) : null;

UrlBookmark? _getUrl(Map<dynamic, dynamic>? data) => data != null ? UrlBookmark.fromMap(data) : null;

WiFi? _getWiFi(Map<dynamic, dynamic>? data) => data != null ? WiFi.fromMap(data) : null;
