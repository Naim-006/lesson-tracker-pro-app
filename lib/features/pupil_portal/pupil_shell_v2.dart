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
  late PageController _pageController;
  late AnimationController _navAnimController;

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
    _pageController = PageController();
    _navAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _navAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navAnimController.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (i == _currentIndex) return;
    _pageController.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    setState(() => _currentIndex = i);
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
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF7F5F2),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      extendBody: true,
      bottomNavigationBar: _FloatingNav(
        currentIndex: _currentIndex,
        tabs: _tabs,
        isDark: isDark,
        onTap: _onTap,
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.currentIndex, required this.tabs, required this.isDark, required this.onTap});
  final int currentIndex;
  final List<({IconData icon, IconData active, String label, Color color})> tabs;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (i) {
                  final t = tabs[i];
                  final sel = currentIndex == i;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? t.color.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            width: sel ? 22 : 24,
                            height: sel ? 22 : 24,
                            alignment: Alignment.center,
                            child: Icon(
                              sel ? t.active : t.icon,
                              size: sel ? 22 : 20,
                              color: sel ? t.color : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (sel || !sel)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              width: sel ? 50 : 0,
                              child: AnimatedOpacity(
                                opacity: sel ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  t.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.color),
                                ),
                              ),
                            ),
                        ],
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