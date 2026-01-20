// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LevelData _$LevelDataFromJson(Map<String, dynamic> json) {
  json['images']['offset'] = json['offset'];
  return LevelData(
    levelId: json['levelId'] as String,
    images: ImageSettings.fromJson(json['images'] as Map<String, dynamic>),
    differences:
        (json['differences'] as List<dynamic>?)
            ?.map((e) => Difference.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

Map<String, dynamic> _$LevelDataToJson(LevelData instance) => <String, dynamic>{
  'levelId': instance.levelId,
  'images': instance.images,
  'offset': const Vector2Converter().toJson(instance.images.offset ?? Vector2.zero()),
  'differences': instance.differences,
};
