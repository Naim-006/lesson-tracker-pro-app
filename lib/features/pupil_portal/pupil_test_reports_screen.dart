import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/supabase_pupil_provider.dart';
import '../../core/theme/app_colors.dart';

class PupilTestReportsScreen extends ConsumerWidget {
  const PupilTestReportsScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(pupilTestReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Test Reports'),
        backgroundColor: AppColors.sunsetBright,
        foregroundColor: Colors.white,
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading reports',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No test reports yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your instructor will add them here.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, i) {
              final r = reports[i];
              final date = DateTime.tryParse(r['test_date'].toString()) ?? DateTime.now();
              final result = r['result']?.toString() ?? 'pending';
              final color = _resultColor(result);
              final manoeuvres = (r['manoeuvres'] as List? ?? []).cast<String>();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              result == 'pass'
                                  ? Icons.check_circle
                                  : result == 'fail'
                                      ? Icons.cancel
                                      : Icons.schedule,
                              color: color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('d MMM yyyy').format(date),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r['grade_level']?.toString() ?? 'Category B',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
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
                      const SizedBox(height: 16),
                      if (r['test_center_name'] != null &&
                          r['test_center_name'].toString().isNotEmpty)
                        _infoRow(Icons.location_on, 'Test Centre', r['test_center_name'].toString()),
                      if (r['examiner_name'] != null && r['examiner_name'].toString().isNotEmpty)
                        _infoRow(Icons.person, 'Examiner', r['examiner_name'].toString()),
                      _infoRow(Icons.warning_amber, 'Driving Faults', '${r['faults'] ?? 0}'),
                      _infoRow(Icons.warning, 'Serious Faults', '${r['serious_faults'] ?? 0}'),
                      _infoRow(Icons.dangerous, 'Dangerous Faults', '${r['dangerous_faults'] ?? 0}'),
                      if (manoeuvres.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Manoeuvres',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                      if ((r['scales_notes']?.toString() ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _infoRow(Icons.quiz, 'Show Me / Tell Me', r['scales_notes'].toString()),
                      ],
                      if ((r['notes']?.toString() ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _infoRow(Icons.notes, 'Notes', r['notes'].toString()),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.sunsetBright),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
