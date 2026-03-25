import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../models/template_request.dart';
import '../providers/template_provider.dart';
import '../services/master_data_service.dart';

class TemplateCreationPage extends StatefulWidget {
  const TemplateCreationPage({super.key});

  @override
  State<TemplateCreationPage> createState() => _TemplateCreationPageState();
}

class _TemplateCreationPageState extends State<TemplateCreationPage> with TickerProviderStateMixin {
  final _model = TemplateRequest();
  final _scrollCtrl = ScrollController();
  bool _submitted = false;

  final _nameCtrl = TextEditingController();
  final _normalVolCtrl = TextEditingController();
  final _peakVolCtrl = TextEditingController();
  final _benefitAmtCtrl = TextEditingController();
  final _tatCtrl = TextEditingController();
  final _spocCtrl = TextEditingController();
  final _spocMgrCtrl = TextEditingController();
  final _unitHeadCtrl = TextEditingController();

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  List<String> _departments = [];
  bool _deptLoading = true;
  static const _frequencies = ['Daily', 'Weekly', 'Bi-Weekly', 'Monthly', 'Quarterly', 'Yearly', 'On-Demand'];
  static const _benefitTypes = ['Cost Saving', 'Revenue Generation', 'Efficiency Improvement', 'Risk Reduction', 'Compliance', 'Other'];
  static const _priorities = ['Low', 'Medium', 'High', 'Critical'];
  static const _outputFormats = ['Unimailing', 'User Defined'];
  static const _approvalOptions = ['Unit Head', 'UAT Sign Off', 'Marketing', 'BCU Head', 'CCU Head Approval', 'Functional Head Approval', 'SMS Whitelisting'];
  static const _sourceCountOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  static const _numOutputOptions = ['1 - Static', '2 - Dynamic'];

