import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../finances/request_payment_form_screen.dart';
import '../../core/utils/error_handler.dart';
import 'lesson_form_screen.dart';
import 'mark_paid_dialog.dart';

class LessonDetailSheet extends ConsumerWidget {
  const LessonDetailSheet({super.key, required this.lesson});

  final Lesson lesson;

  String _mapLessonStatus(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed: return 'completed';
      case LessonStatus.cancelled: return 'cancelled';
      case LessonStatus.noShow: return 'no_show';
      default: return 'scheduled';
    }
  }

  Future<void> _updateLessonStatus(BuildContext context, WidgetRef ref, LessonStatus status) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('lessons').update({
        'status': _mapLessonStatus(status),
      }).eq('id', lesson.id);

      if (context.mounted) {
        ref.invalidate(instructorLessonsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  Future<void> _deleteLesson(BuildContext context, WidgetRef ref) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('lessons').delete().eq('id', lesson.id);

      if (context.mounted) {
        ref.invalidate(instructorLessonsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pupilAsync = ref.watch(pupilByIdProvider(lesson.pupilId));
    final unpaidLessonsAsync = ref.watch(pupilUnpaidLessonsProvider(lesson.pupilId));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Lesson Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.sunsetBright.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      lesson.pupilName.isNotEmpty ? lesson.pupilName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.sunsetBright,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.pupilName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lesson.time} · ${lesson.duration}min',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '£${lesson.rate.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            
            if (lesson.pickupLocation != null && lesson.pickupLocation!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lesson.pickupLocation!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Unpaid Lessons / Payment Due Section
            unpaidLessonsAsync.when(
              data: (unpaidLessons) {
                if (unpaidLessons.isEmpty) return const SizedBox.shrink();
                
                final totalDue = unpaidLessons.fold<double>(0, (sum, l) {
                  final rate = (l['rate'] as num?)?.toDouble() ?? 0;
                  return sum + rate;
                });
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          const Text('Payment Due', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const Spacer(),
                          Text(
                            '${unpaidLessons.length} lessons',
                            style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Total Due: ',
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                          ),
                          Text(
                            '£${totalDue.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.warning),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RequestPaymentFormScreen()),
                                );
                              },
                              icon: const Icon(Icons.request_quote, size: 16),
                              label: const Text('Request Payment'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                foregroundColor: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            if (unpaidLessonsAsync.value?.isNotEmpty == true) const SizedBox(height: 20),
            
            // Pupil Contact
            pupilAsync.when(
              data: (pupil) {
                if (pupil == null) return const SizedBox.shrink();
                final phone = pupil['phone'] as String? ?? '';
                final email = pupil['email'] as String? ?? '';
                
                if (phone.isEmpty && email.isEmpty) return const SizedBox.shrink();
                
                return Row(
                  children: [
                    if (phone.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchPhone(phone),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    if (phone.isNotEmpty && email.isNotEmpty) const SizedBox(width: 8),
                    if (email.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchEmail(email),
                          icon: const Icon(Icons.email, size: 16),
                          label: const Text('Email'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 20),
            
            // Main Actions
            if (lesson.status != LessonStatus.completed)
              FilledButton.icon(
                onPressed: () => _updateLessonStatus(context, ref, LessonStatus.completed),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Mark Complete'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sunsetBright,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            
            if (lesson.status != LessonStatus.completed && !lesson.paid) const SizedBox(height: 8),
            
            if (!lesson.paid)
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await showModalBottomSheet<MarkPaidResult>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => MarkPaidDialog(lesson: lesson),
                  );
                  if (result != null && context.mounted) {
                    ref.invalidate(instructorLessonsProvider);
                    ref.invalidate(instructorPaymentsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.skipRecording
                          ? 'Lesson marked as paid'
                          : 'Lesson marked as paid — ${result.paymentMethod![0].toUpperCase()}${result.paymentMethod!.substring(1)}')),
                    );
                  }
                },
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Mark Paid'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Secondary Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonFormScreen(existing: lesson),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (!lesson.paid) const SizedBox(width: 8),
                if (!lesson.paid)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RequestPaymentFormScreen()),
                        );
                      },
                      icon: const Icon(Icons.request_quote, size: 16),
                      label: const Text('Request'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppColors.sunsetBright,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Danger Zone
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _updateLessonStatus(context, ref, LessonStatus.cancelled),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteLesson(context, ref),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
