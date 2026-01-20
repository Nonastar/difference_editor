import 'dart:math';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/anomaly_editor_cubit.dart';
import '../bloc/anomaly_editor_state.dart';
import '../models/anomaly_point.dart';
import '../models/resize_handle.dart';
import 'anomaly_painter.dart';

class AnomalyCanvasView extends StatefulWidget {
  const AnomalyCanvasView({super.key});

  @override
  State<AnomalyCanvasView> createState() => _AnomalyCanvasViewState();
}

class _AnomalyCanvasViewState extends State<AnomalyCanvasView> {
  final TransformationController _transformationController = TransformationController();

  // 交互状态
  HandlePosition? _resizingHandle;
  AnomalyPoint? _movingAnomaly;
  Offset? _dragStart;
  Rect? _initialRect;
  bool _isAutoFitScheduled = true;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnomalyEditorCubit, AnomalyEditorState>(
      listenWhen: (previous, current) =>
          previous.data?.backgroundImage != current.data?.backgroundImage,
      listener: (context, state) {
        if (state.data?.backgroundImage != null) {
          setState(() {
            _isAutoFitScheduled = true;
          });
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final state = context.watch<AnomalyEditorCubit>().state;

          if (_isAutoFitScheduled && state.data?.backgroundImage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _autoFitImage(constraints, state.data!.backgroundImage!);
              }
            });
            _isAutoFitScheduled = false;
          }

