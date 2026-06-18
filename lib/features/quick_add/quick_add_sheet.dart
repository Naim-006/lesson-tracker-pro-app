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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.sunsetBright, AppColors.sunset]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text('Quick Actions', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                        const Spacer(),
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
                    const SizedBox(height: 14),
                    _buildRow(isDark, [
                      _CompactAction(icon: Icons.person_add_alt_1, label: 'Pupil', color: const Color(0xFF6C63FF), onTap: () => go(const PupilFormScreen())),
                      _CompactAction(icon: Icons.speed, label: 'Mileage', color: const Color(0xFF00BFA5), onTap: () { Navigator.pop(context); showDialog(context: context, builder: (_) => const MileageDialog()); }),
                      _CompactAction(icon: Icons.school, label: 'Lesson', color: AppColors.sunsetBright, onTap: () => go(const LessonFormScreen())),
                      _CompactAction(icon: Icons.event, label: 'Event', color: const Color(0xFFFF6B6B), onTap: () => go(const EventFormScreen())),
                    ]),
                    const SizedBox(height: 8),
                    _buildRow(isDark, [
                      _CompactAction(icon: Icons.schedule, label: 'Slot', color: const Color(0xFFFFA726), onTap: () => go(const OpenSlotFormScreen())),
                      _CompactAction(icon: Icons.payments, label: 'Payment', color: const Color(0xFF4CAF50), onTap: () => go(const PaymentFormScreen())),
                      _CompactAction(icon: Icons.receipt_long, label: 'Expense', color: const Color(0xFFEF5350), onTap: () => go(const ExpenseFormScreen())),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(bool isDark, List<_CompactAction> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i < items.length - 1) const SizedBox(width: 8),
        ],
        if (items.length < 4) ...[
          const SizedBox(width: 8),
          Expanded(child: SizedBox(height: items.length < 4 ? 0 : null)),
        ],
      ],
    );
  }
}

class _CompactAction extends StatelessWidget {
  const _CompactAction({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.1 : 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: isDark ? 0.12 : 0.1), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
