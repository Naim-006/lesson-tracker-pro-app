import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';

class TestReportFormScreen extends ConsumerStatefulWidget {
  final Pupil? pupil;
  final Map<String, dynamic>? existingReport;

  const TestReportFormScreen({super.key, this.pupil, this.existingReport});

  @override
  ConsumerState<TestReportFormScreen> createState() => _TestReportFormScreenState();
}

class _TestReportFormScreenState extends ConsumerState<TestReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Pupil? _pupil;
  DateTime _date = DateTime.now();
  final _grade = TextEditingController(text: 'Category B');
  final _manoeuvres = TextEditingController();
  final _scales = TextEditingController();
  final _aural = TextEditingController();
  final _notes = TextEditingController();
  final _testCenter = TextEditingController();
  final _examiner = TextEditingController();
  final _faults = TextEditingController(text: '0');
  final _seriousFaults = TextEditingController(text: '0');
  final _dangerousFaults = TextEditingController(text: '0');
  TestResult _result = TestResult.pending;
  bool _saving = false;

  bool get _isEditing => widget.existingReport != null;

  @override
  void initState() {
    super.initState();
    _pupil = widget.pupil;

    if (_isEditing) {
      final r = widget.existingReport!;
      _date = DateTime.tryParse(r['test_date'].toString()) ?? DateTime.now();
      _grade.text = r['grade_level']?.toString() ?? 'Category B';
      _result = _parseResult(r['result']?.toString());
      _manoeuvres.text = (r['manoeuvres'] as List? ?? []).join(', ');
      _scales.text = r['scales_notes']?.toString() ?? '';
      _aural.text = r['aural_notes']?.toString() ?? '';
      _notes.text = r['notes']?.toString() ?? '';
      _testCenter.text = r['test_center_name']?.toString() ?? '';
      _examiner.text = r['examiner_name']?.toString() ?? '';
      _faults.text = (r['faults'] as int? ?? 0).toString();
      _seriousFaults.text = (r['serious_faults'] as int? ?? 0).toString();
      _dangerousFaults.text = (r['dangerous_faults'] as int? ?? 0).toString();
    }
  }

  @override
  void dispose() {
    _grade.dispose();
    _manoeuvres.dispose();
    _scales.dispose();
    _aural.dispose();
    _notes.dispose();
    _testCenter.dispose();
    _examiner.dispose();
    _faults.dispose();
    _seriousFaults.dispose();
    _dangerousFaults.dispose();
    super.dispose();
  }

  TestResult _parseResult(String? value) {
    switch (value) {
      case 'pass':
        return TestResult.pass;
      case 'fail':
        return TestResult.fail;
      default:
        return TestResult.pending;
    }
  }

  String _mapTestResult(TestResult result) {
    switch (result) {
      case TestResult.pass:
        return 'pass';
      case TestResult.fail:
        return 'fail';
      case TestResult.pending:
        return 'pending';
    }
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pupil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pupil')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    final data = {
      'instructor_id': user.id,
      'pupil_id': _pupil!.id,
      'pupil_name': _pupil!.fullName,
      'test_date': _date.toIso8601String().split('T')[0],
      'grade_level': _grade.text.trim(),
      'result': _mapTestResult(_result),
      'manoeuvres': _manoeuvres.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'scales_notes': _scales.text.trim(),
      'aural_notes': _aural.text.trim(),
      'notes': _notes.text.trim(),
      'test_center_name': _testCenter.text.trim().isEmpty ? null : _testCenter.text.trim(),
      'examiner_name': _examiner.text.trim().isEmpty ? null : _examiner.text.trim(),
      'faults': _parseInt(_faults.text),
      'serious_faults': _parseInt(_seriousFaults.text),
      'dangerous_faults': _parseInt(_dangerousFaults.text),
    };

    try {
      if (_isEditing) {
        await Supabase.instance.client
            .from('test_reports')
            .update(data)
            .eq('id', widget.existingReport!['id']);
      } else {
        await Supabase.instance.client.from('test_reports').insert(data);
      }

      if (mounted) {
        ref.invalidate(instructorTestReportsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Test report updated' : 'Test report saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final instructorPupils = ref.watch(instructorPupilsProvider);

    final pupils = instructorPupils.value?.map((link) {
          final pupilData = link['pupils'] ?? <String, dynamic>{};
          return Pupil(
            id: pupilData['id'],
            firstName: pupilData['first_name'] ?? '',
            lastName: pupilData['last_name'] ?? '',
            phone: pupilData['phone'] ?? '',
            email: pupilData['email'] ?? '',
            postcode: pupilData['postcode'],
            pickupAddresses: pupilData['pickup_addresses'] != null
                ? List<String>.from(pupilData['pickup_addresses'])
                : [],
            hourlyRate: (pupilData['hourly_rate'] as num?)?.toDouble() ?? 40.0,
          );
        }).toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Test Report' : 'New Test Report',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.sunsetBright,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: _save,
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionCard(
              icon: Icons.person_outline,
              title: 'Pupil',
              children: [
                DropdownButtonFormField<Pupil>(
                  initialValue: _pupil,
                  isExpanded: true,
                  decoration: _inputDecoration('Select pupil'),
                  items: pupils.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.fullName));
                  }).toList(),
                  onChanged: _isEditing
                      ? null
                      : (p) => setState(() => _pupil = p),
                  validator: (value) => value == null ? 'Please select a pupil' : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              icon: Icons.assignment,
              title: 'Test Details',
              children: [
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.sunsetBright),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Test date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('d MMM yyyy').format(_date),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _grade,
                  decoration: _inputDecoration('Grade / category'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Please enter a grade' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TestResult>(
                  initialValue: _result,
                  isExpanded: true,
                  decoration: _inputDecoration('Result'),
                  items: TestResult.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(labelEnum(r))))
                      .toList(),
                  onChanged: (v) => setState(() => _result = v!),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              icon: Icons.assessment,
              title: 'Test Centre & Examiner',
              children: [
                TextFormField(
                  controller: _testCenter,
                  decoration: _inputDecoration('Test centre name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _examiner,
                  decoration: _inputDecoration('Examiner name'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              icon: Icons.warning_amber,
              title: 'Faults',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _faultField(_faults, 'Driving faults'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _faultField(_seriousFaults, 'Serious'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _faultField(_dangerousFaults, 'Dangerous'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              icon: Icons.sports_score,
              title: 'Performance',
              children: [
                TextFormField(
                  controller: _manoeuvres,
                  decoration: _inputDecoration('Manoeuvres (comma separated)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _scales,
                  decoration: _inputDecoration('Show me / tell me notes'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _aural,
                  decoration: _inputDecoration('Additional notes'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              icon: Icons.note,
              title: 'General Notes',
              children: [
                TextFormField(
                  controller: _notes,
                  decoration: _inputDecoration('Notes'),
                  maxLines: 4,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.sunsetBright, AppColors.sunsetBright.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sunsetBright.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _isEditing ? 'Update report' : 'Save report',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sunsetBright.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.sunsetBright, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _faultField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
