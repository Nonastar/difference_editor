import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

import '../models/anomaly_data.dart';
import '../models/anomaly_point.dart';
import 'anomaly_editor_state.dart';

class AnomalyEditorCubit extends Cubit<AnomalyEditorState> {
  AnomalyEditorCubit() : super(const AnomalyEditorState());

  final _uuid = const Uuid();

  Future<void> loadBackgroundImage(String path) async {
    try {
      emit(state.copyWith(status: EditorStatus.loading));
      final file = File(path);
      final bytes = await file.readAsBytes();
      final image = await _decodeImage(bytes);
      final imageInfo = ImageInfo(image: image);
      final data = AnomalyData(
        backgroundImagePath: path,
        backgroundImage: image,
      );
      emit(state.copyWith(
        status: EditorStatus.loaded,
        data: data,
        backgroundImageInfo: imageInfo,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: EditorStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> addAnomaly(String imagePath, Offset position) async {
    if (state.data == null) return;

    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = await _decodeImage(bytes);
      final imageName = p.basename(imagePath);

      final newAnomaly = AnomalyPoint(
        id: _uuid.v4(),
        imageName: imageName,
        imagePath: imagePath,
        position: position,
        size: Size(image.width.toDouble() / 2, image.height.toDouble() / 2), // Default size
        loadedImage: image,
      );

      final updatedAnomalies = List<AnomalyPoint>.from(state.data!.anomalies)
        ..add(newAnomaly);

      emit(state.copyWith(
        data: state.data!.copyWith(anomalies: updatedAnomalies),
        selectedAnomalyId: newAnomaly.id,
        editMode: EditMode.select,
      ));
    } catch (e) {
      // Handle error
    }
  }

  void selectAnomaly(String? anomalyId) {
    emit(state.copyWith(selectedAnomalyId: anomalyId));
  }
  
  void deleteSelectedAnomaly() {
    if (state.selectedAnomalyId == null || state.data == null) return;

    final updatedAnomalies = state.data!.anomalies
        .where((a) => a.id != state.selectedAnomalyId)
        .toList();

    emit(state.copyWith(
      data: state.data!.copyWith(anomalies: updatedAnomalies),
      selectedAnomalyId: null,
    ));
  }

  void updateAnomalyPosition(String anomalyId, Offset newPosition) {
    if (state.data == null) return;

    final updatedAnomalies = state.data!.anomalies.map((anomaly) {
      if (anomaly.id == anomalyId) {
        return anomaly.copyWith(position: newPosition);
      }
      return anomaly;
    }).toList();

    emit(state.copyWith(
        data: state.data!.copyWith(anomalies: updatedAnomalies)));
  }
  
  void updateAnomalySize(String anomalyId, Size newSize) {
    if (state.data == null) return;

    final updatedAnomalies = state.data!.anomalies.map((anomaly) {
      if (anomaly.id == anomalyId) {
        return anomaly.copyWith(size: newSize);
      }
      return anomaly;
    }).toList();

    emit(state.copyWith(
        data: state.data!.copyWith(anomalies: updatedAnomalies)));
  }

  void setEditMode(EditMode mode) {
    emit(state.copyWith(editMode: mode));
  }

  Future<String?> saveAnomaliesToJson() async {
    if (state.data == null) return null;

    try {
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'anomalies.json',
        allowedExtensions: ['json'],
      );

      if (outputPath == null) {
        return null;
      }

      final file = File(outputPath);
      // Manually create a map to be serialized to JSON
      final dataToSave = {
        'backgroundImagePath': state.data!.backgroundImagePath,
        'anomalies': state.data!.anomalies.map((anomaly) {
          return {
            'id': anomaly.id,
            'imageName': anomaly.imageName,
            'imagePath': anomaly.imagePath,
            'position': {
              'dx': anomaly.position.dx,
              'dy': anomaly.position.dy,
            },
            'size': {
              'width': anomaly.size.width,
              'height': anomaly.size.height,
            },
          };
        }).toList(),
      };
      final jsonString = jsonEncode(dataToSave);
      await file.writeAsString(jsonString);

      return outputPath;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return null;
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
