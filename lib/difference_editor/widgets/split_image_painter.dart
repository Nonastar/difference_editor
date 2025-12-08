import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../models/image_settings.dart';

class SplitImagePainter extends CustomPainter {
  final ui.Image image;
  final SplitMode splitMode;
  final double splitRatio;

  SplitImagePainter({
    required this.image,
    required this.splitMode,
    required this.splitRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final srcWidth = image.width.toDouble();
    final srcHeight = image.height.toDouble();

    if (splitMode == SplitMode.horizontal) {
      // Left part
      final srcLeftRect = Rect.fromLTWH(0, 0, srcWidth * splitRatio, srcHeight);
      final destLeftRect = Rect.fromLTWH(0, 0, size.width / 2, size.height);
      canvas.drawImageRect(image, srcLeftRect, destLeftRect, paint);

      // Right part
      final srcRightRect = Rect.fromLTWH(srcWidth * splitRatio, 0, srcWidth * (1 - splitRatio), srcHeight);
      final destRightRect = Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
      canvas.drawImageRect(image, srcRightRect, destRightRect, paint);

    } else { // Vertical
      // Top part
      final srcTopRect = Rect.fromLTWH(0, 0, srcWidth, srcHeight * splitRatio);
      final destTopRect = Rect.fromLTWH(0, 0, size.width, size.height / 2);
      canvas.drawImageRect(image, srcTopRect, destTopRect, paint);

      // Bottom part
      final srcBottomRect = Rect.fromLTWH(0, srcHeight * splitRatio, srcWidth, srcHeight * (1 - splitRatio));
      final destBottomRect = Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2);
      canvas.drawImageRect(image, srcBottomRect, destBottomRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // For simplicity, always repaint. Can be optimized.
  }
}
