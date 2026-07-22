import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerHelper {
  static Future<BitmapDescriptor> createCustomMarkerBitmap(String label, Color backgroundColor) async {
    final int size = 50; // 120px for good resolution
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint backgroundPaint = Paint()..color = backgroundColor;
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final double radius = size / 2.0;

    // Draw background circle
    canvas.drawCircle(Offset(radius, radius), radius - 3.0, backgroundPaint);
    
    // Draw border circle
    canvas.drawCircle(Offset(radius, radius), radius - 3.0, borderPaint);

    // Draw text
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: size * 0.5,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  static Future<BitmapDescriptor> createRichInfoMarkerBitmap(String label, String timeText, String distText, Color color) async {
    final int width = 300;
    final int height = 300;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint paint = Paint()..color = color;
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final Paint circlePaint = Paint()..color = color;
    final Paint circleBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    // Draw info box rectangle
    final Rect rect = Rect.fromLTRB(10, 10, width - 10, 130);
    final RRect rRect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    canvas.drawRRect(rRect, paint);
    canvas.drawRRect(rRect, borderPaint);

    // Draw triangle pointer
    final Path path = Path();
    path.moveTo(width / 2 - 20, 130);
    path.lineTo(width / 2 + 20, 130);
    path.lineTo(width / 2, 160);
    path.close();
    canvas.drawPath(path, paint);

    // Draw text inside rectangle
    TextPainter timePainter = TextPainter(textDirection: TextDirection.ltr);
    timePainter.text = TextSpan(
      text: timeText,
      style: const TextStyle(fontSize: 45, color: Colors.black, fontWeight: FontWeight.bold),
    );
    timePainter.layout();
    timePainter.paint(
      canvas,
      Offset((width - timePainter.width) / 2, 20),
    );

    TextPainter distPainter = TextPainter(textDirection: TextDirection.ltr);
    distPainter.text = TextSpan(
      text: distText,
      style: const TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.w500),
    );
    distPainter.layout();
    distPainter.paint(
      canvas,
      Offset((width - distPainter.width) / 2, 70),
    );

    // Draw label circle below
    final double circleCenterY = 220;
    final double radius = 50;
    canvas.drawCircle(Offset(width / 2, circleCenterY), radius, circlePaint);
    canvas.drawCircle(Offset(width / 2, circleCenterY), radius, circleBorder);

    TextPainter labelPainter = TextPainter(textDirection: TextDirection.ltr);
    labelPainter.text = TextSpan(
      text: label,
      style: const TextStyle(fontSize: 50, color: Colors.white, fontWeight: FontWeight.bold),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(
        (width - labelPainter.width) / 2,
        circleCenterY - labelPainter.height / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(width, height);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  static Future<BitmapDescriptor> createCarMarkerBitmap() async {
    final int size = 50;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint backgroundPaint = Paint()..color = Colors.black;
    final Paint borderPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final double radius = size / 2.0;

    canvas.drawCircle(Offset(radius, radius), radius - 3.0, backgroundPaint);
    canvas.drawCircle(Offset(radius, radius), radius - 3.0, borderPaint);

    TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_car.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: Icons.directions_car.fontFamily,
        package: Icons.directions_car.fontPackage,
        color: Colors.white,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        radius - iconPainter.width / 2,
        radius - iconPainter.height / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }
}
