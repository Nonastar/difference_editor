import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math.dart' as vector;
import '../bloc/editor_cubit.dart';
import '../models/difference.dart';

class DifferenceEditor extends StatefulWidget {
  final Difference difference;

  const DifferenceEditor({super.key, required this.difference});

  @override
  State<DifferenceEditor> createState() => _DifferenceEditorState();
}

class _DifferenceEditorState extends State<DifferenceEditor> {
  late final TextEditingController _xController;
  late final TextEditingController _yController;
  late final TextEditingController _wController;
  late final TextEditingController _hController;

  @override
  void initState() {
    super.initState();
    _xController = TextEditingController();
    _yController = TextEditingController();
    _wController = TextEditingController();
    _hController = TextEditingController();
    _updateControllers(widget.difference);
  }

  @override
  void didUpdateWidget(DifferenceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.difference != oldWidget.difference) {
      _updateControllers(widget.difference);
    }
  }

  void _updateControllers(Difference difference) {
    _xController.text = difference.position.x.toStringAsFixed(2);
    _yController.text = difference.position.y.toStringAsFixed(2);
    _wController.text = difference.size.x.toStringAsFixed(2);
    _hController.text = difference.size.y.toStringAsFixed(2);
  }

  void _onValueChanged() {
    final x = double.tryParse(_xController.text) ?? widget.difference.position.x;
    final y = double.tryParse(_yController.text) ?? widget.difference.position.y;
    final w = double.tryParse(_wController.text) ?? widget.difference.size.x;
    final h = double.tryParse(_hController.text) ?? widget.difference.size.y;

    if (x != widget.difference.position.x ||
        y != widget.difference.position.y ||
        w != widget.difference.size.x ||
        h != widget.difference.size.y) {
      final newPosition = vector.Vector2(x, y);
      final newSize = vector.Vector2(w, h);
      context.read<EditorCubit>().updateDifference(widget.difference.copyWith(position: newPosition, size: newSize));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selected Difference', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField(_xController, _yController, "Pos:"),
            const SizedBox(height: 8),
            _buildTextField(_wController, _hController, "Size:"),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                onPressed: () {
                  context.read<EditorCubit>().deleteSelectedDifference();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController xController, TextEditingController yController, String label) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            SizedBox(width: 40, child: Text(label)),
            Expanded(
              child: TextFormField(
                controller: xController,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                onEditingComplete: _onValueChanged,
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              child: TextFormField(
                controller: yController,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                onEditingComplete: _onValueChanged,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    _wController.dispose();
    _hController.dispose();
    super.dispose();
  }
}
