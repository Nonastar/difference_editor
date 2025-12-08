// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'difference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Difference _$DifferenceFromJson(Map<String, dynamic> json) => Difference(
  id: json['id'] as String,
  position: const RectConverter().fromJson(
    json['position'] as Map<String, dynamic>,
  ),
  shape: json['shape'] as String,
);

Map<String, dynamic> _$DifferenceToJson(Difference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'position': const RectConverter().toJson(instance.position),
      'shape': instance.shape,
    };
