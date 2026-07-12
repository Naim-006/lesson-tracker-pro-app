import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/supabase_pupil_provider.dart';
import '../../core/theme/app_colors.dart';
import 'slot_request_screen.dart';
import 'pupil_progress_screen.dart';
import 'pupil_test_reports_screen.dart';
import 'pupil_lessons_screen.dart';
import 'pupil_payment_screen.dart';
import 'pupil_instructor_screen.dart';

class PupilHomeScreenV2 extends ConsumerStatefulWidget {
  const PupilHomeScreenV2({super.key});

  @override
  ConsumerState<PupilHomeScreenV2> createState() => _PupilHomeScreenV2State();
}

class _PupilHomeScreenV2State extends ConsumerState<PupilHomeScreenV2> {
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName(Map<String, dynamic>? p) =>
      (p?['first_name'] as String?) ?? (p?['full_name'] as String?)?.split(' ').first ?? 'there';

  double _progress(List<Map<String, dynamic>> skills) {
    if (skills.isEmpty) return 0;
    final t = skills.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0));
    return t / (skills.length * 5);
  }

  void _refresh() {
    ref.invalidate(pupilProfileProvider);
    ref.invalidate(pupilInstructorLinkProvider);
    ref.invalidate(pupilUpcomingLessonsProvider);
    ref.invalidate(pupilProgressSkillsProvider);
    ref.invalidate(pupilLessonStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF7F5F2),
      body: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!,
        child: _buildContent(isDark),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final profileAsync = ref.watch(pupilProfileProvider);
    final linkAsync = ref.watch(pupilInstructorLinkProvider);
    final upcomingAsync = ref.watch(pupilUpcomingLessonsProvider);
    final skillsAsync = ref.watch(pupilProgressSkillsProvider);
    final statsAsync = ref.watch(pupilLessonStatsProvider);

    return profileAsync.when(
      loading: () => _loading(isDark),
      error: (_, __) => _errorState('Profile', isDark),
      data: (profile) => linkAsync.when(
        loading: () => _loading(isDark),
        error: (_, __) => _errorState('Instructor', isDark),
        data: (link) => upcomingAsync.when(
          loading: () => _loading(isDark),
          error: (_, __) => _errorState('Lessons', isDark),
          data: (upcoming) => skillsAsync.when(
            loading: () => _loading(isDark),
            error: (_, __) => _errorState('Progress', isDark),
            data: (skills) => statsAsync.when(
              loading: () => _loading(isDark),
              error: (_, __) => _errorState('Stats', isDark),
              data: (stats) => _dashboard(profile, link, upcoming, skills, stats, isDark),
            ),
          ),
        ),
      ),
    );
  }

  // ─── LOADING / ERROR ────────────────────────────────────────
  Widget _loading(bool isDark) {
    return Center(child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.sunsetBright.withValues(alpha: 0.8), backgroundColor: AppColors.sunsetBright.withValues(alpha: 0.1)));
  }

  Widget _errorState(String what, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Could not load', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ─── MAIN DASHBOARD ────────────────────────────────────────
  Widget _dashboard(Map<String, dynamic>? profile, Map<String, dynamic>? link, List<Map<String, dynamic>> upcoming, List<Map<String, dynamic>> skills, Map<String, dynamic> stats, bool isDark) {
    final instructor = link?['instructor'] as Map<String, dynamic>?;
    final progress = _progress(skills);
    final firstName = _firstName(profile);
    final totalLessons = stats['total'] as int? ?? 0;
    final totalHours = (stats['hours'] as double? ?? 0.0);
    final totalSpent = (stats['spent'] as double? ?? 0.0);

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: AppColors.sunsetBright,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // HERO
          SliverToBoxAdapter(child: _hero(isDark, profile, instructor, firstName)),
          // STATS
          SliverToBoxAdapter(child: _statsRow(isDark, totalLessons, totalHours, progress, totalSpent)),
          // INSTRUCTOR CARD
          if (instructor != null)
            SliverToBoxAdapter(child: _instructorCard(isDark, instructor)),
          // NEXT LESSON
          SliverToBoxAdapter(child: _nextLesson(isDark, upcoming)),
          // QUICK ACTIONS
          SliverToBoxAdapter(child: _quickActions(isDark)),
          // PROGRESS SNAPSHOT
          if (skills.isNotEmpty)
            SliverToBoxAdapter(child: _progressCard(isDark, skills, progress)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ─── HERO ──────────────────────────────────────────────────
  Widget _hero(bool isDark, Map<String, dynamic>? profile, Map<String, dynamic>? instructor, String firstName) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sunsetBright, const Color(0xFFE85D3A), const Color(0xFFD9480F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 10)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM').format(DateTime.now()),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.75), letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_greeting()},',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      Text(
                        firstName,
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5)),
                  child: Center(child: Text(firstName.isNotEmpty ? firstName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ],
            ),
            if (instructor != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${instructor['full_name'] ?? 'Your Instructor'}${instructor['business_name'] != null ? ' · ${instructor['business_name']}' : ''}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── STATS ROW ─────────────────────────────────────────────
  Widget _statsRow(bool isDark, int lessons, double hours, double progress, double spent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            _stat(lessons.toString(), 'Lessons', Icons.school_rounded, AppColors.sunsetBright),
            _divider(),
            _stat('${hours.toStringAsFixed(0)}h', 'Hours', Icons.timer_rounded, const Color(0xFF10B981)),
            _divider(),
            _stat('${(progress * 100).toInt()}%', 'Progress', Icons.trending_up_rounded, const Color(0xFF3B82F6)),
            _divider(),
            _stat('\u00a3${spent.toStringAsFixed(0)}', 'Spent', Icons.payments_rounded, const Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 44, color: Colors.grey.shade200);
  }

  // ─── INSTRUCTOR CARD ────────────────────────────────────────
  Widget _instructorCard(bool isDark, Map<String, dynamic> instructor) {
    final name = instructor['full_name'] as String? ?? 'Your Instructor';
    final business = instructor['business_name'] as String?;
    final phone = instructor['phone'] as String?;
    final email = instructor['email'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilInstructorScreen())),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.sunsetBright.withValues(alpha: 0.8), AppColors.sunset]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (business != null && business.isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 1), child: Text(business, style: TextStyle(fontSize: 13, color: AppColors.sunsetBright, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('Your Instructor', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              if (phone != null && phone.isNotEmpty)
                IconButton(
                  onPressed: () async { final u = Uri.parse('tel:$phone'); if (await canLaunchUrl(u)) await launchUrl(u); },
                  icon: const Icon(Icons.phone_rounded, color: AppColors.success, size: 20),
                  style: IconButton.styleFrom(backgroundColor: AppColors.success.withValues(alpha: 0.1)),
                ),
              if (email != null && email.isNotEmpty)
                IconButton(
                  onPressed: () async { final u = Uri.parse('mailto:$email'); if (await canLaunchUrl(u)) await launchUrl(u); },
                  icon: const Icon(Icons.email_rounded, color: AppColors.info, size: 20),
                  style: IconButton.styleFrom(backgroundColor: AppColors.info.withValues(alpha: 0.1)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── NEXT LESSON ───────────────────────────────────────────
  Widget _nextLesson(bool isDark, List<Map<String, dynamic>> upcoming) {
    if (upcoming.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotRequestScreen())),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add_rounded, color: AppColors.sunsetBright, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Book your next lesson', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('No upcoming lessons scheduled', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ])),
                Icon(Icons.chevron_right_rounded, color: AppColors.sunsetBright.withValues(alpha: 0.5), size: 24),
              ],
            ),
          ),
        ),
      );
    }

    final lesson = upcoming.first;
    final date = DateTime.parse(lesson['date']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]), borderRadius: BorderRadius.circular(8)),
                  child: const Text('NEXT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
                const Spacer(),
                Text('\u00a3${lesson['rate'] ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sunsetBright)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.calendar_today_rounded, color: AppColors.sunsetBright, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('EEEE, d MMM').format(date), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('${lesson['time'] ?? ''} · ${lesson['duration'] ?? 60} min', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            if (lesson['pickup_location'] != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(child: Text(lesson['pickup_location'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilLessonsScreen())),
                icon: const Icon(Icons.list_rounded, size: 16),
                label: const Text('All lessons', style: TextStyle(fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: AppColors.sunsetBright),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── QUICK ACTIONS ────────────────────────────────────────
  Widget _quickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(
            children: [
              _action('Book Slot', Icons.add_circle_rounded, AppColors.sunsetBright, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotRequestScreen()))),
              const SizedBox(width: 12),
              _action('Progress', Icons.trending_up_rounded, const Color(0xFF10B981), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilProgressScreen()))),
              const SizedBox(width: 12),
              _action('Tests', Icons.assignment_rounded, const Color(0xFF3B82F6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilTestReportsScreen()))),
              const SizedBox(width: 12),
              _action('Pay', Icons.payment_rounded, const Color(0xFF8B5CF6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilPaymentScreen()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PROGRESS SNAPSHOT ────────────────────────────────────
  Widget _progressCard(bool isDark, List<Map<String, dynamic>> skills, double overall) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in skills) {
      final cat = s['progress_categories']?['title'] ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progress Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('${(overall * 100).toInt()}%', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.sunsetBright)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: overall, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation(AppColors.sunsetBright), minHeight: 12),
            ),
            const SizedBox(height: 16),
            ...grouped.entries.take(4).map((e) {
              final cp = e.value.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0)) / (e.value.length * 5);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 10),
                    Expanded(flex: 3, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: cp, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(cp > 0.7 ? const Color(0xFF10B981) : AppColors.sunsetBright), minHeight: 6))),
                    const SizedBox(width: 10),
                    SizedBox(width: 32, child: Text('${(cp * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sunsetBright), textAlign: TextAlign.right)),
                  ],
                ),
              );
            }),
            if (grouped.length > 4)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilProgressScreen())), child: const Text('View detailed progress', style: TextStyle(fontWeight: FontWeight.w600))),
              ),
          ],
        ),
      ),
    );
  }
}