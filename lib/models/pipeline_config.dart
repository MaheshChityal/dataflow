import 'pipeline_models.dart';

class PipelineConfig {
  // ── Templates per department (same as HTML templatesByDept) ──
  static const Map<String, List<String>> templatesByDept = {
    'Finance':         ['GL Reconciliation', 'P&L Report', 'Budget Variance', 'Cash Flow', 'Trial Balance'],
    'Operations':      ['Daily MIS', 'Branch Performance', 'Transaction Summary', 'SLA Report'],
    'Risk Management': ['NPA Report', 'Credit Risk Dashboard', 'Exposure Report', 'Stress Test'],
    'Compliance':      ['AML Report', 'KYC Tracker', 'Regulatory Filing', 'Audit Trail'],
    'IT':              ['System Health', 'API Metrics', 'Error Log Summary', 'Uptime Report'],
    'HR':              ['Headcount Report', 'Payroll Summary', 'Attendance MIS', 'Attrition Report'],
  };

  // ── Required input sources per template (same as HTML templateSourceCount) ──
  static const Map<String, int> templateSourceCount = {
    'GL Reconciliation': 3,  'P&L Report': 2,           'Budget Variance': 2,
    'Cash Flow': 2,          'Trial Balance': 1,
    'Daily MIS': 3,          'Branch Performance': 2,    'Transaction Summary': 1,  'SLA Report': 2,
    'NPA Report': 3,         'Credit Risk Dashboard': 4, 'Exposure Report': 2,      'Stress Test': 3,
    'AML Report': 2,         'KYC Tracker': 2,           'Regulatory Filing': 3,    'Audit Trail': 1,
    'System Health': 2,      'API Metrics': 1,           'Error Log Summary': 2,    'Uptime Report': 1,
    'Headcount Report': 2,   'Payroll Summary': 2,       'Attendance MIS': 1,       'Attrition Report': 2,
  };

  // ── Join types ──
  static const List<String> joinTypes = [
    'INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'FULL OUTER JOIN', 'CROSS JOIN',
  ];

  // ── Demo sources (same as HTML _demoSources) ──
  static const List<Map<String, String>> demoSources = [
    {'id': '1', 'name': 'GL Transactions', 'type': 'fc',     'department': 'Finance', 'template': 'GL Reconciliation'},
    {'id': '2', 'name': 'Account Master',  'type': 'laser',  'department': 'Finance', 'template': 'GL Reconciliation'},
    {'id': '3', 'name': 'Budget Upload',   'type': 'manual', 'department': 'Finance', 'template': 'Budget Variance'},
  ];

  // ── Demo data rows (same as HTML _demoData) ──
  static final Map<String, DemoDataSet> demoData = {
    'GL Transactions': DemoDataSet(
      cols: ['TxnID', 'GL_Code', 'Debit', 'Credit', 'Period'],
      rows: [
        {'TxnID': 'T001', 'GL_Code': '4001', 'Debit': '50000', 'Credit': '0',     'Period': 'Q1'},
        {'TxnID': 'T002', 'GL_Code': '4002', 'Debit': '0',     'Credit': '30000', 'Period': 'Q1'},
        {'TxnID': 'T003', 'GL_Code': '4003', 'Debit': '75000', 'Credit': '0',     'Period': 'Q2'},
        {'TxnID': 'T004', 'GL_Code': '4001', 'Debit': '0',     'Credit': '20000', 'Period': 'Q2'},
        {'TxnID': 'T005', 'GL_Code': '4004', 'Debit': '15000', 'Credit': '0',     'Period': 'Q3'},
      ],
    ),
    'Account Master': DemoDataSet(
      cols: ['GL_Code', 'AccountName', 'Category', 'Status'],
      rows: [
        {'GL_Code': '4001', 'AccountName': 'Salary Expense', 'Category': 'OpEx',    'Status': 'Active'},
        {'GL_Code': '4002', 'AccountName': 'Rent Income',    'Category': 'Revenue', 'Status': 'Active'},
        {'GL_Code': '4003', 'AccountName': 'Utility Expense','Category': 'OpEx',    'Status': 'Active'},
        {'GL_Code': '4005', 'AccountName': 'Depreciation',   'Category': 'OpEx',    'Status': 'Inactive'},
      ],
    ),
    'Budget Upload': DemoDataSet(
      cols: ['GL_Code', 'BudgetAmt', 'ActualAmt', 'Variance'],
      rows: [
        {'GL_Code': '4001', 'BudgetAmt': '60000', 'ActualAmt': '70000', 'Variance': '-10000'},
        {'GL_Code': '4002', 'BudgetAmt': '25000', 'ActualAmt': '30000', 'Variance': '5000'},
        {'GL_Code': '4003', 'BudgetAmt': '80000', 'ActualAmt': '75000', 'Variance': '5000'},
      ],
    ),
  };
}

class DemoDataSet {
  final List<String> cols;
  final List<Map<String, String>> rows;
  const DemoDataSet({required this.cols, required this.rows});
}

/// Demo data by NodeType — for manually dragged nodes from sidebar
final Map<NodeType, DemoDataSet> demoDataByType = {
  NodeType.fc: DemoDataSet(
    cols: ['TxnID', 'GL_Code', 'Debit', 'Credit', 'Period'],
    rows: [
      {'TxnID': 'T001', 'GL_Code': '4001', 'Debit': '50000', 'Credit': '0', 'Period': 'Q1'},
      {'TxnID': 'T002', 'GL_Code': '4002', 'Debit': '0', 'Credit': '30000', 'Period': 'Q1'},
      {'TxnID': 'T003', 'GL_Code': '4003', 'Debit': '75000', 'Credit': '0', 'Period': 'Q2'},
    ],
  ),
  NodeType.laser: DemoDataSet(
    cols: ['GL_Code', 'AccountName', 'Category', 'Status'],
    rows: [
      {'GL_Code': '4001', 'AccountName': 'Salary Expense', 'Category': 'OpEx', 'Status': 'Active'},
      {'GL_Code': '4002', 'AccountName': 'Rent Income', 'Category': 'Revenue', 'Status': 'Active'},
      {'GL_Code': '4003', 'AccountName': 'Utility Expense', 'Category': 'OpEx', 'Status': 'Active'},
    ],
  ),
  NodeType.manual: DemoDataSet(
    cols: ['GL_Code', 'BudgetAmt', 'ActualAmt', 'Variance'],
    rows: [
      {'GL_Code': '4001', 'BudgetAmt': '60000', 'ActualAmt': '70000', 'Variance': '-10000'},
      {'GL_Code': '4002', 'BudgetAmt': '25000', 'ActualAmt': '30000', 'Variance': '5000'},
    ],
  ),
  NodeType.api: DemoDataSet(
    cols: ['EventID', 'Amount', 'EventTime', 'ResponseCode'],
    rows: [
      {'EventID': 'E001', 'Amount': '15000', 'EventTime': '2024-01-15', 'ResponseCode': '200'},
      {'EventID': 'E002', 'Amount': '22000', 'EventTime': '2024-01-16', 'ResponseCode': '200'},
    ],
  ),
};
