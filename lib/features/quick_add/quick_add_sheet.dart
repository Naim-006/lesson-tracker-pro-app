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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark
                      ? const Color(0xFF1E1E2E).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  isDark
                      ? const Color(0xFF16162A).withValues(alpha: 0.98)
                      : Colors.white.withValues(alpha: 0.98),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.lightBorder.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.sunsetBright, AppColors.sunset],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.sunsetBright.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Actions',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Add a record instantly',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close, size: 20, color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.grey.shade500),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(title: 'Records', isDark: isDark),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _QuickActionCard(
                              icon: Icons.person_add_alt_1,
                              label: 'Pupil',
                              subtitle: 'Add student',
                              color: const Color(0xFF6C63FF),
                              isDark: isDark,
                              onTap: () => go(const PupilFormScreen()),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _QuickActionCard(
                              icon: Icons.speed,
                              label: 'Mileage',
                              subtitle: 'Log trip',
                              color: const Color(0xFF00BFA5),
                              isDark: isDark,
                              onTap: () {
                                Navigator.pop(context);
                                showDialog(context: context, builder: (_) => const MileageDialog());
                              },
                            )),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionHeader(title: 'Planning', isDark: isDark),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _QuickActionCard(
                              icon: Icons.school,
                              label: 'Lesson',
                              subtitle: 'Schedule',
                              color: AppColors.sunsetBright,
                              isDark: isDark,
                              onTap: () => go(const LessonFormScreen()),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _QuickActionCard(
                              icon: Icons.event,
                              label: 'Event',
                              subtitle: 'Calendar',
                              color: const Color(0xFFFF6B6B),
                              isDark: isDark,
                              onTap: () => go(const EventFormScreen()),
                            )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _QuickActionCard(
                              icon: Icons.schedule,
                              label: 'Open Slot',
                              subtitle: 'Offer time',
                              color: const Color(0xFFFFA726),
                              isDark: isDark,
                              onTap: () => go(const OpenSlotFormScreen()),
                            )),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionHeader(title: 'Finances', isDark: isDark),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _QuickActionCard(
                              icon: Icons.payments,
                              label: 'Payment',
                              subtitle: 'Record income',
                              color: const Color(0xFF4CAF50),
                              isDark: isDark,
                              onTap: () => go(const PaymentFormScreen()),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _QuickActionCard(
                              icon: Icons.receipt_long,
                              label: 'Expense',
                              subtitle: 'Log outgoing',
                              color: const Color(0xFFEF5350),
                              isDark: isDark,
                              onTap: () => go(const ExpenseFormScreen()),
                            )),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: isDark ? 0.12 : 0.08),
                color.withValues(alpha: isDark ? 0.06 : 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.15 : 0.12),
              width: 1.0,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
