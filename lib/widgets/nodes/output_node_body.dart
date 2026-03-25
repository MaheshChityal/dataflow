import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/pipeline_models.dart';
import '../../controllers/pipeline_controller.dart';

class OutputNodeBody extends StatelessWidget {
  final PipelineNode node;
  const OutputNodeBody({super.key, required this.node});

  static const _operators = ['=', '!=', '>', '<', '>=', '<=', 'contains', 'starts with'];

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PipelineController>();
    final result = ctrl.getOutputResult(node.id);
    final diagnosis = result == null ? ctrl.diagnoseOutputIssue(node.id) : null;

    // ── Compute allCols from connected sources (independent of result) ──
    List<String> allCols = [];
    if (result != null) {
      allCols = List<String>.from(result['allCols'] ?? result['cols']);
    } else {
      // Get columns from connected JOIN's sources or direct source
      final inEdge = ctrl.edges.where((e) => e.toNodeId == node.id).toList();
      if (inEdge.isNotEmpty) {
        final fromNode = ctrl.findNode(inEdge.first.fromNodeId);
        if (fromNode != null && fromNode.type == NodeType.join) {
          // Collect cols from all sources connected to this JOIN
          final joinInEdges = ctrl.edges.where((e) => e.toNodeId == fromNode.id).toList();
          final seen = <String>{};
          for (final je in joinInEdges) {
            final src = ctrl.findNode(je.fromNodeId);
            if (src != null) {
              for (final c in src.cols) {
                if (seen.add(c)) allCols.add(c);
              }
            }
          }
        } else if (fromNode != null && fromNode.type.isSource) {
          allCols = List<String>.from(fromNode.cols);
        }
      }
      // Auto-populate outputSelectedCols first time
      if (node.outputSelectedCols.isEmpty && allCols.isNotEmpty) {
        node.outputSelectedCols = List<String>.from(allCols);
      }
    }

