// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anomaly_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnomalyPoint _$AnomalyPointFromJson(Map<String, dynamic> json) => AnomalyPoint(
  id: json['id'] as String,
  imageName: json['imageName'] as String,
  imagePath: json['imagePath'] as String,
  position: const OffsetConverter().fromJson(
    json['position'] as Map<String, dynamic>,
  ),
  size: const SizeConverter().fromJson(json['size'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AnomalyPointToJson(AnomalyPoint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imageName': instance.imageName,
      'imagePath': instance.imagePath,
      'position': const OffsetConverter().toJson(instance.position),
      'size': const SizeConverter().toJson(instance.size),
    };
