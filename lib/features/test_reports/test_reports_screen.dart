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
  String _filter = 'all';

  Color _resultColor(String? result) {
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

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> reports) {
    if (_filter == 'all') return reports;
    return reports.where((r) => r['result'] == _filter).toList();
  }

  Future<void> _deleteReport(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this test report?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          final date = DateTime.tryParse(r['test_date'].toString()) ?? DateTime.now();
          final manoeuvres = (r['manoeuvres'] as List? ?? []).cast<String>();
          final result = r['result']?.toString() ?? 'pending';
          final color = _resultColor(result);

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        result == 'pass'
                            ? Icons.check_circle
                            : result == 'fail'
                                ? Icons.cancel
                                : Icons.schedule,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pupilName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM yyyy').format(date),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        result.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _DetailSection(
                  title: 'Test Information',
                  children: [
                    _detailRow('Grade', r['grade_level']?.toString() ?? 'N/A'),
                    _detailRow('Test Centre', r['test_center_name']?.toString() ?? 'N/A'),
                    _detailRow('Examiner', r['examiner_name']?.toString() ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Faults',
                  children: [
                    _detailRow('Driving faults', '${r['faults'] ?? 0}'),
                    _detailRow('Serious faults', '${r['serious_faults'] ?? 0}'),
                    _detailRow('Dangerous faults', '${r['dangerous_faults'] ?? 0}'),
                  ],
                ),
                if (manoeuvres.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Manoeuvres',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: manoeuvres.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.sunsetBright.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              m,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sunsetBright,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
                if ((r['scales_notes']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Show Me / Tell Me',
                    children: [Text(r['scales_notes'].toString())],
                  ),
                ],
                if ((r['aural_notes']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Additional Notes',
                    children: [Text(r['aural_notes'].toString())],
                  ),
                ],
                if ((r['notes']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'General Notes',
                    children: [Text(r['notes'].toString())],
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TestReportFormScreen(existingReport: r),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteReport(r['id'] as String);
                        },
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(instructorTestReportsProvider);
    final reportsList = reports.value ?? [];
    final filtered = _applyFilter(reportsList);

    final totalTests = reportsList.length;
    final passedTests = reportsList.where((r) => r['result'] == 'pass').length;
    final passRate = totalTests > 0 ? (passedTests / totalTests * 100).toStringAsFixed(0) : '0';
    final failedTests = reportsList.where((r) => r['result'] == 'fail').length;
    final pendingTests = reportsList.where((r) => r['result'] == 'pending').length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Test Reports', style: TextStyle(fontWeight: FontWeight.w800)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sunsetBright, AppColors.sunsetBright.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sunsetBright, AppColors.sunsetBright.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
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
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PerformanceMetric(
                            label: 'Failed',
                            value: '$failedTests',
                            icon: Icons.cancel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PerformanceMetric(
                            label: 'Pending',
                            value: '$pendingTests',
                            icon: Icons.schedule,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pass',
                      isSelected: _filter == 'pass',
                      onTap: () => setState(() => _filter = 'pass'),
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Fail',
                      isSelected: _filter == 'fail',
                      onTap: () => setState(() => _filter = 'fail'),
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pending',
                      isSelected: _filter == 'pending',
                      onTap: () => setState(() => _filter = 'pending'),
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          reports.value == null
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : filtered.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              _filter == 'all'
                                  ? 'No test reports yet'
                                  : 'No ${_filter.toLowerCase()} reports',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final r = filtered[i];
                            final pupilData = r['pupils'];
                            final pupilName = pupilData != null
                                ? '${pupilData['first_name'] ?? ''} ${pupilData['last_name'] ?? ''}'.trim()
                                : (r['pupil_name']?.toString() ?? 'Unknown');
                            final resolvedName = pupilName.isNotEmpty ? pupilName : 'Unknown';
                            return _ReportCard(
                              report: r,
                              pupilName: resolvedName,
                              resultColor: _resultColor(r['result']?.toString()),
                              onTap: () => _showDetail(context, r, resolvedName),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TestReportFormScreen()),
        ),
        backgroundColor: AppColors.sunsetBright,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  const _PerformanceMetric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

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
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? AppColors.sunsetBright) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? AppColors.sunsetBright) : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.pupilName,
    required this.resultColor,
    required this.onTap,
  });

  final Map<String, dynamic> report;
  final String pupilName;
  final Color resultColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(report['test_date'].toString()) ?? DateTime.now();
    final manoeuvres = (report['manoeuvres'] as List? ?? []).cast<String>();
    final faults = report['faults'] as int? ?? 0;
    final serious = report['serious_faults'] as int? ?? 0;
    final dangerous = report['dangerous_faults'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      report['result'] == 'pass'
                          ? Icons.check_circle
                          : report['result'] == 'fail'
                              ? Icons.cancel
                              : Icons.schedule,
                      color: resultColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pupilName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d MMM yyyy').format(date),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report['result']?.toString().toUpperCase() ?? 'N/A',
                      style: TextStyle(
                        color: resultColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MetricChip(label: 'Grade: ${report['grade_level'] ?? 'N/A'}'),
                  const SizedBox(width: 8),
                  if (manoeuvres.isNotEmpty)
                    _MetricChip(label: '${manoeuvres.length} manoeuvres'),
                  if (faults > 0) ...[
                    const SizedBox(width: 8),
                    _MetricChip(label: '$faults faults'),
                  ],
                ],
              ),
              if (serious > 0 || dangerous > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (serious > 0)
                      _MetricChip(
                        label: '$serious serious',
                        color: AppColors.error,
                      ),
                    if (dangerous > 0) ...[
                      const SizedBox(width: 8),
                      _MetricChip(
                        label: '$dangerous dangerous',
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color ?? Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
