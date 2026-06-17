import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../finances/payment_form_screen.dart';
import '../finances/expense_form_screen.dart';
import '../quick_add/mileage_dialog.dart';
import '../../core/utils/error_handler.dart';
import 'lesson_form_screen.dart';

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              lesson.pupilName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${lesson.time} · ${lesson.duration}min · £${lesson.rate}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            if (lesson.pickupLocation != null) ...[
              const SizedBox(height: 4),
              Text(
                'Pickup: ${lesson.pickupLocation}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            // Add shortcuts
            const Text(
              'Add',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentFormScreen()),
                );
              },
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Add payment'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExpenseFormScreen()),
                );
              },
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('Add expense'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => const MileageDialog(),
                );
              },
              icon: const Icon(Icons.directions_car, size: 18),
              label: const Text('Add mileage'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            // Lesson actions
            if (lesson.status != LessonStatus.completed)
              FilledButton(
                onPressed: () => _updateLessonStatus(context, ref, LessonStatus.completed),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sunsetBright,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Mark complete'),
              ),
            const SizedBox(height: 8),
            if (!lesson.paid)
              OutlinedButton(
                onPressed: () async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return;
                  try {
                    await Supabase.instance.client.from('lessons').update({'paid': true}).eq('id', lesson.id);
                    await Supabase.instance.client.from('payments').insert({
                      'instructor_id': user.id,
                      'pupil_id': lesson.pupilId,
                      'lesson_id': lesson.id,
                      'type': 'income',
                      'amount': lesson.rate,
                      'description': 'Lesson payment - ${lesson.pupilName}',
                      'payment_method': 'cash',
                      'status': 'completed',
                    });
                    if (context.mounted) {
                      ref.invalidate(instructorLessonsProvider);
                      ref.invalidate(instructorPaymentsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lesson marked as paid')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(userFriendlyError(e))),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Mark paid'),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonFormScreen(existing: lesson),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Edit'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _updateLessonStatus(context, ref, LessonStatus.cancelled),
              child: const Text('Cancel lesson'),
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _deleteLesson(context, ref),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
