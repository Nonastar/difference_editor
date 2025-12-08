import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

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
  final double offsetX;
  final double offsetY;

  const ImageSettings({
    required this.imageMode,
    this.combined,
    this.splitMode,
    this.splitRatio,
    this.original,
    this.modified,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  });

  ImageSettings copyWith({
    ImageMode? imageMode,
    String? combined,
    SplitMode? splitMode,
    double? splitRatio,
    String? original,
    String? modified,
    double? offsetX,
    double? offsetY,
  }) {
    return ImageSettings(
      imageMode: imageMode ?? this.imageMode,
      combined: combined ?? this.combined,
      splitMode: splitMode ?? this.splitMode,
      splitRatio: splitRatio ?? this.splitRatio,
      original: original ?? this.original,
      modified: modified ?? this.modified,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }

  factory ImageSettings.fromJson(Map<String, dynamic> json) =>
      _$ImageSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ImageSettingsToJson(this);

  @override
  List<Object?> get props =>
      [imageMode, combined, splitMode, splitRatio, original, modified, offsetX, offsetY];
}