          final scale = _transformationController.value.getMaxScaleOnAxis();
          return Listener(
            onPointerDown: (details) =>
                _handlePointerDown(details, context, state),
            onPointerMove: (details) =>
                _handlePointerMove(details, context, state),
            onPointerUp: (details) => _handlePointerUp(details, context, state),
            child: InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.1,
              maxScale: 4.0,
              panEnabled: state.editMode == EditMode.pan,
              scaleEnabled: state.editMode == EditMode.pan,
              child: CustomPaint(
                size: _getCanvasSize(state),
                painter: AnomalyPainter(
                  data: state.data,
                  selectedAnomalyId: state.selectedAnomalyId,
                  scale: scale,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _autoFitImage(BoxConstraints constraints, ui.Image image) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final viewWidth = constraints.maxWidth;
    final viewHeight = constraints.maxHeight;

    if (imageWidth <= 0 ||
        imageHeight <= 0 ||
        viewWidth <= 0 ||
        viewHeight <= 0) return;

    final scale = min(viewWidth / imageWidth, viewHeight / imageHeight);
    final dx = (viewWidth - imageWidth * scale) / 2.0;
    final dy = (viewHeight - imageHeight * scale) / 2.0;

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  Size _getCanvasSize(AnomalyEditorState state) {
    if (state.data?.backgroundImage != null) {
      return Size(
        state.data!.backgroundImage!.width.toDouble(),
        state.data!.backgroundImage!.height.toDouble(),
      );
    }
    return const Size(1920, 1080); // 默认尺寸
  }

  void _handlePointerDown(
      PointerDownEvent details, BuildContext context, AnomalyEditorState state) {
    if (state.editMode != EditMode.select) {
      _resetInteraction();
      return;
    }

    final scenePos = _transformationController.toScene(details.localPosition);

    if (details.kind == PointerDeviceKind.mouse &&
        details.buttons == kSecondaryMouseButton) {
      _showAddAnomalyDialog(context, scenePos);
      return;
    }

    final selectedAnomaly = _findAnomalyById(state, state.selectedAnomalyId);
    // 优先检查是否点击了已选中异常点的缩放手柄
    if (selectedAnomaly != null) {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      final selectedRect = Rect.fromCenter(
          center: selectedAnomaly.position,
          width: selectedAnomaly.size.width,
          height: selectedAnomaly.size.height);

      _resizingHandle = _hittestHandles(scenePos, selectedRect, scale);

      if (_resizingHandle != null) {
        // 开始调整大小
        _dragStart = scenePos;
        _initialRect = selectedRect;
        return; // 找到手柄，无需检查移动或选择
      }

      // 如果没有点击到手柄，检查是否在异常点内部以开始移动
      if (selectedRect.contains(scenePos)) {
        _movingAnomaly = selectedAnomaly;
        _dragStart = scenePos;
        _initialRect = selectedRect; // 关键修复: 为移动操作初始化矩形
        return;
      }
    }

    // 如果没有选中任何异常点，或者点击位置在选中的异常点之外，
    // 则执行新的选择测试。
    _handleSelection(context, scenePos, state);
  }

  void _handlePointerMove(
      PointerMoveEvent details, BuildContext context, AnomalyEditorState state) {
    if (_dragStart == null || state.editMode != EditMode.select) return;

    final scenePos = _transformationController.toScene(details.localPosition);

    if (_resizingHandle != null && _initialRect != null) {
      // 执行调整大小
      final dragDelta = scenePos - _dragStart!;
      final newRect = _resizeRect(_initialRect!, _resizingHandle!, dragDelta);
      context
          .read<AnomalyEditorCubit>()
          .updateAnomalySize(state.selectedAnomalyId!, newRect.size);
      context
          .read<AnomalyEditorCubit>()
          .updateAnomalyPosition(state.selectedAnomalyId!, newRect.center);
    } else if (_movingAnomaly != null && _initialRect != null) {
      // 关键修复: 基于初始位置计算新位置，而不是上一个状态
      final newPosition = _initialRect!.center + (scenePos - _dragStart!);
      context
          .read<AnomalyEditorCubit>()
          .updateAnomalyPosition(_movingAnomaly!.id, newPosition);
    }
  }

  void _handlePointerUp(
      PointerUpEvent details, BuildContext context, AnomalyEditorState state) {
    // 最终状态已由 onPointerMove 发送。只需重置交互状态。
    _resetInteraction();
  }

  void _resetInteraction() {
    if (mounted) {
      setState(() {
        _resizingHandle = null;
        _movingAnomaly = null;
        _dragStart = null;
        _initialRect = null;
      });
    }
  }

  HandlePosition? _hittestHandles(Offset position, Rect rect, double scale) {
    for (final handle in HandlePosition.values) {
      final handleRect = getHandleRect(rect, handle, scale);
      if (handleRect.contains(position)) {
        return handle;
      }
    }
    return null;
  }

  void _handleSelection(
      BuildContext context, Offset position, AnomalyEditorState state) {
    if (state.data == null) return;
    String? tappedAnomalyId;
    for (final anomaly in state.data!.anomalies.reversed) {
      final rect = Rect.fromCenter(
          center: anomaly.position,
          width: anomaly.size.width,
          height: anomaly.size.height);
      if (rect.contains(position)) {
        tappedAnomalyId = anomaly.id;
        break;
      }
    }
    context.read<AnomalyEditorCubit>().selectAnomaly(tappedAnomalyId);
  }

  AnomalyPoint? _findAnomalyById(AnomalyEditorState state, String? id) {
    if (id == null || state.data == null) return null;
    try {
      return state.data!.anomalies.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _showAddAnomalyDialog(BuildContext context, Offset position) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      context
          .read<AnomalyEditorCubit>()
          .addAnomaly(result.files.single.path!, position);
    }
  }

  Rect _resizeRect(Rect rect, HandlePosition handle, Offset delta) {

    // 保持中心不变，调整大小
    double centerX = rect.center.dx;
    double centerY = rect.center.dy;
    double width = rect.width;
    double height = rect.height;

    switch (handle) {
      case HandlePosition.topLeft:
        width -= delta.dx;
        height -= delta.dy;
        break;
      case HandlePosition.topCenter:
        height -= delta.dy;
        break;
      case HandlePosition.topRight:
        width += delta.dx;
        height -= delta.dy;
        break;
      case HandlePosition.centerLeft:
        width -= delta.dx;
        break;
      case HandlePosition.centerRight:
        width += delta.dx;
        break;
      case HandlePosition.bottomLeft:
        width -= delta.dx;
        height += delta.dy;
        break;
      case HandlePosition.bottomCenter:
        height += delta.dy;
        break;
      case HandlePosition.bottomRight:
        width += delta.dx;
        height += delta.dy;
        break;
    }

    // 确保宽高不为负
    width = max(0, width);
    height = max(0, height);

    return Rect.fromCenter(center: Offset(centerX, centerY), width: width, height: height);
  }
}
