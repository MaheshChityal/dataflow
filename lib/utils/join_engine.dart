import '../models/pipeline_models.dart';

class JoinEngine {
  static List<Map<String, dynamic>> execute({
    required List<Map<String, dynamic>> leftRows,
    required List<Map<String, dynamic>> rightRows,
    required List<ColumnMapping> mappings,
    required String joinType,
  }) {
    final validMaps = mappings.where((m) => m.isValid).toList();
    if (validMaps.isEmpty) return [];
    if (leftRows.isEmpty || rightRows.isEmpty) return [];

    // Check if left row matches right row on all mapping conditions
    bool matches(Map<String, dynamic> lr, Map<String, dynamic> rr) {
      return validMaps.every((m) => '${lr[m.leftCol]}' == '${rr[m.rightCol]}');
    }

    // Create empty row with '—' for all keys
    Map<String, dynamic> emptyOf(Map<String, dynamic> sample) {
      return {for (var k in sample.keys) k: '—'};
    }

    final result = <Map<String, dynamic>>[];

    switch (joinType) {
      case 'INNER JOIN':
        for (final lr in leftRows) {
          for (final rr in rightRows) {
            if (matches(lr, rr)) {
              result.add({...lr, ...rr});
            }
          }
        }
        break;

      case 'LEFT JOIN':
        for (final lr in leftRows) {
          bool matched = false;
          for (final rr in rightRows) {
            if (matches(lr, rr)) {
              result.add({...lr, ...rr});
              matched = true;
            }
          }
          if (!matched) {
            result.add({...lr, ...emptyOf(rightRows.first)});
          }
        }
        break;

      case 'RIGHT JOIN':
        for (final rr in rightRows) {
          bool matched = false;
          for (final lr in leftRows) {
            if (matches(lr, rr)) {
              result.add({...lr, ...rr});
              matched = true;
            }
          }
          if (!matched) {
            result.add({...emptyOf(leftRows.first), ...rr});
          }
        }
        break;

      case 'FULL OUTER JOIN':
        final rightMatched = <int>{};
        for (final lr in leftRows) {
          bool matched = false;
          for (int i = 0; i < rightRows.length; i++) {
            if (matches(lr, rightRows[i])) {
              result.add({...lr, ...rightRows[i]});
              matched = true;
              rightMatched.add(i);
            }
          }
          if (!matched) {
            result.add({...lr, ...emptyOf(rightRows.first)});
          }
        }
        for (int i = 0; i < rightRows.length; i++) {
          if (!rightMatched.contains(i)) {
            result.add({...emptyOf(leftRows.first), ...rightRows[i]});
          }
        }
        break;

      case 'CROSS JOIN':
        for (final lr in leftRows) {
          for (final rr in rightRows) {
            result.add({...lr, ...rr});
          }
        }
        break;
    }

    return result;
  }
}

