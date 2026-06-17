import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../diary/event_form_screen.dart';
import '../diary/lesson_form_screen.dart';
import '../diary/open_slot_form_screen.dart';
import '../finances/expense_form_screen.dart';
import '../finances/payment_form_screen.dart';
import '../pupils/pupil_form_screen.dart';
import 'mileage_dialog.dart';

class QuickAddSheet extends ConsumerWidget {
  const QuickAddSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void go(Widget screen) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add_rounded, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text('Add a record in one tap', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(title: 'Records'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _ActionTile(icon: Icons.person_add_alt_1, label: 'Pupil', subtitle: 'Add new student', accentColor: const Color(0xFF6C63FF), onTap: () => go(const PupilFormScreen()))),
                        const SizedBox(width: 12),
                        Expanded(child: _ActionTile(icon: Icons.speed, label: 'Mileage', subtitle: 'Log trip', accentColor: const Color(0xFF00BFA5), onTap: () { Navigator.pop(context); showDialog(context: context, builder: (_) => const MileageDialog()); })),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel(title: 'Planning'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _ActionTile(icon: Icons.school, label: 'Lesson', subtitle: 'Schedule lesson', accentColor: AppColors.sunsetBright, onTap: () => go(const LessonFormScreen()))),
                        const SizedBox(width: 12),
                        Expanded(child: _ActionTile(icon: Icons.event, label: 'Event', subtitle: 'Add calendar event', accentColor: const Color(0xFFFF6B6B), onTap: () => go(const EventFormScreen()))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _ActionTile(icon: Icons.schedule, label: 'Open Slot', subtitle: 'Offer availability', accentColor: const Color(0xFFFFA726), onTap: () => go(const OpenSlotFormScreen()))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(height: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel(title: 'Finances'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _ActionTile(icon: Icons.payments, label: 'Payment', subtitle: 'Record income', accentColor: const Color(0xFF4CAF50), onTap: () => go(const PaymentFormScreen()))),
                        const SizedBox(width: 12),
                        Expanded(child: _ActionTile(icon: Icons.receipt_long, label: 'Expense', subtitle: 'Log outgoing', accentColor: const Color(0xFFEF5350), onTap: () => go(const ExpenseFormScreen()))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.8));
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? accentColor.withValues(alpha: 0.08) : accentColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }
}
