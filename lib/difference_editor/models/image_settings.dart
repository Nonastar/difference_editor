import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:vector_math/vector_math.dart';

import 'type_converters.dart';

part 'image_settings.g.dart';

enum ImageMode { single, double }

enum SplitMode { horizontal, vertical }

@JsonSerializable()
class ImageSettings extends Equatable {
  final ImageMode imageMode;
  final String? combined;
  final SplitMode? splitMode;
  final double? splitRatio;
  final String? original;
  final String? modified;
  @Vector2Converter()
  final Vector2? offset;

  const ImageSettings({
    required this.imageMode,
    this.combined,
    this.splitMode,
    this.splitRatio,
    this.original,
    this.modified,
    this.offset,
  });

  ImageSettings copyWith({
    ImageMode? imageMode,
    String? combined,
    SplitMode? splitMode,
    double? splitRatio,
    String? original,
    String? modified,
    Vector2? offset,
  }) {
    return ImageSettings(
      imageMode: imageMode ?? this.imageMode,
      combined: combined ?? this.combined,
      splitMode: splitMode ?? this.splitMode,
      splitRatio: splitRatio ?? this.splitRatio,
      original: original ?? this.original,
      modified: modified ?? this.modified,
      offset: offset ?? this.offset,
    );
  }

  factory ImageSettings.fromJson(Map<String, dynamic> json) =>
      _$ImageSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ImageSettingsToJson(this);

  @override
  List<Object?> get props =>
      [imageMode, combined, splitMode, splitRatio, original, modified, offset];
}