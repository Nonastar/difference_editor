import 'package:flutter/material.dart';
import '../models/anomaly_data.dart';
import '../models/resize_handle.dart';

class AnomalyPainter extends CustomPainter {
  final AnomalyData? data;
  final String? selectedAnomalyId;
  final double scale;

  AnomalyPainter({required this.data, this.selectedAnomalyId, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    if (data?.backgroundImage != null) {
      final bgRect = Rect.fromLTWH(0, 0, data!.backgroundImage!.width.toDouble(), data!.backgroundImage!.height.toDouble());
      canvas.drawImageRect(
        data!.backgroundImage!,
        Rect.fromLTWH(0, 0, data!.backgroundImage!.width.toDouble(), data!.backgroundImage!.height.toDouble()),
        bgRect,
        Paint(),
      );
    }

    // Draw anomalies
    if (data != null) {
      for (final anomaly in data!.anomalies) {
        if (anomaly.loadedImage != null) {
          final rect = Rect.fromCenter(
            center: anomaly.position,
            width: anomaly.size.width,
            height: anomaly.size.height,
          );

          canvas.drawImageRect(
            anomaly.loadedImage!,
            Rect.fromLTWH(0, 0, anomaly.loadedImage!.width.toDouble(), anomaly.loadedImage!.height.toDouble()),
            rect,
            Paint(),
          );

          // Draw border and handles if selected
          if (anomaly.id == selectedAnomalyId) {
            final borderPaint = Paint()
              ..color = Colors.red
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0 / scale;
            canvas.drawRect(rect.inflate(2.0 / scale), borderPaint);
            _drawHandles(canvas, rect);
          }
        }
      }
    }
  }

  void _drawHandles(Canvas canvas, Rect rect) {
    final handlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (final handle in HandlePosition.values) {
      final handleRect = getHandleRect(rect, handle, scale);
      canvas.drawRect(handleRect, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnomalyPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.selectedAnomalyId != selectedAnomalyId ||
           oldDelegate.scale != scale;
  }
}