  // Per-approval file uploads: { "Unit Head": "approval_uh.pdf", ... }
  final Map<String, String> _approvalFiles = {};

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 12).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeCtrl);
    _loadDepartments();
  }

  void _loadDepartments() async {
    final service = context.read<MasterDataService>();
    final depts = await service.getDepartments();
    if (mounted) {
      setState(() {
        _departments = depts;
        _deptLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose(); _normalVolCtrl.dispose(); _peakVolCtrl.dispose();
    _benefitAmtCtrl.dispose();
    _tatCtrl.dispose(); _spocCtrl.dispose(); _spocMgrCtrl.dispose(); _unitHeadCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _syncModel() {
    _model.templateName = _nameCtrl.text.trim();
    _model.normalVolume = int.tryParse(_normalVolCtrl.text) ?? 0;
    _model.peakVolume = int.tryParse(_peakVolCtrl.text) ?? 0;
    _model.benefitAmount = double.tryParse(_benefitAmtCtrl.text) ?? 0;
    _model.benefitInTAT = _tatCtrl.text.trim();
    _model.spocPerson = _spocCtrl.text.trim();
    _model.spocManager = _spocMgrCtrl.text.trim();
    _model.unitHead = _unitHeadCtrl.text.trim();
    _model.approvalFiles = Map<String, String>.from(_approvalFiles);
  }

  bool get _allApprovalFilesUploaded =>
      _model.approvals.isNotEmpty && _model.approvals.every((a) => _approvalFiles.containsKey(a));

  void _save() async {
    _syncModel();
    setState(() => _submitted = true);

    if (!_model.isGeneralInfoValid || !_model.isOutputFormatValid || !_model.isApprovalValid || !_allApprovalFilesUploaded) {
      _shakeCtrl.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required sections'), backgroundColor: Colors.red),
      );
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      return;
    }

    // Use TemplateProvider to save
    final provider = context.read<TemplateProvider>();
    final success = await provider.saveTemplate(_model);

    if (mounted && success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _SuccessDialog(onDone: () { Navigator.of(ctx).pop(); _resetForm(); }),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Save failed'), backgroundColor: Colors.red),
      );
    }
  }

  void _resetForm() {
    _model.reset();
    for (final c in [_nameCtrl, _normalVolCtrl, _peakVolCtrl, _benefitAmtCtrl, _tatCtrl, _spocCtrl, _spocMgrCtrl, _unitHeadCtrl]) { c.clear(); }
    _approvalFiles.clear();
    setState(() => _submitted = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeCtrl.isAnimating ? _shakeAnim.value * ((_shakeCtrl.value * 10).toInt().isEven ? 1 : -1) : 0, 0),
        child: child,
      ),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF004C8F).withOpacity(0.1)),
                  child: const Icon(Icons.add_circle_outline, color: Color(0xFF004C8F), size: 24),
                ),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Create New Template', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                  Text('Fill in all required sections to create a template', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                ]),
              ]),
              const SizedBox(height: 14),

              // A) General Information
              _sectionCard(title: 'General Information', icon: Icons.info_outline, hasError: _submitted && !_model.isGeneralInfoValid, child: Column(children: [
                _row([_tf('Template Name *', _nameCtrl, 'Enter template name'), _deptLoading ? _loadingField('Department *') : _dd('Department *', _departments, _model.department, (v) => setState(() => _model.department = v ?? '')), _dd('Frequency *', _frequencies, _model.frequency, (v) => setState(() => _model.frequency = v ?? ''))]),
                const SizedBox(height: 10),
                _row([_dd('Priority', _priorities, _model.priority, (v) => setState(() => _model.priority = v ?? 'Medium')), _tf('Normal Volume', _normalVolCtrl, '0', num: true), _tf('Peak Volume', _peakVolCtrl, '0', num: true)]),
                const SizedBox(height: 10),
                _row([_dd('Source Count *', _sourceCountOptions, _model.sourceCount > 0 ? '${_model.sourceCount}' : '', (v) => setState(() => _model.sourceCount = int.tryParse(v ?? '') ?? 0)), _dd('Number of Outputs *', _numOutputOptions, _model.numberOfOutputs > 0 ? (_model.numberOfOutputs == 1 ? '1 - Static' : '2 - Dynamic') : '', (v) => setState(() => _model.numberOfOutputs = v == '1 - Static' ? 1 : v == '2 - Dynamic' ? 2 : 0)), _dd('Benefit Type', _benefitTypes, _model.benefitType, (v) => setState(() => _model.benefitType = v ?? ''))]),
                const SizedBox(height: 10),
                _row([_tf('Benefit Amount (₹)', _benefitAmtCtrl, '0.00', num: true), _tf('Benefit in TAT', _tatCtrl, 'e.g. 2 hours'), _dp('Go Live Date', _model.goLiveDate, (v) => setState(() => _model.goLiveDate = v))]),
                const SizedBox(height: 10),
                _row([_dp('Deactivate Date', _model.deactivateDate, (v) => setState(() => _model.deactivateDate = v)), _tf('SPOC Person *', _spocCtrl, 'Enter name'), _tf('SPOC Manager', _spocMgrCtrl, 'Enter name')]),
                const SizedBox(height: 10),
                _row([_tf('Unit Head', _unitHeadCtrl, 'Enter name'), const SizedBox(), const SizedBox()]),
              ])),
              const SizedBox(height: 14),

              // B) Output Format
              _sectionCard(title: 'Output Format', icon: Icons.output_rounded, hasError: _submitted && !_model.isOutputFormatValid, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Select at least one output format', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: _outputFormats.map((f) {
                  final sel = _model.outputFormats.contains(f);
                  return InkWell(
                    onTap: () => setState(() { sel ? _model.outputFormats.remove(f) : _model.outputFormats.add(f); }),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: sel ? const Color(0xFF004C8F).withOpacity(0.08) : AppColors.surface2, border: Border.all(color: sel ? const Color(0xFF004C8F) : AppColors.border, width: sel ? 1.5 : 1)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(sel ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: sel ? const Color(0xFF004C8F) : AppColors.textDim),
                        const SizedBox(width: 8),
                        Text(f, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? const Color(0xFF004C8F) : AppColors.text)),
                      ]),
                    ),
                  );
                }).toList()),
                if (_submitted && !_model.isOutputFormatValid) _err('Please select at least one output format'),
              ])),
              const SizedBox(height: 14),

              // C) Approval List
              _sectionCard(title: 'Approval List', icon: Icons.approval_outlined, hasError: _submitted && !_model.isApprovalValid, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Select required approvals', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: _approvalOptions.map((a) {
                  final sel = _model.approvals.contains(a);
                  return InkWell(
                    onTap: () => setState(() { sel ? _model.approvals.remove(a) : _model.approvals.add(a); }),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: sel ? AppColors.green.withOpacity(0.08) : AppColors.surface2, border: Border.all(color: sel ? AppColors.green : AppColors.border, width: sel ? 1.5 : 1)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(sel ? Icons.check_box : Icons.check_box_outline_blank, size: 16, color: sel ? AppColors.green : AppColors.textDim),
                        const SizedBox(width: 6),
                        Text(a, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? AppColors.green : AppColors.text)),
                      ]),
                    ),
                  );
                }).toList()),
                if (_submitted && !_model.isApprovalValid) _err('Please select at least one approval'),
              ])),
              const SizedBox(height: 14),

              // E) Approval File Upload (per approval)
              if (_model.approvals.isNotEmpty)
                _sectionCard(title: 'Approval File Upload', icon: Icons.attach_file_rounded, hasError: _submitted && !_allApprovalFilesUploaded, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Upload approval document for each selected approval', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                  const SizedBox(height: 12),
                  ..._model.approvals.map((approval) {
                    final uploaded = _approvalFiles.containsKey(approval);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: uploaded ? AppColors.green.withOpacity(0.04) : AppColors.surface2,
                        border: Border.all(color: uploaded ? AppColors.green.withOpacity(0.2) : (_submitted && !uploaded ? AppColors.red.withOpacity(0.3) : AppColors.border)),
                      ),
                      child: Row(children: [
                        Icon(uploaded ? Icons.check_circle : Icons.upload_file_rounded, size: 18, color: uploaded ? AppColors.green : AppColors.textDim),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(approval, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: uploaded ? AppColors.green : AppColors.text)),
                          if (uploaded)
                            Text(_approvalFiles[approval]!, style: const TextStyle(fontSize: 10, color: AppColors.textDim), overflow: TextOverflow.ellipsis),
                        ])),
                        const SizedBox(width: 8),
                        if (uploaded) ...[
                          InkWell(
                            onTap: () => _pickForApproval(approval),
                            child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                              child: const Text('Replace', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDim))),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => setState(() => _approvalFiles.remove(approval)),
                            child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.red.withOpacity(0.3))),
                              child: const Icon(Icons.close, size: 14, color: AppColors.red)),
                          ),
                        ] else
                          InkWell(
                            onTap: () => _pickForApproval(approval),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: const Color(0xFF004C8F).withOpacity(0.08), border: Border.all(color: const Color(0xFF004C8F).withOpacity(0.2))),
                              child: const Text('Upload', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF004C8F)))),
                          ),
                      ]),
                    );
                  }),
                  if (_submitted && !_allApprovalFilesUploaded) _err('Please upload files for all selected approvals'),
                ])),
              const SizedBox(height: 28),

              // Save
              SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 20),
                label: const Text('Save Template', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004C8F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              )),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child, bool hasError = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasError ? AppColors.red : AppColors.border, width: hasError ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: hasError ? AppColors.red.withOpacity(0.08) : const Color(0xFF004C8F).withOpacity(0.08)), child: Icon(icon, size: 18, color: hasError ? AppColors.red : const Color(0xFF004C8F))),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: hasError ? AppColors.red : AppColors.text)),
          if (hasError) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: AppColors.red.withOpacity(0.1)), child: const Text('Required', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.red)))],
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget _row(List<Widget> c) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: c.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList());

  Widget _loadingField(String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.fieldLabel), const SizedBox(height: 4),
      Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border), color: AppColors.surface2),
        child: const Row(children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDim)),
          SizedBox(width: 8),
          Text('Loading...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ]),
      ),
    ]);
  }

  Widget _tf(String label, TextEditingController ctrl, String hint, {bool num = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.fieldLabel), const SizedBox(height: 4),
      SizedBox(height: 36, child: TextField(controller: ctrl, keyboardType: num ? TextInputType.number : TextInputType.text, style: const TextStyle(fontSize: 13, color: AppColors.text),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF004C8F), width: 1.5)),
          filled: true, fillColor: AppColors.surface2))),
    ]);
  }

  Widget _dd(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.fieldLabel), const SizedBox(height: 4),
      SizedBox(height: 36, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border), color: AppColors.surface2),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, isDense: true, value: items.contains(value) ? value : null,
          hint: const Text('Select', style: TextStyle(fontSize: 12, color: AppColors.textMuted)), dropdownColor: AppColors.surface,
          style: const TextStyle(fontSize: 13, color: AppColors.text), icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textDim),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: onChanged)))),
    ]);
  }

  Widget _dp(String label, String value, ValueChanged<String> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.fieldLabel), const SizedBox(height: 4),
      InkWell(onTap: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (d != null) onChanged('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      }, child: Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border), color: AppColors.surface2),
        child: Row(children: [Expanded(child: Text(value.isEmpty ? 'Select date' : value, style: TextStyle(fontSize: 12, color: value.isEmpty ? AppColors.textMuted : AppColors.text))), const Icon(Icons.calendar_today, size: 14, color: AppColors.textDim)]))),
    ]);
  }

  Widget _err(String msg) => TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 300),
    builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 4 * (1 - v)), child: child)),
    child: Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.error_outline, size: 14, color: AppColors.red), const SizedBox(width: 6), Text(msg, style: const TextStyle(fontSize: 11, color: AppColors.red, fontWeight: FontWeight.w600))])));

  void _pickForApproval(String approval) async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'], withData: true);
    if (r != null) setState(() => _approvalFiles[approval] = r.files.single.name);
  }

  IconData _fIcon(String n) { final e = n.split('.').last.toLowerCase(); return e == 'pdf' ? Icons.picture_as_pdf : (e == 'doc' || e == 'docx') ? Icons.description : (e == 'png' || e == 'jpg' || e == 'jpeg') ? Icons.image : Icons.insert_drive_file; }
}

class _SuccessDialog extends StatefulWidget {
  final VoidCallback onDone;
  const _SuccessDialog({required this.onDone});
  @override State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)).animate(_ctrl);
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _ctrl, builder: (_, __) => Opacity(opacity: _opacity.value, child: Transform.scale(scale: _scale.value,
      child: AlertDialog(
        backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(width: 320, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.green.withOpacity(0.1)), child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 48)),
          const SizedBox(height: 16),
          const Text('Data Saved Successfully!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('Template has been saved successfully.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textDim)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 44, child: ElevatedButton(onPressed: widget.onDone,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004C8F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('OK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)))),
        ])),
      ),
    )));
  }
}
