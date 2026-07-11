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
import 'pupil_lessons_screen.dart';
import 'pupil_payment_screen.dart';
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
                          _buildHero(profile, instructor),
                          _buildStatRow(upcomingLessons, progress, totalHours),
                          if (instructor != null) _buildInstructorProfile(instructor),
                          _buildUpcomingLesson(upcomingLessons),
                          _buildSectionHeader('Quick Actions'),
                          _buildQuickActions(),
                          _buildSectionHeader('My Progress'),
                          _buildProgressSnapshot(progressSkills, progress),
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

  SliverToBoxAdapter _buildHero(Map<String, dynamic>? profile, Map<String, dynamic>? instructor) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);
    final firstName = _firstName(profile);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
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
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStatRow(List<Map<String, dynamic>> upcomingLessons, double progress, double totalHours) {
    final nextLesson = upcomingLessons.isNotEmpty ? upcomingLessons.first : null;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            _StatCard(value: nextLesson != null ? _lessonDate(nextLesson) : 'None', label: 'Next Lesson', icon: Icons.access_time_rounded, color: AppColors.sunsetBright),
            const SizedBox(width: 10),
            _StatCard(value: '${totalHours.toStringAsFixed(0)}h', label: 'Hours', icon: Icons.timer_rounded, color: const Color(0xFF10B981)),
            const SizedBox(width: 10),
            _StatCard(value: '${(progress * 100).toInt()}%', label: 'Progress', icon: Icons.trending_up_rounded, color: const Color(0xFF3B82F6)),
          ],
        ),
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

  SliverToBoxAdapter _buildInstructorProfile(Map<String, dynamic> instructor) {
    final name = instructor['full_name'] as String? ?? 'Your Instructor';
    final business = instructor['business_name'] as String?;
    final phone = instructor['phone'] as String?;
    final email = instructor['email'] as String?;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(child: Text(initial, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      if (business != null && business.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(business, style: TextStyle(fontSize: 13, color: AppColors.sunsetBright, fontWeight: FontWeight.w600)),
                        ),
                      Text('Your Driving Instructor', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                if (phone != null && phone.isNotEmpty)
                  Expanded(
                    child: _ContactBtn(icon: Icons.phone_rounded, label: 'Call', onTap: () => _launchUrl('tel:$phone')),
                  ),
                if (phone != null && phone.isNotEmpty) const SizedBox(width: 10),
                if (email != null && email.isNotEmpty)
                  Expanded(
                    child: _ContactBtn(icon: Icons.email_rounded, label: 'Email', onTap: () => _launchUrl('mailto:$email')),
                  ),
                if (email != null && email.isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  child: _ContactBtn(icon: Icons.chat_rounded, label: 'Message', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilMessagingScreen()))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildUpcomingLesson(List<Map<String, dynamic>> upcomingLessons) {
    if (upcomingLessons.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotRequestScreen())),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
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
                        Text('No upcoming lessons', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Tap to book your next slot', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Icon(Icons.add_circle_rounded, color: AppColors.sunsetBright, size: 28),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final lesson = upcomingLessons.first;
    final date = DateTime.parse(lesson['date']);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('NEXT LESSON', style: TextStyle(color: AppColors.sunsetBright, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
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
                        Text(DateFormat('EEEE, MMM d').format(date), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                    Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(lesson['pickup_location'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilLessonsScreen())),
                    icon: const Icon(Icons.calendar_month_outlined, size: 16),
                    label: const Text('All lessons', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.sunsetBright),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
      ),
    );
  }

  SliverToBoxAdapter _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(
          children: [
            _QuickActionBtn(icon: Icons.calendar_month_rounded, label: 'Book Slot', color: AppColors.sunsetBright,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotRequestScreen()))),
            const SizedBox(width: 10),
            _QuickActionBtn(icon: Icons.trending_up_rounded, label: 'Progress', color: const Color(0xFF10B981),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilProgressScreen()))),
            const SizedBox(width: 10),
            _QuickActionBtn(icon: Icons.assignment_rounded, label: 'Tests', color: const Color(0xFF3B82F6),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilTestReportsScreen()))),
            const SizedBox(width: 10),
            _QuickActionBtn(icon: Icons.payment_rounded, label: 'Payments', color: const Color(0xFF8B5CF6),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilPaymentScreen()))),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildProgressSnapshot(List<Map<String, dynamic>> progressSkills, double overall) {
    if (progressSkills.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in progressSkills) {
      final cat = s['progress_categories']?['title'] ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: overall,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(AppColors.sunsetBright),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Overall Progress', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  Text('${(overall * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sunsetBright)),
                ],
              ),
              const SizedBox(height: 16),
              ...grouped.entries.take(4).map((e) {
                final catProgress = e.value.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0)) / (e.value.length * 5);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(e.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                      SizedBox(width: 36, child: Text('${(catProgress * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sunsetBright), textAlign: TextAlign.right)),
                    ],
                  ),
                );
              }),
              if (grouped.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilProgressScreen())),
                        child: const Text('View full progress', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});
  final String value; final String label; final IconData icon; final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.12), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon; final String label; final Color color; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
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

class _ContactBtn extends StatelessWidget {
  const _ContactBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.sunsetBright.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.sunsetBright),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sunsetBright)),
          ],
        ),
      ),
    );
  }
}
