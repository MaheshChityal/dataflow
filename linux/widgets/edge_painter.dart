import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/pipeline_models.dart';
import '../controllers/pipeline_controller.dart';

class EdgePainter extends CustomPainter {
  final PipelineController ctrl;
  EdgePainter(this.ctrl) : super(repaint: ctrl);

  static const _joinColors = <String, Color>{
    'LEFT JOIN':       Color(0xFF8B5CF6),
    'RIGHT JOIN':      Color(0xFF3B82F6),
    'INNER JOIN':      Color(0xFF10B981),
    'FULL OUTER JOIN': Color(0xFFF59E0B),
    'CROSS JOIN':      Color(0xFFEF4444),
  };

  @override
  void paint(Canvas canvas, Size size) {
    // ── Draw edges ──
    for (final edge in ctrl.edges) {
      final from = ctrl.findNode(edge.fromNodeId);
      final to = ctrl.findNode(edge.toNodeId);
      if (from == null || to == null) continue;

      final p1 = from.outPortCenter;
      final p2 = to.inPortCenter;
      final isSelected = ctrl.selectedEdgeId == edge.id;

      // Color based on join type (same as HTML)
      final color = to.type == NodeType.join
          ? (_joinColors[to.joinType] ?? const Color(0xFF8B5CF6))
          : AppColors.blue;

      // Bezier path (same as HTML cubic bezier)
      final dx = (p2.dx - p1.dx).abs() * 0.5;
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..cubicTo(p1.dx + dx, p1.dy, p2.dx - dx, p2.dy, p2.dx, p2.dy);

      // Glow layer
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(isSelected ? 0.2 : 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 10 : 6,
      );

      // Main stroke
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(isSelected ? 1.0 : 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3 : 2,
      );

      // ── Disconnect button (same as HTML — shown when edge selected) ──
      if (isSelected) {
        final mx = (p1.dx + p2.dx) / 2;
        final my = (p1.dy + p2.dy) / 2 + 12;

        // Circle bg
        canvas.drawCircle(
          Offset(mx, my), 11,
          Paint()..color = AppColors.surface2,
        );
        canvas.drawCircle(
          Offset(mx, my), 11,
          Paint()
            ..color = AppColors.red
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // X text
        final tp = TextPainter(
          text: const TextSpan(
            text: '✕',
            style: TextStyle(color: AppColors.red, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(mx - tp.width / 2, my - tp.height / 2));
      }
    }

    // ── Live port drag line (same as HTML) ──
    if (ctrl.portDragFromNodeId != null && ctrl.portDragCurrentPos != null) {
      final from = ctrl.findNode(ctrl.portDragFromNodeId!);
      if (from != null) {
        final p1 = from.outPortCenter;
        final p2 = ctrl.portDragCurrentPos!;
        canvas.drawLine(
          p1, p2,
          Paint()
            ..color = AppColors.blue
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant EdgePainter old) => true;

  /// Hit test: check if a tap position hits any edge's disconnect button
  /// Returns edge id or null
  String? hitTestDisconnect(Offset pos) {
    for (final edge in ctrl.edges) {
      if (ctrl.selectedEdgeId != edge.id) continue;
      final from = ctrl.findNode(edge.fromNodeId);
      final to = ctrl.findNode(edge.toNodeId);
      if (from == null || to == null) continue;

      final p1 = from.outPortCenter;
      final p2 = to.inPortCenter;
      final mx = (p1.dx + p2.dx) / 2;
      final my = (p1.dy + p2.dy) / 2 + 12;

      if ((pos - Offset(mx, my)).distance <= 14) return edge.id;
    }
    return null;
  }

  /// Hit test: check if tap hits any edge line (within tolerance)
  String? hitTestEdge(Offset pos) {
    for (final edge in ctrl.edges) {
      final from = ctrl.findNode(edge.fromNodeId);
      final to = ctrl.findNode(edge.toNodeId);
      if (from == null || to == null) continue;

      final p1 = from.outPortCenter;
      final p2 = to.inPortCenter;

      // Simple bounding box + distance check
      final minX = min(p1.dx, p2.dx) - 20;
      final maxX = max(p1.dx, p2.dx) + 20;
      final minY = min(p1.dy, p2.dy) - 20;
      final maxY = max(p1.dy, p2.dy) + 20;

      if (pos.dx < minX || pos.dx > maxX || pos.dy < minY || pos.dy > maxY) continue;

      // Sample points along bezier and check distance
      final dx = (p2.dx - p1.dx).abs() * 0.5;
      for (double t = 0; t <= 1.0; t += 0.05) {
        final x = _cubic(t, p1.dx, p1.dx + dx, p2.dx - dx, p2.dx);
        final y = _cubic(t, p1.dy, p1.dy, p2.dy, p2.dy);
        if ((pos - Offset(x, y)).distance < 12) return edge.id;
      }
    }
    return null;
  }

  double _cubic(double t, double p0, double p1, double p2, double p3) {
    final t2 = t * t;
    final t3 = t2 * t;
    final mt = 1 - t;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;
    return mt3 * p0 + 3 * mt2 * t * p1 + 3 * mt * t2 * p2 + t3 * p3;
  }

  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FILE: widgets/node_bodies.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SOURCE NODE BODY (same as HTML source node card)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
