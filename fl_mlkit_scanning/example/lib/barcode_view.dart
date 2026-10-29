import 'package:fl_extended/fl_extended.dart';
import 'package:fl_mlkit_scanning/fl_mlkit_scanning.dart';
import 'package:flutter/material.dart';

/// 在相机预览上绘制条码位置。
///
/// [previewSize] 为相机原图尺寸，[fit] 需与 FlCamera 的 fit 保持一致。
class BarcodeOverlay extends StatelessWidget {
  const BarcodeOverlay({super.key, required this.model, required this.previewSize, this.fit = BoxFit.cover});

  /// 当前识别结果。
  final AnalysisImageModel? model;

  /// 相机预览尺寸（像素）。
  final Size? previewSize;

  /// 预览画面的填充方式。
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _BarcodePainter(model: model, previewSize: previewSize, fit: fit),
        ),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter({required this.model, required this.previewSize, required this.fit});

  final AnalysisImageModel? model;
  final Size? previewSize;
  final BoxFit fit;

  @override
  void paint(Canvas canvas, Size size) {
    final AnalysisImageModel? model = this.model;
    if (model == null || model.barcodeList.isEmpty) return;
    final Size imageSize = previewSize ?? Size(model.width ?? size.width, model.height ?? size.height);
    if (imageSize.width <= 0 || imageSize.height <= 0) return;

    final FittedSizes fitted = applyBoxFit(fit, imageSize, size);
    final double scaleX = fitted.destination.width / imageSize.width;
    final double scaleY = fitted.destination.height / imageSize.height;
    final Offset offset = Alignment.center.inscribe(fitted.destination, Offset.zero & size).topLeft;
    Offset map(Offset point) => Offset(offset.dx + point.dx * scaleX, offset.dy + point.dy * scaleY);

    final Paint boxPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final Paint cornerPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final Paint fillPaint = Paint()..color = Colors.cyanAccent.withValues(alpha: 0.15);

    for (final Barcode barcode in model.barcodeList) {
      final Rect? box = barcode.boundingBox;
      if (box != null) {
        final Offset topLeft = map(box.topLeft);
        final Offset bottomRight = map(box.bottomRight);
        canvas.drawRect(Rect.fromPoints(topLeft, bottomRight), boxPaint);
      }
      final List<Offset>? corners = barcode.corners;
      if (corners != null && corners.length == 4) {
        final List<Offset> points = corners.map(map).toList(growable: false);
        final Path path = Path()
          ..moveTo(points.first.dx, points.first.dy)
          ..lineTo(points[1].dx, points[1].dy)
          ..lineTo(points[2].dx, points[2].dy)
          ..lineTo(points[3].dx, points[3].dy)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, cornerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) =>
      oldDelegate.model != model || oldDelegate.previewSize != previewSize || oldDelegate.fit != fit;
}

/// 条码详情卡片。
class BarcodeDetailsCard extends StatelessWidget {
  const BarcodeDetailsCard({super.key, required this.barcode, this.index = 0});

  /// 条码数据。
  final Barcode barcode;

  /// 序号，从 0 开始。
  final int index;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Expanded(child: FlText(barcode.format?.name ?? 'unknown', fontSize: 14, fontWeight: FontWeight.w600)),
                FlText(barcode.type?.name ?? '', fontSize: 12),
              ],
            ),
            const Divider(height: 18),
            _KeyValue(label: '内容', value: barcode.value),
            _KeyValue(label: '展示值', value: barcode.displayValue),
            _KeyValue(label: '外接矩形', value: barcode.boundingBox?.toString()),
            _KeyValue(label: '角点', value: barcode.corners?.join('  ')),
            ..._parseDetails(barcode),
          ],
        ),
      ),
    );
  }

  List<Widget> _parseDetails(Barcode barcode) {
    final List<Widget> children = <Widget>[];
    final UrlBookmark? url = barcode.url;
    if (url != null) {
      children.add(_KeyValue(label: '网址', value: url.url));
      children.add(_KeyValue(label: '标题', value: url.title));
    }
    final WiFi? wifi = barcode.wifi;
    if (wifi != null) {
      children.add(_KeyValue(label: 'WiFi SSID', value: wifi.ssid));
      children.add(_KeyValue(label: 'WiFi 密码', value: wifi.password));
      children.add(_KeyValue(label: 'WiFi 加密', value: wifi.encryptionType?.name));
    }
    final Email? email = barcode.email;
    if (email != null) {
      children.add(_KeyValue(label: '邮箱', value: email.address));
      children.add(_KeyValue(label: '邮件主题', value: email.subject));
      children.add(_KeyValue(label: '邮件正文', value: email.body));
    }
    final Phone? phone = barcode.phone;
    if (phone != null) {
      children.add(_KeyValue(label: '电话', value: phone.number));
      children.add(_KeyValue(label: '电话类型', value: phone.type?.name));
    }
    final SMS? sms = barcode.sms;
    if (sms != null) {
      children.add(_KeyValue(label: '短信号码', value: sms.phoneNumber));
      children.add(_KeyValue(label: '短信内容', value: sms.message));
    }
    final GeoPoint? geo = barcode.geoPoint;
    if (geo != null) {
      children.add(_KeyValue(label: '经纬度', value: '${geo.latitude}, ${geo.longitude}'));
    }
    final CalendarEvent? event = barcode.calendarEvent;
    if (event != null) {
      children.add(_KeyValue(label: '日程标题', value: event.summary));
      children.add(_KeyValue(label: '开始时间', value: event.start?.toIso8601String()));
      children.add(_KeyValue(label: '结束时间', value: event.end?.toIso8601String()));
      children.add(_KeyValue(label: '地点', value: event.location));
    }
    final ContactInfo? contact = barcode.contactInfo;
    if (contact != null) {
      children.add(_KeyValue(label: '联系人', value: contact.name?.formattedName));
      children.add(_KeyValue(label: '组织', value: contact.organization));
      children.add(_KeyValue(label: '职位', value: contact.title));
      children.add(_KeyValue(label: '联系人电话', value: contact.phones?.map((Phone item) => item.number).join(', ')));
      children.add(_KeyValue(label: '联系人邮箱', value: contact.emails?.map((Email item) => item.address).join(', ')));
    }
    final DriverLicense? license = barcode.driverLicense;
    if (license != null) {
      children.add(_KeyValue(label: '证件号码', value: license.licenseNumber));
      children.add(_KeyValue(label: '证件类型', value: license.documentType));
      children.add(_KeyValue(label: '姓名', value: '${license.firstName ?? ''} ${license.lastName ?? ''}'.trim()));
      children.add(_KeyValue(label: '出生日期', value: license.birthDate));
      children.add(_KeyValue(label: '签发国家', value: license.issuingCountry));
    }
    return children;
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final String? value = this.value;
    if (value == null || value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 74, child: FlText(label, fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
