import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:vector_math/vector_math.dart';
import 'editor_state.dart';
import '../models/difference.dart';
import '../models/image_settings.dart';
import '../models/level.dart';
import 'package:image_picker/image_picker.dart';

class EditorCubit extends Cubit<EditorState> {
  EditorCubit() : super(const EditorState());

  final _imagePicker = ImagePicker();

  Future<void> loadImage() async {
    emit(state.copyWith(status: EditorStatus.loading));
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) {
        emit(state.copyWith(status: EditorStatus.initial));
        return;
      }

      ImageSettings imageSettings;
      if (images.length == 1) {
        imageSettings = ImageSettings(
          imageMode: ImageMode.single,
          combined: images.first.path,
          splitMode: SplitMode.horizontal,
          splitRatio: 0.5,
        );
      } else {
        imageSettings = ImageSettings(
          imageMode: ImageMode.double,
          original: images[0].path,
          modified: images[1].path,
        );
      }

      LevelData? loadedLevel;
      try {
        final path = images.first.path;
        final jsonPath = setExtension(path, '.json');
        final jsonFile = File(jsonPath);
        if (await jsonFile.exists()) {
          final content = await jsonFile.readAsString();
          final jsonMap = jsonDecode(content);
          loadedLevel = LevelData.fromJson(jsonMap);
        }
      } catch (e) {
        print('Error loading JSON: $e');
      }

      final LevelData level;
      if (loadedLevel != null) {
        level = loadedLevel.copyWith(
          levelId: basenameWithoutExtension(images.first.path),
          images: loadedLevel.images.copyWith(
            imageMode: imageSettings.imageMode,
            combined: imageSettings.combined,
            original: imageSettings.original,
            modified: imageSettings.modified,
          ),
        );
      } else {
        level = LevelData(
          levelId: basenameWithoutExtension(images.first.path),
          images: imageSettings,
        );
      }

      emit(state.copyWith(status: EditorStatus.loaded, level: level, clearSelectedDifference: true));
    } catch (e) {
      emit(state.copyWith(status: EditorStatus.error, errorMessage: e.toString()));
    }
  }

  void updateImageSettings(ImageSettings settings) {
    if (state.level != null) {
      final updatedLevel = state.level!.copyWith(images: settings);
      emit(state.copyWith(level: updatedLevel));
    }
  }

  void setTool(DrawingTool tool) {
    emit(state.copyWith(selectedTool: tool, clearSelectedDifference: true));
  }

  void addDifference(Difference diff) {
    if (state.level != null) {
      final updatedDiffs = List<Difference>.from(state.level!.differences)..add(diff);
      final updatedLevel = state.level!.copyWith(differences: updatedDiffs);
      emit(state.copyWith(level: updatedLevel));
    }
  }

  void updateDifference(Difference diff) {
    if (state.level != null) {
      final index = state.level!.differences.indexWhere((d) => d.id == diff.id);
      if (index != -1) {
        final updatedDiffs = List<Difference>.from(state.level!.differences);
        updatedDiffs[index] = diff;
        final updatedLevel = state.level!.copyWith(differences: updatedDiffs);
        emit(state.copyWith(level: updatedLevel));
      }
    }
  }

  void selectDifference(String? id) {
    emit(state.copyWith(selectedDifferenceId: id));
  }

  void deleteSelectedDifference() {
    if (state.level != null && state.selectedDifferenceId != null) {
      final updatedDiffs = state.level!.differences
          .where((d) => d.id != state.selectedDifferenceId)
          .toList();
      final updatedLevel = state.level!.copyWith(differences: updatedDiffs);
      emit(state.copyWith(level: updatedLevel, clearSelectedDifference: true));
    }
  }

  Future<String?> saveLevelToJson() async {
    if (state.level == null) return null;

    try {
      // Let the user choose the save location and file name.
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: '${state.level!.levelId}.json',
        allowedExtensions: ['json'],
      );

      if (outputPath == null) {
        // User canceled the picker
        return null;
      }

      final file = File(outputPath);

      final jsonString = jsonEncode(state.level!.toJson());
      await file.writeAsString(jsonString);

      return outputPath;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return null;
    }
  }
}
