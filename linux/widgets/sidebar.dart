import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../models/pipeline_config.dart';
import '../controllers/pipeline_controller.dart';

class Sidebar extends StatelessWidget {
  const Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.surface,
      child: Consumer<PipelineController>(
        builder: (context, ctrl, _) {
          final templates = PipelineConfig.templatesByDept[ctrl.sidebarDept] ?? [];
          final canAdd = ctrl.canAddSource;

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                child: const Text('PIPELINE CONFIG', style: AppTextStyles.sectionLabel),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    const Text('TEMPLATE SELECTION', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 6),

                    // Department
                    const Text('Department', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 4),
                    _sidebarDropdown(
                      value: ctrl.sidebarDept.isEmpty ? null : ctrl.sidebarDept,
                      hint: '— Select Dept —',
                      items: PipelineConfig.templatesByDept.keys.toList(),
                      onChanged: (v) => ctrl.setSidebarDept(v ?? ''),
                    ),
                    const SizedBox(height: 8),

                    // Template
                    const Text('Template', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 4),
                    _sidebarDropdown(
                      value: templates.contains(ctrl.sidebarTemplate) ? ctrl.sidebarTemplate : null,
                      hint: '— Select Template —',
                      items: templates,
                      onChanged: (v) => ctrl.setSidebarTemplate(v ?? ''),
                    ),
                    const SizedBox(height: 8),

                    // Required count
                    const Text('Required Input Sources', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppColors.border2),
                        color: AppColors.surface2,
                      ),
                      child: Text(
                        ctrl.requiredSourceCount > 0 ? '${ctrl.requiredSourceCount}' : 'Select template first',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ctrl.requiredSourceCount > 0 ? AppColors.amber : AppColors.textMuted,
                          fontWeight: FontWeight.w700, fontSize: 13,
                        ),
                      ),
                    ),

                    // Source counter badge
                    if (ctrl.requiredSourceCount > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ctrl.sourceNodesOnCanvas >= ctrl.requiredSourceCount
                                ? AppColors.green.withOpacity(0.3)
                                : AppColors.amber.withOpacity(0.3),
                          ),
                          color: ctrl.sourceNodesOnCanvas >= ctrl.requiredSourceCount
                              ? AppColors.green.withOpacity(0.06)
                              : AppColors.amber.withOpacity(0.06),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sources Added', style: TextStyle(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.w700)),
                            Text(
                              '${ctrl.sourceNodesOnCanvas} / ${ctrl.requiredSourceCount}',
                              style: TextStyle(
                                color: ctrl.sourceNodesOnCanvas >= ctrl.requiredSourceCount ? AppColors.green : AppColors.amber,
                                fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Text('SOURCE TYPES', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 6),
                    PaletteItem(type: NodeType.fc, enabled: canAdd && ctrl.requiredSourceCount > 0),
                    PaletteItem(type: NodeType.laser, enabled: canAdd && ctrl.requiredSourceCount > 0),
                    PaletteItem(type: NodeType.manual, enabled: canAdd && ctrl.requiredSourceCount > 0),
                    PaletteItem(type: NodeType.api, enabled: canAdd && ctrl.requiredSourceCount > 0),

                    const SizedBox(height: 8),
                    const Text('OPERATIONS', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 6),
                    PaletteItem(type: NodeType.join, enabled: true),
                    PaletteItem(type: NodeType.output, enabled: true),

                    const SizedBox(height: 12),
                    const Text('INSTRUCTIONS', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 4),
                    const Text(
                      '1. Select Department → Template\n2. Required sources auto-fills\n3. Drag that many source types\n4. Connect via ports → Join → Output',
                      style: TextStyle(color: AppColors.textDim, fontSize: 10.5, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sidebarDropdown({String? value, required String hint, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border2),
        color: AppColors.surface2,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : null,
          hint: Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          dropdownColor: AppColors.surface2,
          style: const TextStyle(fontSize: 12, color: AppColors.text),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Sidebar palette item — Draggable to canvas
class PaletteItem extends StatelessWidget {
  final NodeType type;
  final bool enabled;
  const PaletteItem({required this.type, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = type.color;

    Widget content() => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        color: AppColors.surface2,
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: color.withOpacity(0.15)),
          child: Icon(type.icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type.label, style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(type.subtitle, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
          ],
        )),
      ]),
    );

    if (!enabled) {
      return Opacity(opacity: 0.3, child: content());
    }

    return Draggable<NodeType>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.blue),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(type.icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(type.label, style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: content()),
      child: content(),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONFIG PANEL (same as HTML .right-panel)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
