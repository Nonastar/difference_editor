import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/editor_cubit.dart';
import 'bloc/editor_state.dart';
import 'models/difference.dart';
import 'models/image_settings.dart';
import 'widgets/canvas_view.dart';
import 'widgets/difference_editor.dart';

class DifferenceEditorPage extends StatelessWidget {
  const DifferenceEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (context) => EditorCubit(), child: const DifferenceEditorView());
  }
}

class DifferenceEditorView extends StatelessWidget {
  const DifferenceEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find the Difference Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () {
              context.read<EditorCubit>().loadImage();
            },
            tooltip: 'Load Image(s)',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final path = await context.read<EditorCubit>().saveLevelToJson();
              if (path != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Level saved to $path')));
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save level')));
              }
            },
            tooltip: 'Save to JSON',
          ),
        ],
      ),
      body: BlocBuilder<EditorCubit, EditorState>(
        builder: (context, state) {
          return Row(
            children: [
              // Toolbar
              _buildToolbar(context, state),
              // Canvas Area
              Expanded(child: _buildCanvasArea(context, state)),
              // Properties Panel
              _buildPropertiesPanel(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, EditorState state) {
    return Container(
      width: 60,
      color: Colors.grey[200],
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.pan_tool_outlined),
            color: state.selectedTool == DrawingTool.pan ? Theme.of(context).primaryColor : null,
            onPressed: () => context.read<EditorCubit>().setTool(DrawingTool.pan),
            tooltip: 'Pan & Zoom',
          ),
          const Divider(),
          IconButton(
            icon: const Icon(Icons.mouse_outlined),
            color: state.selectedTool == DrawingTool.select ? Theme.of(context).primaryColor : null,
            onPressed: () => context.read<EditorCubit>().setTool(DrawingTool.select),
            tooltip: 'Select',
          ),
          const Divider(),
          IconButton(
            icon: const Icon(Icons.circle_outlined),
            color: state.selectedTool == DrawingTool.circle ? Theme.of(context).primaryColor : null,
            onPressed: () => context.read<EditorCubit>().setTool(DrawingTool.circle),
            tooltip: 'Draw Circle',
          ),
          IconButton(
            icon: const Icon(Icons.crop_square_outlined),
            color: state.selectedTool == DrawingTool.rectangle ? Theme.of(context).primaryColor : null,
            onPressed: () => context.read<EditorCubit>().setTool(DrawingTool.rectangle),
            tooltip: 'Draw Rectangle',
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea(BuildContext context, EditorState state) {
    if (state.status == EditorStatus.initial) {
      return const Center(child: Text('Please load an image to start.'));
    }
    if (state.status == EditorStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == EditorStatus.error) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }

    if (state.level?.images != null) {
      return CanvasView(imageSettings: state.level!.images, differences: state.level!.differences);
    }

    return const Center(child: Text('Something went wrong.'));
  }

  Widget _buildPropertiesPanel(BuildContext context, EditorState state) {
    Difference? selectedDifference;
    try {
      selectedDifference = state.level?.differences.firstWhere((d) => d.id == state.selectedDifferenceId);
    } catch (e) {
      selectedDifference = null;
    }

    return Container(
      width: 280, // Increased width for better layout
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always visible settings
          if (state.level?.images.imageMode == ImageMode.single) _buildImageSettings(context, state.level!.images),

          const Divider(),
          const Text('Differences List', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Differences List
          Expanded(flex: 2, child: _buildDifferencesList(context, state)),

          const Divider(),

          // Selected Difference Editor
          Expanded(
            flex: 3,
            child: selectedDifference != null
                ? DifferenceEditor(difference: selectedDifference)
                : const Center(child: Text('No difference selected')),
          ),
        ],
      ),
    );
  }

  Widget _buildDifferencesList(BuildContext context, EditorState state) {
    final differences = state.level?.differences ?? [];

    if (differences.isEmpty) {
      return const Center(child: Text('No differences added yet.'));
    }

    return ListView.builder(
      itemCount: differences.length,
      itemBuilder: (context, index) {
        final diff = differences[index];
        final isSelected = diff.id == state.selectedDifferenceId;
        return Card(
          color: isSelected ? Theme.of(context).primaryColorLight : null,
          child: ListTile(
            title: Text('ID: ${diff.id.substring(0, 8)}...'),
            subtitle: Text(
              'Pos: (${diff.position.left.toStringAsFixed(1)}, ${diff.position.top.toStringAsFixed(1)})\n'
              'Size: (${diff.position.width.toStringAsFixed(1)} x ${diff.position.height.toStringAsFixed(1)})',
            ),
            onTap: () {
              context.read<EditorCubit>().selectDifference(diff.id);
            },
            dense: true,
          ),
        );
      },
    );
  }

  Widget _buildImageSettings(BuildContext context, ImageSettings settings) {
    // Create controllers and initialize them to avoid issues during build.
    final offsetXController = TextEditingController(text: settings.offsetX.toString());
    final offsetYController = TextEditingController(text: settings.offsetY.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Single Image Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Split Mode:'),
            const SizedBox(width: 4),
            DropdownButton<SplitMode>(
              value: settings.splitMode,
              onChanged: (SplitMode? newValue) {
                if (newValue != null) {
                  final newSettings = settings.copyWith(splitMode: newValue);
                  context.read<EditorCubit>().updateImageSettings(newSettings);
                }
              },
              items: SplitMode.values.map<DropdownMenuItem<SplitMode>>((SplitMode value) {
                return DropdownMenuItem<SplitMode>(value: value, child: Text(value.toString().split('.').last));
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Split Ratio'),
            Slider(
              value: settings.splitRatio ?? 0.5,
              min: 0.1,
              max: 0.9,
              divisions: 8,
              label: (settings.splitRatio ?? 0.5).toStringAsFixed(2),
              onChanged: (double value) {
                final newSettings = settings.copyWith(splitRatio: value);
                context.read<EditorCubit>().updateImageSettings(newSettings);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Offset X'),
            const SizedBox(width: 4),
            Expanded(
              child: TextFormField(
                controller: offsetXController,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                onFieldSubmitted: (value) {
                  final double? val = double.tryParse(value);
                  if (val != null) {
                    context.read<EditorCubit>().updateImageSettings(settings.copyWith(offsetX: val));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('Y'),
            const SizedBox(width: 4),
            Expanded(
              child: TextFormField(
                controller: offsetYController,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                onFieldSubmitted: (value) {
                  final double? val = double.tryParse(value);
                  if (val != null) {
                    context.read<EditorCubit>().updateImageSettings(settings.copyWith(offsetY: val));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
