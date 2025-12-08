import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'type_converters.dart';

part 'difference.g.dart';

@JsonSerializable()
class Difference extends Equatable {
  final String id;

  @RectConverter()
  final Rect position;

  final String shape; // "circle" or "rectangle"

  const Difference({
    required this.id,
    required this.position,
    required this.shape,
  });

  Difference copyWith({
    String? id,
    Rect? position,
    String? shape,
  }) {
    return Difference(
      id: id ?? this.id,
      position: position ?? this.position,
      shape: shape ?? this.shape,
    );
  }

  factory Difference.fromJson(Map<String, dynamic> json) => _$DifferenceFromJson(json);
  Map<String, dynamic> toJson() => _$DifferenceToJson(this);

  @override
  List<Object?> get props => [id, position, shape];
}
