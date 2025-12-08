import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../models/anomaly_data.dart';

enum EditorStatus { initial, loading, loaded, failure }
enum EditMode { select, addAnomaly, pan }

class AnomalyEditorState extends Equatable {
  final EditorStatus status;
  final AnomalyData? data;
  final String? selectedAnomalyId;
  final EditMode editMode;
  final String? errorMessage;
  final ImageInfo? backgroundImageInfo;

  const AnomalyEditorState({
    this.status = EditorStatus.initial,
    this.data,
    this.selectedAnomalyId,
    this.editMode = EditMode.select,
    this.errorMessage,
    this.backgroundImageInfo,
  });

  AnomalyEditorState copyWith({
    EditorStatus? status,
    AnomalyData? data,
    String? selectedAnomalyId,
    EditMode? editMode,
    String? errorMessage,
    ImageInfo? backgroundImageInfo,
    bool clearSelection = false,
  }) {
    return AnomalyEditorState(
      status: status ?? this.status,
      data: data ?? this.data,
      selectedAnomalyId: clearSelection ? null : selectedAnomalyId ?? this.selectedAnomalyId,
      editMode: editMode ?? this.editMode,
      errorMessage: errorMessage ?? this.errorMessage,
      backgroundImageInfo: backgroundImageInfo ?? this.backgroundImageInfo,
    );
  }

  @override
  List<Object?> get props => [status, data, selectedAnomalyId, editMode, errorMessage, backgroundImageInfo];
}
