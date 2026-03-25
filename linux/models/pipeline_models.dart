import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ENUMS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum NodeType { fc, laser, manual, api, join, output }

extension NodeTypeExt on NodeType {
  bool get isSource => this != NodeType.join && this != NodeType.output;

  String get label {
    switch (this) {
      case NodeType.fc:     return 'FC Source';
      case NodeType.laser:  return 'Laser Source';
      case NodeType.manual: return 'Manual Upload';
      case NodeType.api:    return 'App-App API';
      case NodeType.join:   return 'Join Operation';
      case NodeType.output: return 'Output';
    }
  }

  String get subtitle {
    switch (this) {
      case NodeType.fc:     return 'Finacle Core';
      case NodeType.laser:  return 'Laser Banking';
      case NodeType.manual: return 'CSV / Excel';
      case NodeType.api:    return 'REST Endpoint';
      case NodeType.join:   return 'LEFT / INNER / RIGHT';
      case NodeType.output: return 'CSV / Excel / JSON';
    }
  }

  IconData get icon {
    switch (this) {
      case NodeType.fc:     return Icons.bar_chart_rounded;
      case NodeType.laser:  return Icons.flash_on_rounded;
      case NodeType.manual: return Icons.upload_file_rounded;
      case NodeType.api:    return Icons.power_rounded;
      case NodeType.join:   return Icons.link_rounded;
      case NodeType.output: return Icons.output_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NodeType.fc:     return AppColors.blue;
      case NodeType.laser:  return AppColors.green;
      case NodeType.manual: return AppColors.amber;
      case NodeType.api:    return AppColors.violet;
      case NodeType.join:   return AppColors.violet;
      case NodeType.output: return AppColors.green;
    }
  }

  /// Parse from string (Flutter savedRow 'type' field)
  static NodeType fromString(String s) {
    switch (s.toLowerCase()) {
      case 'fc':     return NodeType.fc;
      case 'laser':  return NodeType.laser;
      case 'manual': return NodeType.manual;
      case 'api':    return NodeType.api;
      case 'join':   return NodeType.join;
      case 'output': return NodeType.output;
      default:       return NodeType.fc;
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COLUMN MAPPING
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ColumnMapping {
  String leftSourceId;   // Source node ID
  String leftCol;        // Column from that source
  String joinType;       // Relation type
  String rightSourceId;  // Dependent source node ID
  String rightCol;       // Column from dependent source

  ColumnMapping({
    this.leftSourceId = '',
    this.leftCol = '',
    this.joinType = 'LEFT JOIN',
    this.rightSourceId = '',
    this.rightCol = '',
  });

  bool get isValid => leftSourceId.isNotEmpty && leftCol.isNotEmpty && rightSourceId.isNotEmpty && rightCol.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'leftSourceId': leftSourceId,
    'leftCol': leftCol,
    'joinType': joinType,
    'rightSourceId': rightSourceId,
    'rightCol': rightCol,
  };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// OUTPUT FILTER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class OutputFilter {
  String column;
  String operator;
  String value;

  OutputFilter({this.column = '', this.operator = '=', this.value = ''});

  bool get isValid => column.isNotEmpty && value.isNotEmpty;

  bool matches(Map<String, dynamic> row) {
    if (!isValid) return true;
    final cellVal = '${row[column] ?? ''}';
    switch (operator) {
      case '=':  return cellVal == value;
      case '!=': return cellVal != value;
      case '>':  return (double.tryParse(cellVal) ?? 0) > (double.tryParse(value) ?? 0);
      case '<':  return (double.tryParse(cellVal) ?? 0) < (double.tryParse(value) ?? 0);
      case '>=': return (double.tryParse(cellVal) ?? 0) >= (double.tryParse(value) ?? 0);
      case '<=': return (double.tryParse(cellVal) ?? 0) <= (double.tryParse(value) ?? 0);
      case 'contains': return cellVal.toLowerCase().contains(value.toLowerCase());
      case 'starts with': return cellVal.toLowerCase().startsWith(value.toLowerCase());
      default: return true;
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// OUTPUT SORT
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class OutputSort {
  String column;
  bool ascending;

  OutputSort({this.column = '', this.ascending = true});

  bool get isValid => column.isNotEmpty;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PIPELINE NODE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class PipelineNode {
  final String id;
  NodeType type;
  String name;
  Offset position;
  String department;
  String template;

  /// Column names extracted from uploaded file
  List<String> cols;
  /// Columns user has selected/toggled on
  List<String> selectedCols;
  /// Actual data rows (list of {colName: value} maps)
  List<Map<String, dynamic>> rows;

  /// JOIN-specific
  List<ColumnMapping> mappings;
  String? leftSrcId;
  String? rightSrcId;
  String joinType;

  /// OUTPUT-specific
  String outputFormat;
  /// Output column selection (which cols to include in final report)
  List<String> outputSelectedCols;
  /// Column aliases {originalName: aliasName}
  Map<String, String> columnAliases;
  /// Filters [{column, operator, value}]
  List<OutputFilter> filters;
  /// Sort config [{column, direction}]
  List<OutputSort> sortRules;

  /// File info
  String? fileName;
  String? queryFileName;

  /// Original Flutter savedRow id (for updateSingleSource)
  int? sourceId;

  PipelineNode({
    required this.id,
    required this.type,
    required this.name,
    required this.position,
    this.department = 'Finance',
    this.template = '',
    List<String>? cols,
    List<String>? selectedCols,
    List<Map<String, dynamic>>? rows,
    List<ColumnMapping>? mappings,
    this.leftSrcId,
    this.rightSrcId,
    this.joinType = 'LEFT JOIN',
    this.outputFormat = 'csv',
    List<String>? outputSelectedCols,
    Map<String, String>? columnAliases,
    List<OutputFilter>? filters,
    List<OutputSort>? sortRules,
    this.fileName,
    this.queryFileName,
    this.sourceId,
  })  : cols = cols ?? [],
        selectedCols = selectedCols ?? [],
        rows = rows ?? [],
        mappings = mappings ?? [],
        outputSelectedCols = outputSelectedCols ?? [],
        columnAliases = columnAliases ?? {},
        filters = filters ?? [],
        sortRules = sortRules ?? [];

  // ── Layout dimensions (matches HTML CSS) ──

  double get nodeWidth {
    switch (type) {
      case NodeType.join:   return 340;
      case NodeType.output: return 320;
      default:              return 200;
    }
  }

  double get nodeHeight {
    switch (type) {
      case NodeType.join:
        final validCount = mappings.where((m) => m.isValid).length;
        return 140 + (validCount * 28) + 50; // header+badges+mappings+inputRow
      case NodeType.output: return 200;
      default:              return 150;
    }
  }

  /// Port positions (relative to node top-left, same as HTML getPortPos)
  Offset get outPortCenter => Offset(position.dx + nodeWidth, position.dy + nodeHeight / 2);
  Offset get inPortCenter  => Offset(position.dx, position.dy + nodeHeight / 2);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PIPELINE EDGE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class PipelineEdge {
  final String id;
  final String fromNodeId;
  final String toNodeId;

  const PipelineEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
  });
}
