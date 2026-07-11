import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';

class PupilLessonsScreen extends StatefulWidget {
  const PupilLessonsScreen({super.key});

  @override
  State<PupilLessonsScreen> createState() => _PupilLessonsScreenState();
}

class _PupilLessonsScreenState extends State<PupilLessonsScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> _lessons = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    if (user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('lessons')
          .select('*, instructors:profiles!instructor_id(full_name, business_name)')
          .eq('pupil_id', user!.id)
          .order('date', ascending: false);

      if (mounted) {
        setState(() {
          _lessons = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_filter) {
      case 'upcoming':
        return _lessons.where((l) {
          final d = DateTime.tryParse(l['date'] ?? '');
          return d != null && !d.isBefore(today);
        }).toList();
      case 'past':
        return _lessons.where((l) {
          final d = DateTime.tryParse(l['date'] ?? '');
          return d != null && d.isBefore(today);
        }).toList();
      default:
        return _lessons;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      case 'no_show': return AppColors.warning;
      default: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lessons'),
        backgroundColor: AppColors.sunsetBright,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _FilterChip(label: 'All', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Upcoming', selected: _filter == 'upcoming', onTap: () => setState(() => _filter = 'upcoming')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Past', selected: _filter == 'past', onTap: () => setState(() => _filter = 'past')),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No ${_filter == 'all' ? '' : '$_filter '}lessons',
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final l = filtered[i];
                            final date = DateTime.tryParse(l['date'] ?? '');
                            final instructor = l['instructors'] as Map<String, dynamic>?;
                            final instructorName = instructor?['full_name'] as String? ?? instructor?['business_name'] as String? ?? 'Instructor';
                            final status = l['status']?.toString() ?? 'scheduled';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.sunsetBright.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      status == 'completed' ? Icons.check_circle_rounded
                                          : status == 'cancelled' ? Icons.cancel_rounded
                                          : Icons.schedule_rounded,
                                      color: _statusColor(status), size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              date != null ? DateFormat('d MMM yyyy').format(date) : 'Unknown',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor(status)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${l['time'] ?? ''} · ${l['duration'] ?? 60} min · With $instructorName',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        if (l['rate'] != null && (l['rate'] as num) > 0)
                                          Text('\u00a3${l['rate']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sunsetBright)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.sunsetBright : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.sunsetBright : Colors.grey.shade400),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}
