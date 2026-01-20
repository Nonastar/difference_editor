import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math.dart';

class Vector2Converter implements JsonConverter<Vector2, Map<String, dynamic>> {
  const Vector2Converter();

  @override
  Vector2 fromJson(Map<String, dynamic> json) {
    return Vector2(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Vector2 vector) {
    return {
      'x': double.parse(vector.x.toStringAsFixed(1)),
      'y': double.parse(vector.y.toStringAsFixed(1)),
    };
  }
}
