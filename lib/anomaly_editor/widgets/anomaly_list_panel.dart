import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/anomaly_editor_cubit.dart';
import '../bloc/anomaly_editor_state.dart';
import '../models/anomaly_point.dart';

class AnomalyListPanel extends StatelessWidget {
  const AnomalyListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnomalyEditorCubit, AnomalyEditorState>(
      builder: (context, state) {
        final anomalies = state.data?.anomalies ?? [];

        return Scaffold(
          appBar: _buildAppBar(context, state, anomalies.length),
          body: ListView.builder(
            itemCount: anomalies.length,
            itemBuilder: (context, index) {
              final anomaly = anomalies[index];
              return _AnomalyListItem(
                anomaly: anomaly,
                isSelected: anomaly.id == state.selectedAnomalyId,
                onTap: () => context.read<AnomalyEditorCubit>().selectAnomaly(anomaly.id),
              );
            },
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, AnomalyEditorState state, int count) {
    return AppBar(
      title: Text('异常列表 ($count)'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: '删除选中',
          onPressed: state.selectedAnomalyId != null
              ? () => context.read<AnomalyEditorCubit>().deleteSelectedAnomaly()
              : null,
        ),
      ],
    );
  }
}

class _AnomalyListItem extends StatelessWidget {
  const _AnomalyListItem({
    required this.anomaly,
    required this.isSelected,
    required this.onTap,
  });

  final AnomalyPoint anomaly;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.2),
      leading: SizedBox(
        width: 60,
        height: 60,
        child: Image.file(File(anomaly.imagePath), fit: BoxFit.cover),
      ),
      title: Text(anomaly.imageName, overflow: TextOverflow.ellipsis),
      subtitle: Text(
          'Pos: (${anomaly.position.dx.toStringAsFixed(1)}, ${anomaly.position.dy.toStringAsFixed(1)})\n'
          'Size: (${anomaly.size.width.toStringAsFixed(1)}, ${anomaly.size.height.toStringAsFixed(1)})'),
      onTap: onTap,
    );
  }
}
