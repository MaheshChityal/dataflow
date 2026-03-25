import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../controllers/pipeline_controller.dart';

class StatusBar extends StatelessWidget {
  const StatusBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<PipelineController>(
      builder: (context, ctrl, _) {
        final hasSrc = ctrl.nodes.any((n) => n.type.isSource);
        final hasJoin = ctrl.nodes.any((n) => n.type == NodeType.join);
        return Container(
          height: 26,
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              _dot(AppColors.green), const SizedBox(width: 5),
              Text('${ctrl.nodes.length} nodes', style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
              const SizedBox(width: 16),
              _dot(AppColors.blue), const SizedBox(width: 5),
              Text('${ctrl.edges.length} connections', style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
              const SizedBox(width: 16),
              _dot(AppColors.amber), const SizedBox(width: 5),
              Text(hasSrc && hasJoin ? '✓ Pipeline configured' : 'Add sources & join', style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _dot(Color c) => Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: c));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FILE: main.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━