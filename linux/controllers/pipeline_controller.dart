import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pipeline_models.dart';
import '../models/pipeline_config.dart';
import '../utils/join_engine.dart';

class PipelineController extends ChangeNotifier {
  // ── Core state (same as HTML) ──
  final List<PipelineNode> nodes = [];
  final List<PipelineEdge> edges = [];
  int _nodeIdSeq = 0;

  String? selectedNodeId;
  String? selectedEdgeId;

  // ── Sidebar state (same as HTML sidebar dept/template/count) ──
  String sidebarDept = '';
  String sidebarTemplate = '';
  int requiredSourceCount = 0;

  // ── Port drag state (same as HTML portDrag) ──
  String? portDragFromNodeId;
  Offset? portDragCurrentPos;

  // ── Helpers ──
  String _nextId() => 'n${++_nodeIdSeq}';
  String _nextEdgeId() => 'e${++_nodeIdSeq}';

  PipelineNode? findNode(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  PipelineEdge? findEdge(String id) {
    for (final e in edges) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ── Source count logic (same as HTML canAddSource / refreshSourceCounter) ──
  int get sourceNodesOnCanvas => nodes.where((n) => n.type.isSource).length;
  bool get canAddSource {
    if (requiredSourceCount <= 0) return true;
    return sourceNodesOnCanvas < requiredSourceCount;
  }

  // ── Sidebar actions (same as HTML onSidebarDeptChange / onSidebarTemplateChange) ──
  void setSidebarDept(String dept) {
    sidebarDept = dept;
    sidebarTemplate = '';
    requiredSourceCount = 0;
    notifyListeners();
  }

  void setSidebarTemplate(String template) {
    sidebarTemplate = template;
    requiredSourceCount = PipelineConfig.templateSourceCount[template] ?? 0;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // NODE CRUD (same as HTML addNode / deleteNode / clearCanvas)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Same as HTML addNode(type, name, x, y)
  PipelineNode addNode(NodeType type, Offset position, {String? name}) {
    final node = PipelineNode(
      id: _nextId(),
      type: type,
      name: name ?? type.label,
      position: position,
      department: sidebarDept.isNotEmpty ? sidebarDept : 'Finance',
      template: sidebarTemplate,
    );
    // No demo data — columns load only when user uploads file
    nodes.add(node);
    notifyListeners();
    return node;
  }

  /// Same as HTML deleteNode(nodeId)
  void deleteNode(String nodeId) {
    nodes.removeWhere((n) => n.id == nodeId);
    edges.removeWhere((e) => e.fromNodeId == nodeId || e.toNodeId == nodeId);
    // Clean JOIN references
    for (final n in nodes.where((n) => n.type == NodeType.join)) {
      if (n.leftSrcId == nodeId) n.leftSrcId = null;
      if (n.rightSrcId == nodeId) n.rightSrcId = null;
    }
    if (selectedNodeId == nodeId) selectedNodeId = null;
    notifyListeners();
  }

  /// Same as HTML clearCanvas()
  void clearCanvas() {
    nodes.clear();
    edges.clear();
    selectedNodeId = null;
    selectedEdgeId = null;
    _nodeIdSeq = 0;
    notifyListeners();
  }

  /// Move node by delta (drag handler)
  void moveNode(String nodeId, Offset delta) {
    final node = findNode(nodeId);
    if (node != null) {
      node.position += delta;
      notifyListeners();
    }
  }

  void selectNode(String? nodeId) {
    selectedNodeId = nodeId;
    selectedEdgeId = null;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // EDGE CRUD (same as HTML addEdge / removeEdge / selectEdge)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Same as HTML addEdge(fromId, toId) — includes auto-direction-correction
  void addEdge(String fromId, String toId) {
    final fromNode = findNode(fromId);
    final toNode = findNode(toId);
    if (fromNode == null || toNode == null) {
      debugPrint('EDGE FAIL: fromNode or toNode null. from=$fromId to=$toId');
      return;
    }

    // Auto-correct direction
    if (fromNode.type == NodeType.output ||
        (toNode.type.isSource && fromNode.type == NodeType.join)) {
      final tmp = fromId;
      fromId = toId;
      toId = tmp;
    }

    if (edges.any((e) => e.fromNodeId == fromId && e.toNodeId == toId)) {
      debugPrint('EDGE SKIP: duplicate from=$fromId to=$toId');
      return;
    }

    edges.add(PipelineEdge(id: _nextEdgeId(), fromNodeId: fromId, toNodeId: toId));
    debugPrint('EDGE ADDED: from=$fromId to=$toId | total edges=${edges.length}');

    final target = findNode(toId);
    if (target != null && target.type == NodeType.join) {
      _syncJoinSources(target);
    }

    notifyListeners();
  }

  /// Same as HTML removeEdge(fromId, toId)
  void removeEdge(String edgeId) {
    final edge = findEdge(edgeId);
    if (edge == null) return;
    edges.removeWhere((e) => e.id == edgeId);

    // Resync JOIN if source disconnected
    final target = findNode(edge.toNodeId);
    if (target != null && target.type == NodeType.join) {
      _syncJoinSources(target);
    }
    selectedEdgeId = null;
    notifyListeners();
  }

  /// Same as HTML selectEdge(fromId, toId) — toggle
  void selectEdge(String edgeId) {
    selectedEdgeId = (selectedEdgeId == edgeId) ? null : edgeId;
    selectedNodeId = null;
    notifyListeners();
  }

  void deselectAll() {
    selectedNodeId = null;
    selectedEdgeId = null;
    notifyListeners();
  }

  /// Same as HTML syncJoinSources(joinNode)
  void _syncJoinSources(PipelineNode joinNode) {
    final inEdges = edges.where((e) => e.toNodeId == joinNode.id).toList();
    final srcA = inEdges.isNotEmpty ? findNode(inEdges[0].fromNodeId) : null;
    final srcB = inEdges.length > 1 ? findNode(inEdges[1].fromNodeId) : null;

    joinNode.leftSrcId = srcA?.id;
    joinNode.rightSrcId = srcB?.id;

    // Seed empty mapping if none
    if (joinNode.mappings.isEmpty) {
      joinNode.mappings.add(ColumnMapping());
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PORT DRAG (same as HTML portDrag state)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void startPortDrag(String nodeId, Offset pos) {
    portDragFromNodeId = nodeId;
    portDragCurrentPos = pos;
    notifyListeners();
  }

  void updatePortDrag(Offset pos) {
    portDragCurrentPos = pos;
    notifyListeners();
  }

  void endPortDrag(String? targetNodeId) {
    if (portDragFromNodeId != null && targetNodeId != null &&
        portDragFromNodeId != targetNodeId) {
      addEdge(portDragFromNodeId!, targetNodeId);
    }
    portDragFromNodeId = null;
    portDragCurrentPos = null;
    notifyListeners();
  }

  void cancelPortDrag() {
    portDragFromNodeId = null;
    portDragCurrentPos = null;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // JOIN MAPPING (same as HTML joinCardAddFromInput / joinCardMapDel)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void addMappingToJoin(String joinNodeId, ColumnMapping mapping) {
    final node = findNode(joinNodeId);
    if (node == null) return;
    // Remove empty seed mappings
    node.mappings.removeWhere((m) => !m.isValid);
    node.mappings.add(mapping);
    node.joinType = mapping.joinType;
    notifyListeners();
  }

  void removeMappingFromJoin(String joinNodeId, int index) {
    final node = findNode(joinNodeId);
    if (node == null || index < 0 || index >= node.mappings.length) return;
    node.mappings.removeAt(index);
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // JOIN RESULT (same as HTML getNodeRows / getOutputResult — recursive)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Recursive — handles chained joins (join1 → join2 → output)
  List<Map<String, dynamic>>? getNodeRows(String nodeId) {
    final node = findNode(nodeId);
    if (node == null) return null;

    // Source node — return its rows
    if (node.type.isSource) {
      return node.rows.isNotEmpty ? node.rows : null;
    }

    // JOIN node — execute join using mapping source IDs
    if (node.type == NodeType.join) {
      final validMappings = node.mappings.where((m) => m.isValid).toList();
      if (validMappings.isEmpty) return null;

      // Use first mapping's source IDs to determine left/right
      final firstMap = validMappings.first;
      final leftRows = getNodeRows(firstMap.leftSourceId);
      final rightRows = getNodeRows(firstMap.rightSourceId);
      if (leftRows == null || rightRows == null) return null;

      return JoinEngine.execute(
        leftRows: leftRows,
        rightRows: rightRows,
        mappings: node.mappings,
        joinType: firstMap.joinType,
      );
    }

    return null;
  }

  /// Get final result for an OUTPUT node
  /// Returns {cols: List<String>, rows: List<Map>} or null
  Map<String, dynamic>? getOutputResult(String outputNodeId) {
    final outNode = findNode(outputNodeId);
    final inEdge = edges.where((e) => e.toNodeId == outputNodeId).toList();
    if (inEdge.isEmpty || outNode == null) return null;

    var rows = getNodeRows(inEdge.first.fromNodeId);
    if (rows == null || rows.isEmpty) return null;

    // Deduplicate all available columns
    final allCols = <String>[];
    final seen = <String>{};
    for (final r in rows) {
      for (final k in r.keys) {
        if (seen.add(k)) allCols.add(k);
      }
    }

    // Auto-populate outputSelectedCols if empty (first time)
    if (outNode.outputSelectedCols.isEmpty) {
      outNode.outputSelectedCols = List<String>.from(allCols);
    }

    // ── 1. Apply Filters (WHERE) ──
    final validFilters = outNode.filters.where((f) => f.isValid).toList();
    if (validFilters.isNotEmpty) {
      rows = rows.where((row) => validFilters.every((f) => f.matches(row))).toList();
    }

    // ── 2. Apply Sorting (ORDER BY) ──
    final validSorts = outNode.sortRules.where((s) => s.isValid).toList();
    if (validSorts.isNotEmpty) {
      rows = List<Map<String, dynamic>>.from(rows);
      rows.sort((a, b) {
        for (final s in validSorts) {
          final va = '${a[s.column] ?? ''}';
          final vb = '${b[s.column] ?? ''}';
          final na = double.tryParse(va);
          final nb = double.tryParse(vb);
          int cmp;
          if (na != null && nb != null) {
            cmp = na.compareTo(nb);
          } else {
            cmp = va.compareTo(vb);
          }
          if (!s.ascending) cmp = -cmp;
          if (cmp != 0) return cmp;
        }
        return 0;
      });
    }

    // ── 3. Select columns ──
    final selectedCols = outNode.outputSelectedCols.where((c) => allCols.contains(c)).toList();
    final finalCols = selectedCols.isNotEmpty ? selectedCols : allCols;

    // ── 4. Apply aliases ──
    final displayCols = finalCols.map((c) => outNode.columnAliases[c] ?? c).toList();

    // Rebuild rows with only selected cols (using alias as key)
    final finalRows = rows.map((r) {
      final nr = <String, dynamic>{};
      for (int i = 0; i < finalCols.length; i++) {
        nr[displayCols[i]] = r[finalCols[i]] ?? '—';
      }
      return nr;
    }).toList();

    return {'cols': displayCols, 'rows': finalRows, 'allCols': allCols, 'totalBeforeFilter': rows.length};
  }

  /// Diagnose why output has no result (for status messages)
  String? diagnoseOutputIssue(String outputNodeId) {
    final inEdge = edges.where((e) => e.toNodeId == outputNodeId).toList();
    if (inEdge.isEmpty) return null;

    final fromNode = findNode(inEdge.first.fromNodeId);
    if (fromNode == null) return null;

    if (fromNode.type == NodeType.join) {
      // Check connected sources via edges
      final joinInEdges = edges.where((e) => e.toNodeId == fromNode.id).toList();
      if (joinInEdges.length < 2) return 'Connect at least 2 sources to JOIN';

      // Check if mappings exist
      final validMappings = fromNode.mappings.where((m) => m.isValid).toList();
      if (validMappings.isEmpty) return 'Add column mapping in JOIN node';

      // Check if source rows are available (from mapping source IDs)
      final firstMap = validMappings.first;
      final leftNode = findNode(firstMap.leftSourceId);
      final rightNode = findNode(firstMap.rightSourceId);

      if (leftNode == null || rightNode == null) return 'Mapping sources are not connected';

      if (leftNode.rows.isEmpty && rightNode.rows.isEmpty) {
        return 'Upload data rows in both sources (CSV with header + data)';
      }
      if (leftNode.rows.isEmpty) return 'Upload data rows in ${leftNode.name}';
      if (rightNode.rows.isEmpty) return 'Upload data rows in ${rightNode.name}';

      // Try executing join
      final result = getNodeRows(fromNode.id);
      if (result == null || result.isEmpty) return 'No matching rows — check column mapping';

      return null; // should not reach here if getOutputResult works
    }

    if (fromNode.type.isSource && fromNode.rows.isEmpty) {
      return 'Upload data in source (CSV with header + data rows)';
    }

    return null;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INIT FROM SOURCES (same as HTML initFromSources)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void initFromSources(List<Map<String, String>> sources) {
    clearCanvas();

    final count = sources.length;
    const srcX = 60.0;
    const joinX = 320.0;
    const outX = 720.0;
    const startY = 60.0;
    final gapY = min(180.0, 500.0 / max(count, 1));

    // ── Add source nodes ──
    final srcNodes = <PipelineNode>[];
    for (int i = 0; i < count; i++) {
      final src = sources[i];
      final node = PipelineNode(
        id: _nextId(),
        type: NodeTypeExt.fromString(src['type'] ?? 'fc'),
        name: src['name'] ?? 'Source ${i + 1}',
        position: Offset(srcX, startY + i * gapY),
        department: src['department'] ?? 'Finance',
        template: src['template'] ?? '',
        sourceId: int.tryParse(src['id'] ?? ''),
      );
      nodes.add(node);
      srcNodes.add(node);
    }

    // ── Add JOIN nodes (chain) ──
    String? lastJoinId;
    if (count >= 2) {
      for (int i = 0; i < count - 1; i++) {
        final joinNode = PipelineNode(
          id: _nextId(),
          type: NodeType.join,
          name: 'Join Operation',
          position: Offset(joinX, startY + (i + 0.5) * gapY),
        );
        nodes.add(joinNode);

        if (i == 0) {
          addEdge(srcNodes[0].id, joinNode.id);
          addEdge(srcNodes[1].id, joinNode.id);
        } else {
          addEdge(lastJoinId!, joinNode.id);
          addEdge(srcNodes[i + 1].id, joinNode.id);
        }
        lastJoinId = joinNode.id;
      }
    }

    // ── Add OUTPUT node ──
    final outNode = PipelineNode(
      id: _nextId(),
      type: NodeType.output,
      name: 'Final Report',
      position: Offset(outX, startY + ((count - 1) / 2) * gapY),
    );
    nodes.add(outNode);

    final connectTo = lastJoinId ?? (srcNodes.isNotEmpty ? srcNodes.first.id : null);
    if (connectTo != null) addEdge(connectTo, outNode.id);

    // ── Auto-fill sidebar ──
    if (sources.isNotEmpty) {
      sidebarDept = sources[0]['department'] ?? 'Finance';
      sidebarTemplate = sources[0]['template'] ?? '';
      requiredSourceCount = PipelineConfig.templateSourceCount[sidebarTemplate] ?? count;
    }

    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SEED DEMO DATA (same as HTML seedDemoData)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void seedDemoData() {
    for (final node in nodes) {
      if (!node.type.isSource) continue;
      // Try name-based first (for initFromSources), then type-based (for sidebar drag)
      final demo = PipelineConfig.demoData[node.name] ?? demoDataByType[node.type];
      if (demo != null && node.rows.isEmpty) {
        node.cols = List<String>.from(demo.cols);
        node.selectedCols = List<String>.from(demo.cols);
        node.rows = demo.rows.map((r) => Map<String, dynamic>.from(r)).toList();
      }
    }
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // UPDATE SOURCE (same as HTML updateSingleSource / updateSources)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void updateSingleSource(Map<String, dynamic> srcJson) {
    final node = nodes.firstWhere(
      (n) => n.sourceId == srcJson['id'] && n.type.isSource,
      orElse: () => PipelineNode(id: '', type: NodeType.fc, name: '', position: Offset.zero),
    );
    if (node.id.isEmpty) return;

    bool changed = false;
    if (srcJson['name'] != null && srcJson['name'] != node.name) {
      node.name = srcJson['name'];
      changed = true;
    }
    if (srcJson['department'] != null && srcJson['department'] != node.department) {
      node.department = srcJson['department'];
      changed = true;
    }
    if (srcJson['template'] != null && srcJson['template'] != node.template) {
      node.template = srcJson['template'];
      changed = true;
    }
    if (srcJson['type'] != null) {
      final newType = NodeTypeExt.fromString(srcJson['type']);
      if (newType != node.type) {
        node.type = newType;
        node.cols = [];
        node.selectedCols = [];
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  // ── Node name update (same as HTML liveUpdateNode) ──
  void updateNodeName(String nodeId, String name) {
    final node = findNode(nodeId);
    if (node != null) {
      node.name = name;
      notifyListeners();
    }
  }

  // ── Set columns from file (same as HTML handleColFile) ──
  void setNodeColumns(String nodeId, List<String> cols, List<Map<String, dynamic>> rows, String fileName) {
    final node = findNode(nodeId);
    if (node == null) return;
    node.cols = cols;
    node.selectedCols = List<String>.from(cols);
    node.rows = rows;
    node.fileName = fileName;
    notifyListeners();
  }

  // ── Set query file name ──
  void setQueryFile(String nodeId, String fileName) {
    final node = findNode(nodeId);
    if (node == null) return;
    node.queryFileName = fileName;
    notifyListeners();
  }

  // ── Toggle column selection ──
  void toggleColumn(String nodeId, String col) {
    final node = findNode(nodeId);
    if (node == null) return;
    if (node.selectedCols.contains(col)) {
      node.selectedCols.remove(col);
    } else {
      node.selectedCols.add(col);
    }
    notifyListeners();
  }

  // ── Output format ──
  void setOutputFormat(String nodeId, String format) {
    final node = findNode(nodeId);
    if (node != null) {
      node.outputFormat = format;
      notifyListeners();
    }
  }

  // ── Output column toggle ──
  void toggleOutputColumn(String nodeId, String col) {
    final node = findNode(nodeId);
    if (node == null) return;
    if (node.outputSelectedCols.contains(col)) {
      node.outputSelectedCols.remove(col);
    } else {
      node.outputSelectedCols.add(col);
    }
    notifyListeners();
  }

  // ── Column alias ──
  void setColumnAlias(String nodeId, String col, String alias) {
    final node = findNode(nodeId);
    if (node == null) return;
    if (alias.trim().isEmpty) {
      node.columnAliases.remove(col);
    } else {
      node.columnAliases[col] = alias.trim();
    }
    notifyListeners();
  }

  // ── Filters ──
  void addOutputFilter(String nodeId) {
    final node = findNode(nodeId);
    if (node == null) return;
    node.filters.add(OutputFilter());
    notifyListeners();
  }

  void updateOutputFilter(String nodeId, int idx, {String? column, String? operator, String? value}) {
    final node = findNode(nodeId);
    if (node == null || idx >= node.filters.length) return;
    if (column != null) node.filters[idx].column = column;
    if (operator != null) node.filters[idx].operator = operator;
    if (value != null) node.filters[idx].value = value;
    notifyListeners();
  }

  void removeOutputFilter(String nodeId, int idx) {
    final node = findNode(nodeId);
    if (node == null || idx >= node.filters.length) return;
    node.filters.removeAt(idx);
    notifyListeners();
  }

  // ── Sorting ──
  void addOutputSort(String nodeId) {
    final node = findNode(nodeId);
    if (node == null) return;
    node.sortRules.add(OutputSort());
    notifyListeners();
  }

  void updateOutputSort(String nodeId, int idx, {String? column, bool? ascending}) {
    final node = findNode(nodeId);
    if (node == null || idx >= node.sortRules.length) return;
    if (column != null) node.sortRules[idx].column = column;
    if (ascending != null) node.sortRules[idx].ascending = ascending;
    notifyListeners();
  }

  void removeOutputSort(String nodeId, int idx) {
    final node = findNode(nodeId);
    if (node == null || idx >= node.sortRules.length) return;
    node.sortRules.removeAt(idx);
    notifyListeners();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FILE: widgets/edge_painter.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// CustomPainter that draws all edges as bezier curves
