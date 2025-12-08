import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'difference.dart';
import 'image_settings.dart';

part 'level.g.dart';

@JsonSerializable()
class LevelData extends Equatable {
  final String levelId;
  final ImageSettings images;
  final List<Difference> differences;

  const LevelData({
    required this.levelId,
    required this.images,
    this.differences = const [],
  });

  LevelData copyWith({
    String? levelId,
    ImageSettings? images,
    List<Difference>? differences,
  }) {
    return LevelData(
      levelId: levelId ?? this.levelId,
      images: images ?? this.images,
      differences: differences ?? this.differences,
    );
  }

  factory LevelData.fromJson(Map<String, dynamic> json) =>
      _$LevelDataFromJson(json);

  Map<String, dynamic> toJson() => _$LevelDataToJson(this);

  @override
  List<Object?> get props => [levelId, images, differences];
}
