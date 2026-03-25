import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/pipeline_models.dart';
import '../../controllers/pipeline_controller.dart';

class SourceNodeBody extends StatelessWidget {
  final PipelineNode node;
  const SourceNodeBody({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final color = node.type.color;
    final hasCols = node.selectedCols.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withOpacity(0.12),
                ),
                child: Icon(node.type.icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.name, style: AppTextStyles.nodeName, overflow: TextOverflow.ellipsis),
                    Text('${node.type.name.toUpperCase()} · ${node.department}', style: AppTextStyles.nodeSubtitle),
                  ],
                ),
              ),
              InkWell(
                onTap: () => context.read<PipelineController>().selectNode(node.id),
                child: const Icon(Icons.settings, color: AppColors.textDim, size: 16),
              ),
            ],
          ),
        ),

        // Body stats
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            children: [
              _statRow('Template', node.template.isNotEmpty ? node.template : '—'),
              _statRow('Department', node.department),
              _statBadgeRow('Columns', hasCols ? '${node.cols.length} cols' : 'No file',
                  hasCols ? AppColors.blue : AppColors.amber),
              if (node.rows.isNotEmpty) _statRow('Rows', '${node.rows.length}'),
            ],
          ),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => context.read<PipelineController>().selectNode(node.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppColors.blue.withOpacity(0.1),
                    border: Border.all(color: AppColors.blue.withOpacity(0.2)),
                  ),
                  child: const Text('Configure →', style: TextStyle(color: AppColors.blue, fontSize: 10.5, fontWeight: FontWeight.w600)),
                ),
              ),
              InkWell(
                onTap: () => context.read<PipelineController>().deleteNode(node.id),
                child: const Text('🗑', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.statLabel),
          Flexible(child: Text(value, style: AppTextStyles.statValue, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _statBadgeRow(String label, String badge, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.statLabel),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(badge, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// JOIN NODE BODY (same as HTML join-node card with inline mapping)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━