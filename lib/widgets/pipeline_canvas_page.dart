import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../controllers/pipeline_controller.dart';
import 'edge_painter.dart';
import 'nodes/source_node_body.dart';
import 'nodes/join_node_body.dart';
import 'top_bar.dart';
import 'sidebar.dart';
import 'config_panel.dart';
import 'source_preview_sidebar.dart';
import 'status_bar.dart';

class PipelineCanvasPage extends StatefulWidget {
  const PipelineCanvasPage({super.key});

  @override
  State<PipelineCanvasPage> createState() => _PipelineCanvasPageState();
}

class _PipelineCanvasPageState extends State<PipelineCanvasPage> {
  final _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    // Empty canvas — user drags sources from sidebar
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(),
        Expanded(
          child: Row(
            children: [
              const Sidebar(),
              Expanded(child: _buildCanvas()),
              const ConfigPanel(),
              const SourcePreviewSidebar(),
            ],
          ),
        ),
        const StatusBar(),
      ],
    );
  }

  Widget _buildCanvas() {
    return Consumer<PipelineController>(
      builder: (context, ctrl, _) {
        final edgePainter = EdgePainter(ctrl);
        final isConnecting = ctrl.portDragFromNodeId != null;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // ── 1. Canvas ──
                DragTarget<NodeType>(
                  onAcceptWithDetails: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final localPos = box.globalToLocal(details.offset);
                    final inv = Matrix4.inverted(_transformCtrl.value);
                    ctrl.addNode(details.data, MatrixUtils.transformPoint(inv, localPos));
                  },
                  builder: (ctx2, _, __) {
                    return GestureDetector(
                      onTapDown: isConnecting ? null : (d) {
                        final box = ctx2.findRenderObject() as RenderBox;
                        final lp = box.globalToLocal(d.globalPosition);
                        final cp = MatrixUtils.transformPoint(Matrix4.inverted(_transformCtrl.value), lp);
                        final did = edgePainter.hitTestDisconnect(cp);
                        if (did != null) { ctrl.removeEdge(did); return; }
                        final eid = edgePainter.hitTestEdge(cp);
                        if (eid != null) { ctrl.selectEdge(eid); return; }
                        ctrl.deselectAll();
                      },
                      child: Container(
                        color: AppColors.bg,
                        child: InteractiveViewer(
                          transformationController: _transformCtrl,
                          minScale: 0.3, maxScale: 2.0,
                          constrained: false,
                          boundaryMargin: const EdgeInsets.all(2000),
                          panEnabled: !isConnecting,
                          scaleEnabled: !isConnecting,
                          child: SizedBox(
                            width: 3000, height: 2000,
                            child: Stack(children: [
                              CustomPaint(size: const Size(3000, 2000), painter: _GridPainter()),
                              CustomPaint(size: const Size(3000, 2000), painter: edgePainter),
                              ...ctrl.nodes.map((n) => _CanvasNode(key: ValueKey(n.id), node: n)),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // ── 2. SCREEN-SPACE PORT OVERLAY (outside InteractiveViewer!) ──
                // Port dots rendered at screen coordinates so taps ALWAYS work
                ..._buildPortOverlay(ctrl),

                // ── 3. Connection banner ──
                if (isConnecting)
                  Positioned(
                    top: 8, left: 0, right: 0,
                    child: Center(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.amber.withOpacity(0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cable, color: AppColors.amber, size: 16),
                        const SizedBox(width: 8),
                        const Text('Tap green IN port to connect', style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => ctrl.cancelPortDrag(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: AppColors.amber.withOpacity(0.4))),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ]),
                    )),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Screen-space port dots — OUTSIDE InteractiveViewer so taps always register
  List<Widget> _buildPortOverlay(PipelineController ctrl) {
    final matrix = _transformCtrl.value;
    final connecting = ctrl.portDragFromNodeId != null;
    final dots = <Widget>[];

    for (final node in ctrl.nodes) {
      // ── OUT port (blue dot, right side) ──
      {
        final sp = MatrixUtils.transformPoint(matrix, node.outPortCenter);
        final isActive = ctrl.portDragFromNodeId == node.id;
        dots.add(Positioned(
          left: sp.dx - 18, top: sp.dy - 18,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              debugPrint('OUT-PORT: ${node.name}');
              if (isActive) { ctrl.cancelPortDrag(); }
              else { ctrl.startPortDrag(node.id, Offset.zero); }
            },
            child: Container(
              width: 36, height: 36, color: Colors.transparent,
              child: Center(child: Container(
                width: isActive ? 20 : 14, height: isActive ? 20 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.amber : AppColors.blue,
                  border: Border.all(color: AppColors.bg, width: 2),
                  boxShadow: isActive ? [BoxShadow(color: AppColors.amber.withOpacity(0.7), blurRadius: 12, spreadRadius: 3)] : null,
                ),
              )),
            ),
          ),
        ));
      }

      // ── IN port (green dot, left side) ──
          {
        final sp = MatrixUtils.transformPoint(matrix, node.inPortCenter);
        final isTarget = connecting && ctrl.portDragFromNodeId != node.id;
        dots.add(Positioned(
          left: sp.dx - 18, top: sp.dy - 18,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              debugPrint('IN-PORT: ${node.name} | from=${ctrl.portDragFromNodeId}');
              if (ctrl.portDragFromNodeId != null) {
                ctrl.endPortDrag(node.id);
              }
            },
            child: Container(
              width: 36, height: 36, color: Colors.transparent,
              child: Center(child: Container(
                width: isTarget ? 20 : 14, height: isTarget ? 20 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green,
                  border: Border.all(color: AppColors.bg, width: 2),
                  boxShadow: isTarget ? [BoxShadow(color: AppColors.green.withOpacity(0.7), blurRadius: 12, spreadRadius: 3)] : null,
                ),
              )),
            ),
          ),
        ));
      }
    }
    return dots;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GRID PAINTER (same as HTML background-image radial-gradient dots)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 24) {
      for (double y = 0; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CANVAS NODE (Positioned node with drag + port dots)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CanvasNode extends StatelessWidget {
  final PipelineNode node;
  const _CanvasNode({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PipelineController>();
    final isSelected = ctrl.selectedNodeId == node.id;
    final color = node.type.color;

    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: GestureDetector(
        // Disable node drag when in connection mode
        onPanUpdate: ctrl.portDragFromNodeId == null
            ? (d) => ctrl.moveNode(node.id, d.delta)
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main card body — tapping THIS selects the node
            GestureDetector(
              onTap: () => ctrl.selectNode(node.id),
              child: Container(
                width: node.nodeWidth,
                decoration: BoxDecoration(
                  color: node.type == NodeType.join ? AppColors.surface2 : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border2,
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)] : null,
                ),
                child: _buildBody(context),
              ),
            ),
            // Port dots are rendered in screen-space overlay (_buildPortOverlay)
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (node.type) {
      case NodeType.join:
        return JoinNodeBody(node: node);
      default:
        return SourceNodeBody(node: node);
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TOP BAR (same as HTML .topbar)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━