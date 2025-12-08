import 'package:flutter/material.dart';

const double kHandleSize = 8.0;

enum HandlePosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

// Helper to get the Rect for a given handle on a difference's position
Rect getHandleRect(Rect rect, HandlePosition handle, double scale) {
  final handleRadius = kHandleSize / scale / 2;
  switch (handle) {
    case HandlePosition.topLeft:
      return Rect.fromCircle(center: rect.topLeft, radius: handleRadius);
    case HandlePosition.topCenter:
      return Rect.fromCircle(center: rect.topCenter, radius: handleRadius);
    case HandlePosition.topRight:
      return Rect.fromCircle(center: rect.topRight, radius: handleRadius);
    case HandlePosition.centerLeft:
      return Rect.fromCircle(center: rect.centerLeft, radius: handleRadius);
    case HandlePosition.centerRight:
      return Rect.fromCircle(center: rect.centerRight, radius: handleRadius);
    case HandlePosition.bottomLeft:
      return Rect.fromCircle(center: rect.bottomLeft, radius: handleRadius);
    case HandlePosition.bottomCenter:
      return Rect.fromCircle(center: rect.bottomCenter, radius: handleRadius);
    case HandlePosition.bottomRight:
      return Rect.fromCircle(center: rect.bottomRight, radius: handleRadius);
  }
}
