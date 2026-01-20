import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import '../models/difference.dart' as diff_model;
import '../models/image_settings.dart';
import '../models/resize_handle.dart';

class DifferencePainter extends CustomPainter {
  final List<diff_model.Difference> differences;
  final String? selectedId;
  final Rect? currentRect; // For real-time drawing feedback
  final double scale;
  final ImageSettings imageSettings;

  DifferencePainter({
    required this.differences,
    this.selectedId,
    this.currentRect,
    this.scale = 1.0,
    required this.imageSettings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 将原点移动到图片中心
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    final defaultPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale; // Keep stroke width consistent on screen

    final selectedPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 / scale; // Slightly thicker for visibility

    final mirrorPaint = Paint()
      ..color = Colors.red.withAlpha(128) // Replaced deprecated withOpacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale;

    // Draw existing differences
    for (final diff in differences) {
      final isSelected = diff.id == selectedId;
      final paint = isSelected ? selectedPaint : defaultPaint;

      // 使用中心点构造 Rect
      final rect = Rect.fromCenter(
        center: Offset(diff.position.x, diff.position.y),
        width: diff.size.x,
        height: diff.size.y,
      );

      // Draw original shape
      _drawShape(canvas, rect, diff.shape, paint);

      // Draw mirrored shape in single image mode
      if (imageSettings.imageMode == ImageMode.single) {
        Paint currentMirrorPaint;
        if (isSelected) {
          currentMirrorPaint = Paint()
            ..color = selectedPaint.color.withAlpha(179) // Replaced deprecated withOpacity
            ..style = selectedPaint.style
            ..strokeWidth = selectedPaint.strokeWidth;
        } else {
          currentMirrorPaint = mirrorPaint;
        }
        _drawMirroredShape(canvas, rect, diff.shape, currentMirrorPaint, size);
      }

      // Draw resize handles if selected
      if (isSelected) {
        _drawHandles(canvas, rect);
      }
    }

    // Draw the rectangle being created in real-time
    if (currentRect != null) {
      final previewPaint = Paint()
        ..color = Colors.blue.withAlpha(128)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / scale;
      _drawShape(canvas, currentRect!, 'rectangle', previewPaint);

      // Draw mirrored preview
      if (imageSettings.imageMode == ImageMode.single) {
        final mirroredPreviewPaint = Paint()
          ..color = previewPaint.color.withAlpha(64) // Make mirrored preview more transparent
          ..style = previewPaint.style
          ..strokeWidth = previewPaint.strokeWidth;
        _drawMirroredShape(canvas, currentRect!, 'rectangle', mirroredPreviewPaint, size);
      }
    }
    
    canvas.restore();
  }

  void _drawShape(Canvas canvas, Rect rect, String shape, Paint paint) {
    if (shape == 'circle') {
      canvas.drawOval(rect, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  void _drawMirroredShape(Canvas canvas, Rect rect, String shape, Paint paint, Size canvasSize) {
    if (imageSettings.splitMode == null || imageSettings.splitRatio == null || canvasSize.isEmpty) return;

    final offset = imageSettings.offset ?? Vector2.zero();

    final halfWidth = canvasSize.width / 2;
    final halfHeight = canvasSize.height / 2;

    if (imageSettings.splitMode == SplitMode.horizontal) {
      final splitX = -halfWidth + canvasSize.width * imageSettings.splitRatio!;

      final leftPanel = Rect.fromLTWH(-halfWidth, -halfHeight, splitX + halfWidth, canvasSize.height);
      final rightPanel = Rect.fromLTWH(splitX, -halfHeight, halfWidth - splitX, canvasSize.height);

      final leftPart = rect.intersect(leftPanel);
      final rightPart = rect.intersect(rightPanel);

      if (!leftPart.isEmpty) {
        _drawShape(canvas, leftPart.translate(canvasSize.width * imageSettings.splitRatio! + offset.x, 0 + offset.y), shape, paint);
      }

      if (!rightPart.isEmpty) {
        _drawShape(canvas, rightPart.translate(-canvasSize.width * imageSettings.splitRatio! - offset.x, 0 + offset.y), shape, paint);
      }

    } else { // Vertical split
      final splitY = -halfHeight + canvasSize.height * imageSettings.splitRatio!;

      final topPanel = Rect.fromLTWH(-halfWidth, -halfHeight, canvasSize.width, splitY + halfHeight);
      final bottomPanel = Rect.fromLTWH(-halfWidth, splitY, canvasSize.width, halfHeight - splitY);

      final topPart = rect.intersect(topPanel);
      final bottomPart = rect.intersect(bottomPanel);

      if (!topPart.isEmpty) {
        _drawShape(canvas, topPart.translate(0 + offset.x, canvasSize.height * imageSettings.splitRatio! + offset.y), shape, paint);

      }

      if (!bottomPart.isEmpty) {
        _drawShape(canvas, bottomPart.translate(0 + offset.x, -canvasSize.height * imageSettings.splitRatio! + offset.y), shape, paint);

      }
    }
  }

  void _drawHandles(Canvas canvas, Rect rect) {
    final handlePaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    for (final handle in HandlePosition.values) {
      final handleRect = getHandleRect(rect, handle, scale);
      canvas.drawRect(handleRect, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant DifferencePainter oldDelegate) {
    return oldDelegate.differences != differences ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.currentRect != currentRect ||
        oldDelegate.scale != scale ||
        oldDelegate.imageSettings != imageSettings;
  }
}
