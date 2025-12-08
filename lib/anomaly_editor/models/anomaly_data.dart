import 'dart:ui' as ui;
import 'anomaly_point.dart';

class AnomalyData {
  final String? backgroundImagePath;
  final List<AnomalyPoint> anomalies;

  final ui.Image? backgroundImage;

  AnomalyData({
    this.backgroundImagePath,
    this.backgroundImage,
    this.anomalies = const [],
  });

  AnomalyData copyWith({
    String? backgroundImagePath,
    ui.Image? backgroundImage,
    List<AnomalyPoint>? anomalies,
  }) {
    return AnomalyData(
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      anomalies: anomalies ?? this.anomalies,
    );
  }
}
