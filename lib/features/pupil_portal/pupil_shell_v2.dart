import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'pupil_home_screen_v2.dart';
import 'pupil_progress_screen.dart';
import 'pupil_test_reports_screen.dart';
import 'pupil_messaging_screen.dart';
import 'pupil_menu_screen.dart';

class PupilShell extends ConsumerStatefulWidget {
  const PupilShell({super.key});

  @override
  ConsumerState<PupilShell> createState() => _PupilShellState();
}

class _PupilShellState extends ConsumerState<PupilShell> with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  int _currentIndex = 0;

  final _tabs = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.trending_up_rounded, Icons.trending_up_outlined, 'Progress'),
    _NavItem(Icons.assignment_rounded, Icons.assignment_outlined, 'Tests'),
    _NavItem(Icons.chat_rounded, Icons.chat_outlined, 'Chat'),
    _NavItem(Icons.menu_rounded, Icons.menu_outlined, 'Menu'),
  ];

  final _pages = const [
    PupilHomeScreenV2(),
    PupilProgressScreen(),
    PupilTestReportsScreen(),
    PupilMessagingScreen(),
    PupilMenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (i == _currentIndex) return;
    HapticFeedback.lightImpact();
    _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF5F3F0),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 78,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.97) : Colors.white.withValues(alpha: 0.97),
          border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06), width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final item = _tabs[i];
                final sel = i == _currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _goTo(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.sunsetBright.withValues(alpha: isDark ? 0.15 : 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                            child: Icon(
                              sel ? item.active : item.icon,
                              key: ValueKey('$i${sel ? '_a' : '_i'}'),
                              size: sel ? 24 : 22,
                              color: sel ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
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
    );
  }
}

class _NavItem {
  final IconData active;
  final IconData icon;
  final String label;
  const _NavItem(this.active, this.icon, this.label);
}
