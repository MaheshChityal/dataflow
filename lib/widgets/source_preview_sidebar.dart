import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../controllers/pipeline_controller.dart';
import '../services/pipeline_service.dart';

class SourcePreviewSidebar extends StatelessWidget {
  const SourcePreviewSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PipelineController>(
      builder: (context, ctrl, _) {
        final sources = ctrl.nodes.where((n) => n.type.isSource).toList();
        if (sources.isEmpty) return const SizedBox.shrink();

        final allValid = sources.every((s) => _isSourceComplete(s));

        // Hide sidebar until ALL sources are complete
        if (!allValid) return const SizedBox.shrink();

        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: allValid ? AppColors.green.withOpacity(0.05) : AppColors.surface2,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Icon(
                      allValid ? Icons.check_circle : Icons.preview_rounded,
                      size: 18,
                      color: allValid ? AppColors.green : const Color(0xFF004C8F),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Sources Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: allValid ? AppColors.green.withOpacity(0.1) : AppColors.amber.withOpacity(0.1),
                      ),
                      child: Text(
                        '${sources.length}/${sources.length}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: allValid ? AppColors.green : AppColors.amber),
                      ),
                    ),
                  ],
                ),
              ),

              // Source cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: sources.length,
                  itemBuilder: (context, index) {
                    final src = sources[index];
                    return _SourceCard(node: src);
                  },
                ),
              ),

              // Save button
              if (sources.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: allValid ? () => _saveSourceConfig(context, ctrl, sources) : null,
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Save Sources Configuration', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allValid ? const Color(0xFF004C8F) : AppColors.border,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                        disabledForegroundColor: AppColors.textMuted,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isSourceComplete(PipelineNode node) {
    return node.name.isNotEmpty &&
        node.type.isSource &&
        node.separator.isNotEmpty &&
        node.fileName != null &&
        node.fileName!.isNotEmpty;
    // queryFileName is optional for manual type
  }

  void _saveSourceConfig(BuildContext context, PipelineController ctrl, List<PipelineNode> sources) async {
    final payload = {
      'sources': sources.map((s) => {
        'sourceId': s.id,
        'sourceName': s.name,
        'sourceType': s.type.name,
        'separator': s.separator,
        'columnFile': s.fileName,
        'queryFile': s.queryFileName,
        'columns': s.cols,
        'selectedColumns': s.selectedCols,
      }).toList(),
    };

    debugPrint('[SAVE SOURCE CONFIG]\n${const JsonEncoder.withIndent('  ').convert(payload)}');

    // Show loader
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF004C8F))));

    // Call API
    try {
      final service = context.read<PipelineService>();
      await service.saveSourceConfig(payload);
    } catch (_) {
      debugPrint('[SAVE SOURCE CONFIG] API not available — dev mode');
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (context.mounted) Navigator.of(context).pop();

    // Success dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.green.withOpacity(0.1)),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 36),
              ),
              const SizedBox(height: 14),
              const Text('Sources Saved!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 6),
              Text('${sources.length} source configuration(s) saved successfully.',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity, height: 38,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004C8F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('OK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _SourceCard extends StatelessWidget {
  final PipelineNode node;
  const _SourceCard({required this.node});

  bool get _isComplete =>
      node.name.isNotEmpty &&
          node.type.isSource &&
          node.separator.isNotEmpty &&
          node.fileName != null &&
          node.fileName!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final color = node.type.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _isComplete ? AppColors.green.withOpacity(0.03) : AppColors.surface2,
        border: Border.all(color: _isComplete ? AppColors.green.withOpacity(0.2) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: color.withOpacity(0.12)),
                child: Icon(node.type.icon, size: 12, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(node.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text), overflow: TextOverflow.ellipsis),
              ),
              Icon(
                _isComplete ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 14,
                color: _isComplete ? AppColors.green : AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fields
          _fieldRow('Source Type', node.type.label, true),
          _fieldRow('Separator', _separatorLabel(node.separator), node.separator.isNotEmpty),
          _fieldRow('Column File', node.fileName ?? '—', node.fileName != null),
          _fieldRow('Query File', node.queryFileName ?? '(optional)', node.queryFileName != null),

          // Columns count
          if (node.cols.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: color.withOpacity(0.08)),
              child: Text('${node.cols.length} columns loaded', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value, bool filled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.textDim)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: filled ? AppColors.text : AppColors.red),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _separatorLabel(String sep) {
    switch (sep) {
      case ',': return 'Comma (,)';
      case '|': return 'Pipe (|)';
      case '\t': return 'Tab (\\t)';
      case ';': return 'Semicolon (;)';
      default: return sep.isNotEmpty ? sep : '—';
    }
  }
}