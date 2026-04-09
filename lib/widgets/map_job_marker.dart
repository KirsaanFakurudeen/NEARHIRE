import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapJobMarker {
  static Future<BitmapDescriptor> create(String jobType) async {
    final color = _colorForType(jobType);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 48.0;

    final paint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 1.5, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: _iconForType(jobType),
        style: const TextStyle(fontSize: 22, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  static Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'full-time': return const Color(0xFF1565C0);
      case 'part-time': return const Color(0xFF6A1B9A);
      case 'freelance': return const Color(0xFF2E7D32);
      case 'gig': return const Color(0xFFE65100);
      case 'shift-based': return const Color(0xFF00695C);
      default: return const Color(0xFF1A3C6E);
    }
  }

  static String _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'full-time': return '💼';
      case 'part-time': return '⏰';
      case 'freelance': return '💻';
      case 'gig': return '⚡';
      case 'shift-based': return '🔄';
      default: return '📍';
    }
  }
}
