import 'package:equatable/equatable.dart';
import '../models/level.dart';

enum EditorStatus { initial, loading, loaded, error }
enum DrawingTool { select, pan, circle, rectangle }

class EditorState extends Equatable {
  final EditorStatus status;
  final LevelData? level;
  final String? errorMessage;
  final DrawingTool selectedTool;
  final String? selectedDifferenceId;

  const EditorState({
    this.status = EditorStatus.initial,
    this.level,
    this.errorMessage,
    this.selectedTool = DrawingTool.select,
    this.selectedDifferenceId,
  });

  EditorState copyWith({
    EditorStatus? status,
    LevelData? level,
    String? errorMessage,
    DrawingTool? selectedTool,
    String? selectedDifferenceId,
    bool clearSelectedDifference = false,
  }) {
    return EditorState(
      status: status ?? this.status,
      level: level ?? this.level,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedDifferenceId: clearSelectedDifference ? null : selectedDifferenceId ?? this.selectedDifferenceId,
    );
  }

  @override
  List<Object?> get props => [status, level, errorMessage, selectedTool, selectedDifferenceId];
}
