import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/editor_cubit.dart';
import '../bloc/editor_state.dart';
import '../models/difference.dart' as diff_model;
import '../models/image_settings.dart';
import '../models/resize_handle.dart';
import 'difference_painter.dart';
import 'split_image_painter.dart';
import 'package:uuid/uuid.dart';

class CanvasView extends StatefulWidget {
  final ImageSettings imageSettings;
  final List<diff_model.Difference> differences;

  const CanvasView({
    super.key,
    required this.imageSettings,
    required this.differences,
  });

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  ui.Image? _singleImage;
  Size? _doubleImageSize;
  Offset? _startPan;
  Offset? _endPan;
  final _uuid = const Uuid();
  bool _isAutoFitScheduled = true;

  // 用于移动差异点的缓存引用，避免频繁查找。
  diff_model.Difference? _movingDifference;
  // 用于调整大小的状态
  HandlePosition? _resizingHandle;
  Rect? _initialResizeRect;


  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadImageForCanvas();
    _transformationController.addListener(() {
      setState(() {});
    });
  }

  void _loadImageForCanvas() {
    if (widget.imageSettings.imageMode == ImageMode.single) {
      _loadSingleImage();
    } else {
      _loadDoubleImageSize();
    }
  }

  @override
  void didUpdateWidget(covariant CanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final didImageChange = (widget.imageSettings.imageMode != oldWidget.imageSettings.imageMode) ||
        (widget.imageSettings.imageMode == ImageMode.single &&
            widget.imageSettings.combined != oldWidget.imageSettings.combined) ||
        (widget.imageSettings.imageMode == ImageMode.double &&
            (widget.imageSettings.original != oldWidget.imageSettings.original ||
                widget.imageSettings.modified != oldWidget.imageSettings.modified));

    if (didImageChange) {
      _loadImageForCanvas();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _singleImage?.dispose();
    super.dispose();
  }

  Future<void> _loadSingleImage() async {
    if (widget.imageSettings.combined == null) return;
    final bytes = await File(widget.imageSettings.combined!).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _singleImage = frame.image;
      _isAutoFitScheduled = true;
    });
  }

  Future<void> _loadDoubleImageSize() async {
    final path = widget.imageSettings.original ?? widget.imageSettings.modified;
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _doubleImageSize = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    });
  }

  void _autoFitImage(BoxConstraints constraints) {
    Size? imageSize;
    if (widget.imageSettings.imageMode == ImageMode.single && _singleImage != null) {
      imageSize = Size(_singleImage!.width.toDouble(), _singleImage!.height.toDouble());
    } else if (widget.imageSettings.imageMode == ImageMode.double && _doubleImageSize != null) {
      imageSize = _doubleImageSize;
    } else {
      return;
    }

    if (imageSize == null) return;

    final imageWidth = imageSize.width;
    final imageHeight = imageSize.height;
    final isDouble = widget.imageSettings.imageMode == ImageMode.double;
    final viewWidth = isDouble ? (constraints.maxWidth - 2.0) / 2.0 : constraints.maxWidth;
    final viewHeight = constraints.maxHeight;

    if (imageWidth <= 0 || imageHeight <= 0 || viewWidth <= 0 || viewHeight <= 0) return;

    final scale = min(viewWidth / imageWidth, viewHeight / imageHeight);
    final dx = (viewWidth - imageWidth * scale) / 2.0;
    final dy = (viewHeight - imageHeight * scale) / 2.0;

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }
  
  HandlePosition? _hittestHandles(Offset position, String? selectedId) {
    if (selectedId == null) return null;
    try {
      final diff = widget.differences.firstWhere((d) => d.id == selectedId);
      final scale = _transformationController.value.getMaxScaleOnAxis();
      for (final handle in HandlePosition.values) {
        final handleRect = getHandleRect(diff.position, handle, scale);
        if (handleRect.contains(position)) {
          return handle;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }


  String? _hittest(Offset position) {
    // 反向迭代以正确选择绘制在顶部的项目。
    for (final diff in widget.differences.reversed) {
      if (diff.position.contains(position)) {
        return diff.id;
      }
    }
    return null;
  }

  void _handleRightClick(PointerEvent event) {
    // 使用位与（AND）检查次要按钮。这至关重要
    // 因为当按下多个按钮时（例如，在按下主按钮拖动时单击了次要按钮），event.buttons 是一个位掩码。
    if (event.kind == ui.PointerDeviceKind.mouse &&
        (event.buttons & kSecondaryMouseButton) != 0) {
      if (_startPan != null) {
        setState(() {
          _startPan = null;
          _endPan = null;
          _resizingHandle = null;
          _movingDifference = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (_isAutoFitScheduled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _autoFitImage(constraints);
        });
        _isAutoFitScheduled = false;
      }

      final editorCubit = context.read<EditorCubit>();
      final editorState = context.watch<EditorCubit>().state;

      return Stack(
        fit: StackFit.expand,
        children: [
          _buildCanvas(editorState, constraints, editorCubit),
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
               _handleRightClick(event);
              final scenePos = _transformationController.toScene(event.localPosition);
              if (editorState.selectedTool == DrawingTool.select) {
                final handle = _hittestHandles(scenePos, editorState.selectedDifferenceId);
                if (handle != null) {
                  setState(() {
                    _resizingHandle = handle;
                    _startPan = scenePos;
                    _initialResizeRect = widget.differences.firstWhere((d) => d.id == editorState.selectedDifferenceId).position;
                  });
                  return;
                }
              }
            },
            onPointerMove: _handleRightClick, 
            onPointerUp: (event) {
              if (editorState.selectedTool == DrawingTool.select && _resizingHandle == null) {
                final viewportPos = _getCorrectedLocalPosition(event.localPosition, constraints);
                final scenePos = _transformationController.toScene(viewportPos);
                final selectedId = _hittest(scenePos);
                editorCubit.selectDifference(selectedId);
              }
            },
          ),
        ],
      );
    });
  }

  Offset _getCorrectedLocalPosition(Offset globalPosition, BoxConstraints constraints) {
    if (widget.imageSettings.imageMode != ImageMode.double) {
      return globalPosition;
    }
    const dividerWidth = 2.0;
    final sideViewWidth = (constraints.maxWidth - dividerWidth) / 2.0;

    if (globalPosition.dx > sideViewWidth + dividerWidth) {
      return Offset(globalPosition.dx - sideViewWidth - dividerWidth, globalPosition.dy);
    } else {
      return globalPosition;
    }
  }
  
  Widget _buildCommonInteractiveViewer({
    required Widget child,
    required EditorState editorState,
    required BoxConstraints constraints,
    required EditorCubit editorCubit,
    required DifferencePainter foregroundPainter,
  }) {
    const maxScale = 10.0;
    const minScale = 0.1;
    final isInteractionDisabled = editorState.selectedTool != DrawingTool.pan;

    return InteractiveViewer(
      transformationController: _transformationController,
      constrained: false,
      panEnabled: !isInteractionDisabled,
      scaleEnabled: !isInteractionDisabled,
      maxScale: maxScale,
      minScale: minScale,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      onInteractionStart: (details) {
        final tool = editorState.selectedTool;
        if (tool == DrawingTool.pan || _resizingHandle != null) return;

        final viewportPos = _getCorrectedLocalPosition(details.localFocalPoint, constraints);
        final scenePos = _transformationController.toScene(viewportPos);

        if (tool == DrawingTool.circle || tool == DrawingTool.rectangle) {
          setState(() => _startPan = scenePos);
        } else if (tool == DrawingTool.select && editorState.selectedDifferenceId != null) {
          final hitId = _hittest(scenePos);
          if (hitId != null && hitId == editorState.selectedDifferenceId) {
            try {
              _movingDifference = widget.differences.firstWhere((d) => d.id == hitId);
              setState(() => _startPan = scenePos);
            } catch (e) {
              _movingDifference = null;
            }
          }
        }
      },
      onInteractionUpdate: (details) {
        if (_startPan == null || editorState.selectedTool == DrawingTool.pan) return;
        if (details.pointerCount > 1) return;

        final tool = editorState.selectedTool;
        final viewportPos = _getCorrectedLocalPosition(details.localFocalPoint, constraints);
        final scenePos = _transformationController.toScene(viewportPos);

        if (_resizingHandle != null) {
          // 调整大小的逻辑
          final initialRect = _initialResizeRect!;
          double left = initialRect.left;
          double top = initialRect.top;
          double right = initialRect.right;
          double bottom = initialRect.bottom;

          switch (_resizingHandle!) {
            case HandlePosition.topLeft:
              left = scenePos.dx;
              top = scenePos.dy;
              break;
            case HandlePosition.topCenter:
              top = scenePos.dy;
              break;
            case HandlePosition.topRight:
              right = scenePos.dx;
              top = scenePos.dy;
              break;
            case HandlePosition.centerLeft:
              left = scenePos.dx;
              break;
            case HandlePosition.centerRight:
              right = scenePos.dx;
              break;
            case HandlePosition.bottomLeft:
              left = scenePos.dx;
              bottom = scenePos.dy;
              break;
            case HandlePosition.bottomCenter:
              bottom = scenePos.dy;
              break;
            case HandlePosition.bottomRight:
              right = scenePos.dx;
              bottom = scenePos.dy;
              break;
          }
          final newRect = Rect.fromLTRB(left, top, right, bottom);
          final selectedDiff = widget.differences.firstWhere((d) => d.id == editorState.selectedDifferenceId);
          editorCubit.updateDifference(selectedDiff.copyWith(position: newRect));

        } else if (tool == DrawingTool.circle || tool == DrawingTool.rectangle) {
          setState(() => _endPan = scenePos);
        } else if (tool == DrawingTool.select && _movingDifference != null) {
          final delta = scenePos - _startPan!;
          editorCubit.updateDifference(_movingDifference!.copyWith(position: _movingDifference!.position.shift(delta)));
        }
      },
      onInteractionEnd: (details) {
        final tool = editorState.selectedTool;
        if (_resizingHandle != null) {
          // 完成调整大小
        } else if ((tool == DrawingTool.circle || tool == DrawingTool.rectangle) && _startPan != null && _endPan != null) {
          final rect = Rect.fromPoints(_startPan!, _endPan!);
          editorCubit.addDifference(diff_model.Difference(
            id: _uuid.v4(),
            position: rect,
            shape: tool == DrawingTool.circle ? 'circle' : 'rectangle',
          ));
        }
        
        setState(() {
          _startPan = null;
          _endPan = null;
          _movingDifference = null;
          _resizingHandle = null;
          _initialResizeRect = null;
        });
      },
      child: CustomPaint(
        foregroundPainter: foregroundPainter,
        child: child,
      ),
    );
  }

  Widget _buildCanvas(EditorState editorState, BoxConstraints constraints, EditorCubit editorCubit) {
    final selectedDifferenceId = editorState.selectedDifferenceId;
    final currentRect = _startPan != null && _endPan != null && editorState.selectedTool != DrawingTool.select
        ? Rect.fromPoints(_startPan!, _endPan!)
        : null;
    final scale = _transformationController.value.getMaxScaleOnAxis();

    final foregroundPainter = DifferencePainter(
      differences: widget.differences,
      selectedId: selectedDifferenceId,
      currentRect: currentRect,
      scale: scale,
      imageSettings: widget.imageSettings,
    );

    if (widget.imageSettings.imageMode == ImageMode.double) {
      return Row(
        children: [
          Expanded(
            child: _buildCommonInteractiveViewer(
              child: widget.imageSettings.original != null ? Image.file(File(widget.imageSettings.original!)) : Container(),
              editorState: editorState,
              constraints: constraints,
              editorCubit: editorCubit,
              foregroundPainter: foregroundPainter,
            ),
          ),
          const VerticalDivider(width: 2, color: Colors.black),
          Expanded(
            child: _buildCommonInteractiveViewer(
              child: widget.imageSettings.modified != null ? Image.file(File(widget.imageSettings.modified!)) : Container(),
              editorState: editorState,
              constraints: constraints,
              editorCubit: editorCubit,
              foregroundPainter: foregroundPainter,
            ),
          ),
        ],
      );
    } else {
      // 单图模式
      return _buildCommonInteractiveViewer(
        child: _buildBaseImage(),
        editorState: editorState,
        constraints: constraints,
        editorCubit: editorCubit,
        foregroundPainter: foregroundPainter,
      );
    }
  }

  Widget _buildBaseImage() {
    if (_singleImage != null) {
      return CustomPaint(
        size: Size(_singleImage!.width.toDouble(), _singleImage!.height.toDouble()),
        painter: SplitImagePainter(
          image: _singleImage!,
          splitMode: widget.imageSettings.splitMode!,
          splitRatio: widget.imageSettings.splitRatio!,
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
