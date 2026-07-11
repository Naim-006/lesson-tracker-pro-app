import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/supabase_pupil_provider.dart';
import '../../core/theme/app_colors.dart';
import 'slot_request_screen.dart';
import 'pupil_progress_screen.dart';
import 'pupil_test_reports_screen.dart';
import 'pupil_messaging_screen.dart';

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

  String _firstName(Map<String, dynamic>? profile) {
    return (profile?['first_name'] as String?) ?? (profile?['full_name'] as String?)?.split(' ').first ?? 'there';
  }

  double _overallProgress(List<Map<String, dynamic>> skills) {
    if (skills.isEmpty) return 0.0;
    final total = skills.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0));
    return total / (skills.length * 5);
  }

  Future<void> _launchUrl(String url) async {
    final u = Uri.parse(url);
    if (await canLaunchUrl(u)) await launchUrl(u);
  }

  void _refresh() {
    ref.invalidate(pupilProfileProvider);
    ref.invalidate(pupilInstructorLinkProvider);
    ref.invalidate(pupilUpcomingLessonsProvider);
    ref.invalidate(pupilProgressSkillsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profileAsync = ref.watch(pupilProfileProvider);
    final linkAsync = ref.watch(pupilInstructorLinkProvider);
    final upcomingLessonsAsync = ref.watch(pupilUpcomingLessonsProvider);
    final progressSkillsAsync = ref.watch(pupilProgressSkillsProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)),
      error: (_, __) => const Center(child: Text('Error loading profile')),
      data: (profile) {
        return linkAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)),
          error: (_, __) => const Center(child: Text('Error loading instructor')),
          data: (link) {
            return upcomingLessonsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)),
              error: (_, __) => const Center(child: Text('Error loading lessons')),
              data: (upcomingLessons) {
                return progressSkillsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)),
                  error: (_, __) => const Center(child: Text('Error loading progress')),
                  data: (progressSkills) {
                    final instructor = link?['instructors'] as Map<String, dynamic>?;
                    final progress = _overallProgress(progressSkills);
                    final totalHours = progressSkills.length * 0.5;

                    return RefreshIndicator(
                      onRefresh: () async => _refresh(),
                      color: AppColors.sunsetBright,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: _buildHero(isDark, profile, instructor)),
                          SliverToBoxAdapter(child: _buildStatRow(isDark, upcomingLessons, progress, totalHours)),
                          SliverToBoxAdapter(child: _buildUpcomingLesson(isDark, upcomingLessons)),
                          SliverToBoxAdapter(child: _buildQuickActions(isDark)),
                          SliverToBoxAdapter(child: _buildProgressSnapshot(isDark, progressSkills, progress)),
                          if (instructor != null)
                            SliverToBoxAdapter(child: _buildInstructorCard(isDark, instructor)),
                          const SliverToBoxAdapter(child: SizedBox(height: 100)),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHero(bool isDark, Map<String, dynamic>? profile, Map<String, dynamic>? instructor) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);
    final firstName = _firstName(profile);
    final instructorName = instructor?['full_name'] as String? ?? instructor?['business_name'] as String? ?? 'Your Instructor';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sunsetBright, const Color(0xFFE85D3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.sunsetBright.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
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
                      Text(dateStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text('$_greeting(), $firstName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                    ],
                  ),
                ),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                  child: Center(child: Text(firstName.isNotEmpty ? firstName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, color: Colors.white.withValues(alpha: 0.9), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(instructorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('Your Driving Instructor', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  )),
                  if (instructor?['phone'] != null)
                    GestureDetector(
                      onTap: () => _launchUrl('tel:${instructor!['phone']}'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(bool isDark, List<Map<String, dynamic>> upcomingLessons, double progress, double totalHours) {
    final nextLesson = upcomingLessons.isNotEmpty ? upcomingLessons.first : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatCard(value: nextLesson != null ? _lessonDate(nextLesson) : 'None', label: 'Next Lesson', icon: Icons.access_time_rounded, color: AppColors.sunsetBright, isDark: isDark),
          const SizedBox(width: 8),
          _StatCard(value: '${totalHours.toStringAsFixed(0)}h', label: 'Hours', icon: Icons.timer_rounded, color: const Color(0xFF10B981), isDark: isDark),
          const SizedBox(width: 8),
          _StatCard(value: '${(progress * 100).toInt()}%', label: 'Progress', icon: Icons.trending_up_rounded, color: const Color(0xFF3B82F6), isDark: isDark),
        ],
      ),
    );
  }

  String _lessonDate(Map<String, dynamic> lesson) {
    try {
      final date = DateTime.parse(lesson['date']);
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) return lesson['time'] ?? 'Today';
      if (date.difference(now).inDays == 1) return 'Tomorrow';
      return DateFormat('EEE').format(date);
    } catch (_) {
      return '--';
    }
  }

  Widget _buildUpcomingLesson(bool isDark, List<Map<String, dynamic>> upcomingLessons) {
    if (upcomingLessons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotRequestScreen())),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.event_available_rounded, color: AppColors.sunsetBright, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No upcoming lessons', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 2),
                      Text('Tap to book your next slot', style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500)),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_rounded, color: AppColors.sunsetBright, size: 28),
              ],
            ),
          ),
        ),
      );
    }

    final lesson = upcomingLessons.first;
    final date = DateTime.parse(lesson['date']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('UPCOMING', style: TextStyle(color: AppColors.sunsetBright, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                ),
                const Spacer(),
                Text('\u00a3${lesson['rate'] ?? 0}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
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
                      Text(DateFormat('EEEE, MMM d').format(date), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 2),
                      Text('${lesson['time'] ?? ''} · ${lesson['duration'] ?? 60} min', style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            if (lesson['pickup_location'] != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(lesson['pickup_location'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 14),
          Row(
            children: [
              _QuickAction(icon: Icons.calendar_month_rounded, label: 'Book Slot', color: AppColors.sunsetBright, isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotRequestScreen()))),
              const SizedBox(width: 10),
              _QuickAction(icon: Icons.trending_up_rounded, label: 'Progress', color: const Color(0xFF10B981), isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilProgressScreen()))),
              const SizedBox(width: 10),
              _QuickAction(icon: Icons.assignment_rounded, label: 'Tests', color: const Color(0xFF3B82F6), isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilTestReportsScreen()))),
              const SizedBox(width: 10),
              _QuickAction(icon: Icons.chat_rounded, label: 'Message', color: const Color(0xFF8B5CF6), isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilMessagingScreen()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSnapshot(bool isDark, List<Map<String, dynamic>> progressSkills, double overall) {
    if (progressSkills.isEmpty) return const SizedBox.shrink();

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in progressSkills) {
      final cat = s['progress_categories']?['title'] ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Progress', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
              Text('${(overall * 100).toInt()}% overall', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sunsetBright)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overall,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(AppColors.sunsetBright),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 16),
                ...grouped.entries.take(4).map((e) {
                  final catSkills = e.value;
                  final catProgress = catSkills.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0)) / (catSkills.length * 5);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(e.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: catProgress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(catProgress > 0.7 ? const Color(0xFF10B981) : AppColors.sunsetBright),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 36,
                          child: Text('${(catProgress * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sunsetBright), textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorCard(bool isDark, Map<String, dynamic> instructor) {
    final name = instructor['full_name'] as String? ?? 'Your Instructor';
    final businessName = instructor['business_name'] as String?;
    final phone = instructor['phone'] as String?;
    final email = instructor['email'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                      if (businessName != null) Text(businessName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (phone != null) ...[
              InkWell(
                onTap: () => _launchUrl('tel:$phone'),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 16, color: AppColors.sunsetBright),
                      const SizedBox(width: 8),
                      Text(phone, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87)),
                    ],
                  ),
                ),
              ),
            ],
            if (email != null) ...[
              InkWell(
                onTap: () => _launchUrl('mailto:$email'),
                child: Row(
                  children: [
                    Icon(Icons.email_rounded, size: 16, color: AppColors.sunsetBright),
                    const SizedBox(width: 8),
                    Text(email, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.icon, required this.color, required this.isDark});
  final String value; final String label; final IconData icon; final Color color; final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.isDark, required this.onTap});
  final IconData icon; final String label; final Color color; final bool isDark; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
