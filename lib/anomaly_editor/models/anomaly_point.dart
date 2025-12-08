import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'type_converters.dart';

part 'anomaly_point.g.dart';

@JsonSerializable()
class AnomalyPoint {
  final String id;
  final String imageName;
  final String imagePath;

  @OffsetConverter()
  final Offset position;

  @SizeConverter()
  final Size size;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final ui.Image? loadedImage;

  AnomalyPoint({
    required this.id,
    required this.imageName,
    required this.imagePath,
    required this.position,
    required this.size,
    this.loadedImage,
  });

  AnomalyPoint copyWith({
    String? id,
    String? imageName,
    String? imagePath,
    Offset? position,
    Size? size,
    ui.Image? loadedImage,
  }) {
    return AnomalyPoint(
      id: id ?? this.id,
      imageName: imageName ?? this.imageName,
      imagePath: imagePath ?? this.imagePath,
      position: position ?? this.position,
      size: size ?? this.size,
      loadedImage: loadedImage ?? this.loadedImage,
    );
  }

  factory AnomalyPoint.fromJson(Map<String, dynamic> json) => _$AnomalyPointFromJson(json);
  Map<String, dynamic> toJson() => _$AnomalyPointToJson(this);
}
