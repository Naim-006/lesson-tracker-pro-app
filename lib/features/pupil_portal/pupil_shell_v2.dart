import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'pupil_home_screen_v2.dart';
import 'pupil_progress_screen.dart';
import 'pupil_messaging_screen.dart';
import 'pupil_test_reports_screen.dart';
import 'pupil_menu_screen.dart';

class PupilShell extends ConsumerStatefulWidget {
  const PupilShell({super.key});

  @override
  ConsumerState<PupilShell> createState() => _PupilShellState();
}

class _PupilShellState extends ConsumerState<PupilShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late List<AnimationController> _dotControllers;

  static const _tabs = [
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Home', color: AppColors.sunsetBright),
    (icon: Icons.trending_up_outlined, active: Icons.trending_up_rounded, label: 'Progress', color: Color(0xFF10B981)),
    (icon: Icons.assignment_outlined, active: Icons.assignment_rounded, label: 'Tests', color: Color(0xFF3B82F6)),
    (icon: Icons.chat_outlined, active: Icons.chat_rounded, label: 'Chat', color: Color(0xFF8B5CF6)),
    (icon: Icons.grid_view_outlined, active: Icons.grid_view_rounded, label: 'Menu', color: AppColors.sunset),
  ];

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(5, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 400)));
    _dotControllers[0].value = 1.0;
  }

  @override
  void dispose() {
    for (final c in _dotControllers) { c.dispose(); }
    super.dispose();
  }

  void _onTap(int i) {
    if (i == _currentIndex) return;
    setState(() {
      _dotControllers[_currentIndex].reverse();
      _currentIndex = i;
      _dotControllers[i].forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = const [
      PupilHomeScreenV2(),
      PupilProgressScreen(),
      PupilTestReportsScreen(),
      PupilMessagingScreen(),
      PupilMenuScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF6F4F0),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _GlassBottomNav(
        selectedIndex: _currentIndex,
        tabs: _tabs,
        isDark: isDark,
        onTap: _onTap,
        dotControllers: _dotControllers,
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  const _GlassBottomNav({
    required this.selectedIndex,
    required this.tabs,
    required this.isDark,
    required this.onTap,
    required this.dotControllers,
  });

  final int selectedIndex;
  final List<({IconData icon, IconData active, String label, Color color})> tabs;
  final bool isDark;
  final ValueChanged<int> onTap;
  final List<AnimationController> dotControllers;

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
                : Colors.white.withValues(alpha: 0.82),
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? t.color.withValues(alpha: isDark ? 0.2 : 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  sel ? t.active : t.icon,
                                  size: sel ? 24 : 22,
                                  color: sel
                                      ? t.color
                                      : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                                ),
                                if (sel)
                                  Positioned(
                                    bottom: -4,
                                    child: FadeTransition(
                                      opacity: dotControllers[i],
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: t.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
