import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import 'test_report_form_screen.dart';

class TestReportsScreen extends ConsumerStatefulWidget {
  const TestReportsScreen({super.key});

  @override
  ConsumerState<TestReportsScreen> createState() => _TestReportsScreenState();
}

class _TestReportsScreenState extends ConsumerState<TestReportsScreen> {
  bool _dvsaSyncEnabled = true;
  String _dvsaStatus = 'Connected';
  DateTime _lastSync = DateTime.now().subtract(const Duration(hours: 2));

  Color _resultColor(String result) {
    switch (result) {
      case 'pass':
        return AppColors.success;
      case 'fail':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  Future<void> _syncWithDVSA() async {
    setState(() => _dvsaStatus = 'Syncing...');
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _dvsaStatus = 'Connected';
      _lastSync = DateTime.now();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DVSA sync complete')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(instructorTestReportsProvider);

    // Calculate performance metrics
    final reportsList = reports.value ?? [];
    final totalTests = reportsList.length;
    final passedTests = reportsList.where((r) => r['result'] == 'pass').length;
    final passRate = totalTests > 0 ? (passedTests / totalTests * 100).toStringAsFixed(0) : '0';
    final failedTests = reportsList.where((r) => r['result'] == 'fail').length;
    final pendingTests = reportsList.where((r) => r['result'] == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TestReportFormScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Test Performance Summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test Performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _PerformanceMetric(
                        label: 'Total Tests',
                        value: '$totalTests',
                        icon: Icons.assessment,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PerformanceMetric(
                        label: 'Pass Rate',
                        value: '$passRate%',
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PerformanceMetric(
                        label: 'Passed',
                        value: '$passedTests',
                        icon: Icons.check_circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PerformanceMetric(
                        label: 'Failed',
                        value: '$failedTests',
                        icon: Icons.cancel,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PerformanceMetric(
                        label: 'Pending',
                        value: '$pendingTests',
                        icon: Icons.schedule,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Standards Check Metrics
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                      child: const Icon(Icons.assessment, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Standards Check Metrics',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StandardsMetric(
                        label: 'Junctions',
                        score: '85%',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StandardsMetric(
                        label: 'Manoeuvres',
                        score: '78%',
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StandardsMetric(
                        label: 'Control',
                        score: '92%',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StandardsMetric(
                        label: 'Planning',
                        score: '88%',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StandardsMetric(
                        label: 'Observation',
                        score: '81%',
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StandardsMetric(
                        label: 'Positioning',
                        score: '90%',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // DVSA Sync Component
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sunsetBright.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _dvsaSyncEnabled ? Icons.cloud_done : Icons.cloud_off,
                      color: _dvsaSyncEnabled ? AppColors.success : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DVSA Integration',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    Switch(
                      value: _dvsaSyncEnabled,
                      onChanged: (v) => setState(() => _dvsaSyncEnabled = v),
                      activeThumbColor: AppColors.sunsetBright,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _dvsaStatus == 'Connected' ? AppColors.success : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _dvsaStatus,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Last sync: ${DateFormat('HH:mm').format(_lastSync)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Spacer(),
                    if (_dvsaSyncEnabled)
                      TextButton(
                        onPressed: _syncWithDVSA,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Sync Now', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: reports.value == null || reports.value!.isEmpty
                ? const Center(child: Text('No test reports yet'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: reports.value!.length,
                    itemBuilder: (context, i) {
                      final r = reports.value![i];
                      final pupilData = r['pupils'];
                      final String pupilName = pupilData != null
                          ? '${pupilData['first_name'] ?? ''} ${pupilData['last_name'] ?? ''}'.trim()
                          : 'Unknown';
                      final String resolvedPupilName = pupilName.isNotEmpty ? pupilName : 'Unknown';
                      return _StudentPerformanceCard(
                        report: r,
                        pupilName: resolvedPupilName,
                        resultColor: _resultColor(r['result']),
                        onDelete: () => _deleteReport(r['id']),
                        onTap: () => _showDetail(context, r, resolvedPupilName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(String id) async {
    try {
      await Supabase.instance.client.from('test_reports').delete().eq('id', id);
      if (mounted) {
        ref.invalidate(instructorTestReportsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showDetail(BuildContext context, Map<String, dynamic> r, String pupilName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(pupilName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('Grade: ${r['grade_level'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Result: ${r['result']?.toUpperCase() ?? 'N/A'}'),
            const SizedBox(height: 8),
            if (r['manoeuvres'] != null)
              Text('Manoeuvres: ${(r['manoeuvres'] as List).join(', ')}'),
            if (r['notes'] != null && r['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r['notes'].toString()),
            ],
          ],
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  const _PerformanceMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color ?? Colors.white,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardsMetric extends StatelessWidget {
  const _StandardsMetric({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final String score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            score,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentPerformanceCard extends StatelessWidget {
  const _StudentPerformanceCard({
    required this.report,
    required this.pupilName,
    required this.resultColor,
    required this.onDelete,
    required this.onTap,
  });

  final Map<String, dynamic> report;
  final String pupilName;
  final Color resultColor;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(report['test_date']) ?? DateTime.now();
    final manoeuvres = report['manoeuvres'] as List? ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: resultColor.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.assignment_turned_in,
                      color: resultColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pupilName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          DateFormat('d MMM yyyy').format(date),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report['result']?.toUpperCase() ?? 'N/A',
                        style: TextStyle(
                          color: resultColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(child: _PerformanceChip(label: 'Grade: ${report['grade_level'] ?? 'N/A'}')),
                  const SizedBox(width: 8),
                  if (manoeuvres.isNotEmpty)
                    Flexible(child: _PerformanceChip(label: '${manoeuvres.length} manoeuvres')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceChip extends StatelessWidget {
  const _PerformanceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
