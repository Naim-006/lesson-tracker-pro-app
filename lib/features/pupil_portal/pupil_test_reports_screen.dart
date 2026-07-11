import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/supabase_pupil_provider.dart';
import '../../core/theme/app_colors.dart';

class PupilTestReportsScreen extends ConsumerWidget {
  const PupilTestReportsScreen({super.key});

  Color _resultColor(String? r) {
    switch (r) {
      case 'pass': return AppColors.success;
      case 'fail': return AppColors.error;
      case 'pending': return AppColors.warning;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(pupilTestReportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Reports'),
        backgroundColor: AppColors.sunsetBright,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)),
        error: (_, __) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Could not load reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
          ],
        )),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 72, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No Test Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Text('Your instructor will add them here.', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ));
          }

          final total = reports.length;
          final passed = reports.where((r) => r['result'] == 'pass').length;
          final failed = reports.where((r) => r['result'] == 'fail').length;
          final pending = reports.where((r) => r['result'] == 'pending').length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pupilTestReportsProvider),
            color: AppColors.sunsetBright,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      const Text('Test Performance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                      const SizedBox(height: 16),
                      Row(children: [
                        _StatBox(label: 'Total', value: '$total', color: Colors.white),
                        const SizedBox(width: 10),
                        _StatBox(label: 'Passed', value: '$passed', color: AppColors.success),
                        const SizedBox(width: 10),
                        _StatBox(label: 'Failed', value: '$failed', color: AppColors.error),
                        const SizedBox(width: 10),
                        _StatBox(label: 'Pending', value: '$pending', color: AppColors.warning),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...reports.map((r) {
                  final date = DateTime.tryParse(r['test_date']?.toString() ?? '');
                  final result = r['result']?.toString() ?? 'pending';
                  final color = _resultColor(result);
                  final manoeuvres = (r['manoeuvres'] as List? ?? []).cast<String>();
                  final faults = r['faults'] as int? ?? 0;
                  final serious = r['serious_faults'] as int? ?? 0;
                  final dangerous = r['dangerous_faults'] as int? ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                            child: Icon(
                              result == 'pass' ? Icons.check_circle_rounded : result == 'fail' ? Icons.cancel_rounded : Icons.schedule_rounded,
                              color: color, size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(date != null ? DateFormat('d MMM yyyy').format(date) : 'Unknown date', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                Text(r['grade_level']?.toString() ?? 'Practical Test', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(result.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        if (r['test_center_name'] != null || r['examiner_name'] != null) ...[
                          Row(children: [
                            if (r['test_center_name'] != null) ...[
                              Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(child: Text(r['test_center_name'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                            ],
                            if (r['examiner_name'] != null) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(r['examiner_name'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ]),
                          const SizedBox(height: 10),
                        ],
                        if (faults > 0 || serious > 0 || dangerous > 0)
                          Wrap(spacing: 8, runSpacing: 6, children: [
                            if (faults > 0) _FaultChip('$faults Driving', AppColors.warning),
                            if (serious > 0) _FaultChip('$serious Serious', AppColors.error),
                            if (dangerous > 0) _FaultChip('$dangerous Dangerous', AppColors.error),
                          ]),
                        if (manoeuvres.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(spacing: 6, runSpacing: 6, children: manoeuvres.map((m) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.15))),
                            child: Text(m, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sunsetBright)),
                          )).toList()),
                        ],
                        if (r['notes'] != null && r['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                            child: Text(r['notes'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label; final String value; final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _FaultChip extends StatelessWidget {
  final String text; final Color color;
  const _FaultChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
