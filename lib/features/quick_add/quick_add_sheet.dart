import 'dart:ui';
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark
                      ? const Color(0xFF1E1E2E).withValues(alpha: 0.96)
                      : Colors.white.withValues(alpha: 0.96),
                  isDark
                      ? const Color(0xFF16162A).withValues(alpha: 0.98)
                      : Colors.white.withValues(alpha: 0.98),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.lightBorder.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.sunsetBright, AppColors.sunset]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quick Actions', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 1),
                              Text('Add a record', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade400, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close, size: 18, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade400),
                            onPressed: () => Navigator.pop(context),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _MedAction(icon: Icons.person_add_alt_1, label: 'Pupil', color: const Color(0xFF6C63FF), isDark: isDark, onTap: () => go(const PupilFormScreen()))),
                            const SizedBox(width: 10),
                            Expanded(child: _MedAction(icon: Icons.speed, label: 'Mileage', color: const Color(0xFF00BFA5), isDark: isDark, onTap: () { Navigator.pop(context); showDialog(context: context, builder: (_) => const MileageDialog()); })),
                            const SizedBox(width: 10),
                            Expanded(child: _MedAction(icon: Icons.school, label: 'Lesson', color: AppColors.sunsetBright, isDark: isDark, onTap: () => go(const LessonFormScreen()))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _MedAction(icon: Icons.event, label: 'Event', color: const Color(0xFFFF6B6B), isDark: isDark, onTap: () => go(const EventFormScreen()))),
                            const SizedBox(width: 10),
                            Expanded(child: _MedAction(icon: Icons.schedule, label: 'Open Slot', color: const Color(0xFFFFA726), isDark: isDark, onTap: () => go(const OpenSlotFormScreen()))),
                            const SizedBox(width: 10),
                            Expanded(child: _MedAction(icon: Icons.payments, label: 'Payment', color: const Color(0xFF4CAF50), isDark: isDark, onTap: () => go(const PaymentFormScreen()))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _MedAction(icon: Icons.receipt_long, label: 'Expense', color: const Color(0xFFEF5350), isDark: isDark, onTap: () => go(const ExpenseFormScreen()))),
                            const SizedBox(width: 10),
                            const Expanded(child: SizedBox()),
                            const SizedBox(width: 10),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _MedAction extends StatelessWidget {
  const _MedAction({required this.icon, required this.label, required this.color, required this.isDark, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.1 : 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: isDark ? 0.12 : 0.1), width: 0.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
