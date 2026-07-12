import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../auth/onboarding_screen.dart';
import 'pupil_settings_screen.dart';
import 'pupil_payment_screen.dart';
import 'pupil_resources_screen.dart';
import 'pupil_test_reports_screen.dart';
import 'pupil_lessons_screen.dart';
import 'pupil_instructor_screen.dart';
import 'pupil_messaging_screen.dart';

class PupilMenuScreen extends StatefulWidget {
  const PupilMenuScreen({super.key});

  @override
  State<PupilMenuScreen> createState() => _PupilMenuScreenState();
}

class _PupilMenuScreenState extends State<PupilMenuScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _instructor;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_user == null) return;
    try {
      _profile = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', _user!.id)
          .maybeSingle();
    } catch (_) { _profile = null; }

    try {
      final link = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', _user!.id)
          .eq('status', 'active')
          .maybeSingle();
      if (link?['instructor_id'] != null) {
        _instructor = await Supabase.instance.client
            .from('profiles')
            .select('full_name, business_name')
            .eq('id', link!['instructor_id'])
            .maybeSingle();
      }
    } catch (_) { _instructor = null; }

    if (mounted) setState(() {});
  }

  String _displayName() => (_profile?['first_name'] as String?) ??
      (_profile?['full_name'] as String?)?.split(' ').first ?? 'Pupil';

  String _initial() => _displayName().isNotEmpty ? _displayName()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF7F5F2),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sunsetBright, const Color(0xFFE85D3A), const Color(0xFFD9480F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5)),
                              child: Center(child: Text(_initial(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_displayName(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(_user?.email ?? '', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          if (_instructor != null)
            SliverToBoxAdapter(child: _instructorBanner(isDark)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _section('Account', [
                _Item(Icons.person_rounded, 'My Instructor', AppColors.sunsetBright, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilInstructorScreen()))),
                _Item(Icons.calendar_month_rounded, 'My Lessons', const Color(0xFF3B82F6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilLessonsScreen()))),
                _Item(Icons.payment_rounded, 'Payments', const Color(0xFF8B5CF6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilPaymentScreen()))),
                _Item(Icons.receipt_long_rounded, 'Resources', const Color(0xFF10B981), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilResourcesScreen()))),
                _Item(Icons.assignment_turned_in_rounded, 'Test Reports', const Color(0xFFFBBF24), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilTestReportsScreen()))),
                _Item(Icons.chat_rounded, 'Messages', const Color(0xFF8B5CF6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilMessagingScreen()))),
              ], isDark),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _section('Settings', [
                _Item(Icons.settings_rounded, 'Preferences', Colors.grey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilSettingsScreen()))),
                _Item(Icons.help_outline_rounded, 'Help & Support', Colors.grey, () {}),
                _Item(Icons.info_outline_rounded, 'About', Colors.grey, () => _showAbout()),
              ], isDark),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _signOut(isDark)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _instructorBanner(bool isDark) {
    final name = _instructor!['full_name'] as String? ?? 'Instructor';
    final business = _instructor!['business_name'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilInstructorScreen())),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.sunsetBright, AppColors.sunset]), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), if (business != null) Text(business, style: TextStyle(fontSize: 13, color: Colors.grey.shade500))],)),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<_Item> items, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade400)),
          ),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            return _tile(item, isDark, !isLast);
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _tile(_Item item, bool isDark, bool showDivider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)), child: Icon(item.icon, size: 20, color: item.color)),
                  const SizedBox(width: 14),
                  Expanded(child: Text(item.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87))),
                  Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300),
                ],
              ),
            ),
            if (showDivider) Padding(padding: const EdgeInsets.only(left: 72), child: Divider(height: 0.5, color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.lightBorder.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _signOut(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () async {
          final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Sign Out')),
            ],
          ));
          if (ok == true) {
            await Supabase.instance.client.auth.signOut();
            if (!mounted) return;
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.error.withValues(alpha: 0.12))),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(Icons.logout_rounded, color: AppColors.error, size: 20), SizedBox(width: 8), Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.error))],
          ),
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]), borderRadius: BorderRadius.all(Radius.circular(20))),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Lesson Tracker Pro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 8),
            Text('Professional driving instructor platform.\nManage lessons, track progress, and more.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        actions: [Center(child: FilledButton(onPressed: () => Navigator.pop(ctx), style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright), child: const Text('Close')))],
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _Item(this.icon, this.label, this.color, this.onTap);
}