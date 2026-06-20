import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'pupil_home_screen_v2.dart';
import 'pupil_journey_screen.dart';
import 'pupil_messages_screen.dart';
import 'pupil_menu_screen.dart';

class PupilShell extends ConsumerStatefulWidget {
  const PupilShell({super.key});

  @override
  ConsumerState<PupilShell> createState() => _PupilShellState();
}

class _PupilShellState extends ConsumerState<PupilShell> {
  int _currentIndex = 0;

  static const _tabs = [
    (icon: Icons.home_rounded, active: Icons.home_rounded, label: 'Home', color: AppColors.sunsetBright),
    (icon: Icons.explore_rounded, active: Icons.explore_rounded, label: 'Journey', color: Color(0xFF10B981)),
    (icon: Icons.chat_rounded, active: Icons.chat_rounded, label: 'Chat', color: Color(0xFF3B82F6)),
    (icon: Icons.grid_view_rounded, active: Icons.grid_view_rounded, label: 'Menu', color: AppColors.sunset),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF6F4F0),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          PupilHomeScreenV2(),
          PupilJourneyScreen(),
          PupilMessagesScreen(),
          PupilMenuScreen(),
        ],
      ),
      floatingActionButton: _buildFAB(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _GlassBottomNav(
        selectedIndex: _currentIndex,
        tabs: _tabs,
        isDark: isDark,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    return Container(
      width: 58,
      height: 58,
      margin: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.sunsetBright, Color(0xFFE85D3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sunsetBright.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showQuickActions,
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showQuickActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _QuickActionsSheet(isDark: isDark),
    );
  }
}

// ─── Glass Bottom Nav ───────────────────────────────────────
class _GlassBottomNav extends StatelessWidget {
  const _GlassBottomNav({
    required this.selectedIndex,
    required this.tabs,
    required this.isDark,
    required this.onTap,
  });

  final int selectedIndex;
  final List<({IconData icon, IconData active, String label, Color color})> tabs;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (i) {
                  final t = tabs[i];
                  final sel = selectedIndex == i;
                  return Expanded(
                    child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? t.color.withValues(alpha: isDark ? 0.2 : 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            sel ? t.active : t.icon,
                            size: sel ? 24 : 22,
                            color: sel
                                ? t.color
                                : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            t.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel
                                  ? t.color
                                  : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions Bottom Sheet ─────────────────────────────
class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.sunsetBright, Color(0xFFE85D3A)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'What would you like to do?',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'Book a Lesson',
                    subtitle: 'View available slots',
                    color: AppColors.sunsetBright,
                    isDark: isDark,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.chat_rounded,
                    label: 'Message Instructor',
                    subtitle: 'Send a message',
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.payment_rounded,
                    label: 'View Payments',
                    subtitle: 'Check invoices',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white.withValues(alpha: 0.35) : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
