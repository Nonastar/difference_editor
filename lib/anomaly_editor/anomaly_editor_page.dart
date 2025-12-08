import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/anomaly_editor_cubit.dart';
import 'bloc/anomaly_editor_state.dart';
import 'widgets/anomaly_canvas_view.dart';
import 'widgets/anomaly_list_panel.dart';

class AnomalyEditorPage extends StatelessWidget {
  const AnomalyEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnomalyEditorCubit(),
      child: const AnomalyEditorView(),
    );
  }
}

class AnomalyEditorView extends StatelessWidget {
  const AnomalyEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('异常编辑器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            tooltip: '导入大图',
            onPressed: () => _importBackgroundImage(context),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '导出 JSON',
            onPressed: () async {
              final path = await context.read<AnomalyEditorCubit>().saveAnomaliesToJson();
              if (path != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('保存成功: $path')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('保存失败')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.pan_tool),
            tooltip: '平移',
            onPressed: () => context.read<AnomalyEditorCubit>().setEditMode(EditMode.pan),
          ),
           IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: '选择',
            onPressed: () => context.read<AnomalyEditorCubit>().setEditMode(EditMode.select),
          ),
        ],
      ),
      body: BlocBuilder<AnomalyEditorCubit, AnomalyEditorState>(
        builder: (context, state) {
          if (state.status == EditorStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == EditorStatus.failure) {
            return Center(child: Text('加载失败: ${state.errorMessage}'));
          }

          return Row(
            children: [
              const Expanded(
                flex: 3,
                child: AnomalyCanvasView(),
              ),
              const VerticalDivider(width: 1),
              SizedBox(
                 width: 300,
                child: AnomalyListPanel(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _importBackgroundImage(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      context.read<AnomalyEditorCubit>().loadBackgroundImage(result.files.single.path!);
    }
  }
}