    final hasConnection = ctrl.edges.any((e) => e.toNodeId == node.id);
    final hasColumns = allCols.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: AppColors.green.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.green.withOpacity(0.15)),
              child: const Icon(Icons.output_rounded, color: AppColors.green, size: 14),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Output', style: AppTextStyles.nodeName),
                Text('Final Report', style: AppTextStyles.nodeSubtitle),
              ],
            )),
            InkWell(
              onTap: () => ctrl.deleteNode(node.id),
              child: Icon(Icons.delete_outline, color: AppColors.textDim.withOpacity(0.6), size: 16),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Format chips ──
              Wrap(spacing: 4, children: ['csv', 'xlsx', 'json', 'pipe'].map((f) {
                final active = f == node.outputFormat;
                return InkWell(
                  onTap: () => ctrl.setOutputFormat(node.id, f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: active ? AppColors.green : Colors.transparent,
                      border: Border.all(color: active ? AppColors.green : AppColors.border2),
                    ),
                    child: Text(f.toUpperCase(), style: TextStyle(color: active ? Colors.white : AppColors.textDim, fontSize: 9.5, fontWeight: FontWeight.w700)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 6),
              Text('📁 output_report.${node.outputFormat}', style: const TextStyle(color: AppColors.textDim, fontSize: 10)),

              // ── Submit Data Format button ──
              const SizedBox(height: 8),
              InkWell(
                onTap: (hasConnection && hasColumns) ? () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.green)),
                  );
                  await Future.delayed(const Duration(milliseconds: 800));
                  if (context.mounted) Navigator.of(context).pop();

                  debugPrint('SUBMIT FORMAT: ${node.outputFormat.toUpperCase()}');

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
                              width: 60, height: 60,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.green.withOpacity(0.15)),
                              child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 40),
                            ),
                            const SizedBox(height: 16),
                            const Text('Format Submitted!', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(
                              'Output format ${node.outputFormat.toUpperCase()} submitted successfully.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.surface2),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.description_outlined, size: 16, color: AppColors.green),
                                const SizedBox(width: 8),
                                Text('output_report.${node.outputFormat}', style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.green),
                                child: const Center(child: Text('Done', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                } : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: (hasConnection && hasColumns)
                        ? null
                        : AppColors.surface2,
                    gradient: (hasConnection && hasColumns)
                        ? LinearGradient(colors: [AppColors.green, AppColors.green.withOpacity(0.8)])
                        : null,
                    border: (hasConnection && hasColumns)
                        ? null
                        : Border.all(color: AppColors.border2),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.send_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Submit Data Format', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),

              // Diagnosis shown when no columns available
              if (diagnosis != null && !hasColumns) ...[
                const SizedBox(height: 6),
                Text('⚠ $diagnosis', style: const TextStyle(color: AppColors.amber, fontSize: 10)),
              ],

              // ══════════════════════════════════════════════
              // Config sections — show when connected and columns available
              // ══════════════════════════════════════════════
              if (hasConnection && hasColumns) ...[
                const SizedBox(height: 10),

                // ── 1. SELECT COLUMNS ──
                _sectionHeader('SELECT COLUMNS', Icons.view_column_rounded),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4, runSpacing: 4,
                  children: allCols.map((c) {
                    final sel = node.outputSelectedCols.contains(c);
                    return InkWell(
                      onTap: () => ctrl.toggleOutputColumn(node.id, c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: sel ? AppColors.green.withOpacity(0.15) : AppColors.surface2,
                          border: Border.all(color: sel ? AppColors.green : AppColors.border2),
                        ),
                        child: Text(c, style: TextStyle(
                          color: sel ? AppColors.green : AppColors.textDim,
                          fontSize: 9, fontWeight: FontWeight.w600, fontFamily: 'monospace',
                        )),
                      ),
                    );
                  }).toList(),
                ),

                // ── 2. COLUMN ALIASES ──
                const SizedBox(height: 10),
                _sectionHeader('RENAME COLUMNS', Icons.edit_rounded),
                const SizedBox(height: 4),
                ...node.outputSelectedCols.where((c) => allCols.contains(c)).map((col) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      SizedBox(
                        width: 90,
                        child: Text(col, style: const TextStyle(color: AppColors.textDim, fontSize: 9, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                      ),
                      const Text(' → ', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      Expanded(
                        child: SizedBox(
                          height: 26,
                          child: TextField(
                            controller: TextEditingController(text: node.columnAliases[col] ?? ''),
                            onChanged: (v) => ctrl.setColumnAlias(node.id, col, v),
                            style: const TextStyle(color: AppColors.text, fontSize: 10, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              hintText: col,
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 10),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: AppColors.border2)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: AppColors.border2)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: AppColors.green)),
                              filled: true, fillColor: AppColors.surface2,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  );
                }),

                // ── 3. FILTERS (WHERE) ──
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _sectionHeader('FILTERS', Icons.filter_alt_rounded)),
                  InkWell(
                    onTap: () => ctrl.addOutputFilter(node.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border2)),
                      child: const Text('+ Add', style: TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                ...node.filters.asMap().entries.map((e) {
                  final idx = e.key;
                  final f = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: AppColors.surface2, border: Border.all(color: AppColors.border2)),
                    child: Row(children: [
                      // Column
                      Expanded(child: _miniFilterDrop(allCols, f.column.isEmpty ? null : f.column, (v) => ctrl.updateOutputFilter(node.id, idx, column: v))),
                      const SizedBox(width: 4),
                      // Operator
                      SizedBox(width: 70, child: _miniFilterDrop(_operators, f.operator, (v) => ctrl.updateOutputFilter(node.id, idx, operator: v))),
                      const SizedBox(width: 4),
                      // Value
                      Expanded(
                        child: SizedBox(
                          height: 26,
                          child: TextField(
                            controller: TextEditingController(text: f.value),
                            onChanged: (v) => ctrl.updateOutputFilter(node.id, idx, value: v),
                            style: const TextStyle(color: AppColors.text, fontSize: 10),
                            decoration: InputDecoration(
                              hintText: 'value',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 10),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: AppColors.border2)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: AppColors.border2)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: AppColors.amber)),
                              filled: true, fillColor: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(onTap: () => ctrl.removeOutputFilter(node.id, idx), child: const Icon(Icons.close, size: 14, color: AppColors.textDim)),
                    ]),
                  );
                }),

                // ── 4. SORTING (ORDER BY) ──
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _sectionHeader('SORT BY', Icons.sort_rounded)),
                  InkWell(
                    onTap: () => ctrl.addOutputSort(node.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border2)),
                      child: const Text('+ Add', style: TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                ...node.sortRules.asMap().entries.map((e) {
                  final idx = e.key;
                  final s = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: AppColors.surface2, border: Border.all(color: AppColors.border2)),
                    child: Row(children: [
                      Expanded(child: _miniFilterDrop(allCols, s.column.isEmpty ? null : s.column, (v) => ctrl.updateOutputSort(node.id, idx, column: v))),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => ctrl.updateOutputSort(node.id, idx, ascending: !s.ascending),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: AppColors.border, border: Border.all(color: AppColors.border2)),
                          child: Text(s.ascending ? 'ASC ↑' : 'DESC ↓', style: const TextStyle(color: AppColors.text, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(onTap: () => ctrl.removeOutputSort(node.id, idx), child: const Icon(Icons.close, size: 14, color: AppColors.textDim)),
                    ]),
                  );
                }),

                // ── RESULT TABLE (only when join produces data) ──
                if (result != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: AppColors.green.withOpacity(0.06),
                      border: Border.all(color: AppColors.green.withOpacity(0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '✓ ${(result['rows'] as List).length} rows × ${(result['cols'] as List).length} columns',
                        style: const TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      _ResultTableWidget(result: result),
                    ]),
                  ),
                ] else if (diagnosis != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: AppColors.amber.withOpacity(0.06),
                      border: Border.all(color: AppColors.amber.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.amber),
                      const SizedBox(width: 6),
                      Expanded(child: Text(diagnosis, style: const TextStyle(color: AppColors.amber, fontSize: 10))),
                    ]),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 12, color: AppColors.textDim),
      const SizedBox(width: 4),
      Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textDim, letterSpacing: 0.5)),
    ]);
  }

  Widget _miniFilterDrop(List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.border2),
        color: AppColors.border,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true, isDense: true,
          value: items.contains(value) ? value : null,
          hint: const Text('--', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
          dropdownColor: AppColors.surface2,
          style: const TextStyle(fontSize: 9.5, color: AppColors.text, fontFamily: 'monospace', fontWeight: FontWeight.w600),
          icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textDim),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ResultTableWidget extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultTableWidget({required this.result});

  @override
  Widget build(BuildContext context) {
    final cols = List<String>.from(result['cols']);
    final rows = List<Map<String, dynamic>>.from(result['rows']);
    final display = rows.take(8).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 500),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.border.withOpacity(0.5), width: 0.5),
            ),
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(color: AppColors.surface2),
                children: cols.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text(c, style: AppTextStyles.tableHeader),
                )).toList(),
              ),
              // Data rows
              ...display.map((r) => TableRow(
                children: cols.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('${r[c] ?? '—'}', style: AppTextStyles.tableCell),
                )).toList(),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
