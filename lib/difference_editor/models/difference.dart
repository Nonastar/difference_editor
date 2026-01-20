import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math.dart';
import 'type_converters.dart';

part 'difference.g.dart';

@JsonSerializable()
class Difference extends Equatable {
  final String id;

  @Vector2Converter()
  final Vector2 position;

  @Vector2Converter()
  final Vector2 size;

  final String shape; // "circle" or "rectangle"

  const Difference({
    required this.id,
    required this.position,
    required this.size,
    required this.shape,
  });

  Difference copyWith({
    String? id,
    Vector2? position,
    Vector2? size,
    String? shape,
  }) {
    return Difference(
      id: id ?? this.id,
      position: position ?? this.position,
      size: size ?? this.size,
      shape: shape ?? this.shape,
    );
  }

  factory Difference.fromJson(Map<String, dynamic> json) => _$DifferenceFromJson(json);
  Map<String, dynamic> toJson() => _$DifferenceToJson(this);

  @override
  List<Object?> get props => [id, position, size, shape];
}
