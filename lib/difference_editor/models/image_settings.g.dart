// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageSettings _$ImageSettingsFromJson(Map<String, dynamic> json) =>(
    ImageSettings(
      imageMode: $enumDecode(_$ImageModeEnumMap, json['imageMode']),
      combined: json['combined'] as String?,
      splitMode: $enumDecodeNullable(_$SplitModeEnumMap, json['splitMode']),
      splitRatio: (json['splitRatio'] as num?)?.toDouble() ?? 0.5,
      original: json['original'] == null ? null : json['original'] as String?,
      modified: json['modified'] == null ? null : json['modified'] as String?,
      offset: const Vector2Converter().fromJson(
        json['offset'] as Map<String, dynamic>,
      ),
    ));

Map<String, dynamic> _$ImageSettingsToJson(ImageSettings instance) =>
    <String, dynamic>{
      'imageMode': _$ImageModeEnumMap[instance.imageMode]!,
      'combined': instance.combined,
      'splitMode': _$SplitModeEnumMap[instance.splitMode],
      'splitRatio': instance.splitRatio,
      'original': instance.original,
      'modified': instance.modified,
      //'offset': const Vector2Converter().toJson(instance.offset),
    };

const _$ImageModeEnumMap = {
  ImageMode.single: 'single',
  ImageMode.double: 'double',
};

const _$SplitModeEnumMap = {
  SplitMode.horizontal: 'horizontal',
  SplitMode.vertical: 'vertical',
};
