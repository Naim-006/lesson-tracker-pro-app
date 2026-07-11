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

  String _firstName(Map<String, dynamic>? profile) {
    return (profile?['first_name'] as String?) ?? (profile?['full_name'] as String?)?.split(' ').first ?? 'there';
  }

  double _overallProgress(List<Map<String, dynamic>> skills) {
    if (skills.isEmpty) return 0.0;
    final total = skills.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0));
    return total / (skills.length * 5);
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
    final profileAsync = ref.watch(pupilProfileProvider);
    final linkAsync = ref.watch(pupilInstructorLinkProvider);
    final upcomingLessonsAsync = ref.watch(pupilUpcomingLessonsProvider);
    final progressSkillsAsync = ref.watch(pupilProgressSkillsProvider);
    final statsAsync = ref.watch(pupilLessonStatsProvider);

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
                    return statsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)),
                      error: (_, __) => const Center(child: Text('Error loading stats')),
                      data: (stats) {
                        final instructor = link?['instructors'] as Map<String, dynamic>?;
                        final progress = _overallProgress(progressSkills);
                        final firstName = _firstName(profile);

                        return RefreshIndicator(
                          onRefresh: () async => _refresh(),
                          color: AppColors.sunsetBright,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              _buildHeader(profile, instructor, firstName, stats, progress),
                              _buildInstructorCard(instructor),
                              _buildUpcomingSection(upcomingLessons),
                              _buildQuickActions(),
                              _buildProgressSection(progressSkills, progress),
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
      },
    );
  }

  // ─── PREMIUM HEADER ──────────────────────────────────────────
  Widget _buildHeader(Map<String, dynamic>? profile, Map<String, dynamic>? instructor, String firstName, Map<String, dynamic> stats, double progress) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM').format(now);
    final totalLessons = stats['total'] as int? ?? 0;
    final totalHours = (stats['hours'] as double? ?? 0.0);
    final totalSpent = (stats['spent'] as double? ?? 0.0);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.sunsetBright, Color(0xFFE85D3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12)),
          ],
        ),
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
                      Text(dateStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7))),
                      const SizedBox(height: 6),
                      Text('$_greeting(), $firstName', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                    ],
                  ),
                ),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                  child: Center(child: Text(firstName.isNotEmpty ? firstName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _HeaderStat(label: 'Lessons', value: '$totalLessons'),
                _HeaderStat(label: 'Hours', value: '${totalHours.toStringAsFixed(0)}h'),
                _HeaderStat(label: 'Progress', value: '${(progress * 100).toInt()}%'),
                _HeaderStat(label: 'Spent', value: '\u00a3${totalSpent.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── INSTRUCTOR CARD ─────────────────────────────────────────
  Widget _buildInstructorCard(Map<String, dynamic>? instructor) {
    if (instructor == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final name = instructor['full_name'] as String? ?? 'Your Instructor';
    final business = instructor['business_name'] as String?;
    final phone = instructor['phone'] as String?;
    final email = instructor['email'] as String?;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilInstructorScreen())),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    if (business != null && business.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(business, style: TextStyle(fontSize: 13, color: AppColors.sunsetBright, fontWeight: FontWeight.w600)),
                      ),
                    Text('Your Driving Instructor', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Column(
                children: [
                  if (phone != null)
                    _IconBtn(Icons.phone_rounded, AppColors.success, () async { final u = Uri.parse('tel:$phone'); if (await canLaunchUrl(u)) await launchUrl(u); }),
                  if (email != null) ...[
                    const SizedBox(height: 6),
                    _IconBtn(Icons.email_rounded, AppColors.info, () async { final u = Uri.parse('mailto:$email'); if (await canLaunchUrl(u)) await launchUrl(u); }),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UPCOMING SECTION ────────────────────────────────────────
  Widget _buildUpcomingSection(List<Map<String, dynamic>> upcomingLessons) {
    if (upcomingLessons.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotRequestScreen())),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.3), width: 1.5),
                borderRadius: BorderRadius.circular(22),
                color: AppColors.sunsetBright.withValues(alpha: 0.04),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.event_available_rounded, color: AppColors.sunsetBright, size: 28),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Book Your Next Lesson', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text('No upcoming lessons scheduled', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.sunsetBright, size: 16),
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
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('NEXT LESSON', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
                const Spacer(),
                Text('\u00a3${lesson['rate'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.sunsetBright)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(DateFormat('MMM').format(date).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('${date.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('EEEE').format(date), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text('${lesson['time'] ?? ''} \u00b7 ${lesson['duration'] ?? 60} min', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      if (lesson['pickup_location'] != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(child: Text(lesson['pickup_location'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilLessonsScreen())),
                child: const Text('All Lessons', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── QUICK ACTIONS ───────────────────────────────────────────
  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, letterSpacing: -0.3)),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickCard(icon: Icons.calendar_month_rounded, label: 'Book', color: AppColors.sunsetBright,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotRequestScreen()))),
                const SizedBox(width: 12),
                _QuickCard(icon: Icons.payments_rounded, label: 'Pay', color: const Color(0xFF10B981),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilPaymentScreen()))),
                const SizedBox(width: 12),
                _QuickCard(icon: Icons.assignment_rounded, label: 'Tests', color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilTestReportsScreen()))),
                const SizedBox(width: 12),
                _QuickCard(icon: Icons.trending_up_rounded, label: 'Progress', color: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilProgressScreen()))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── PROGRESS SECTION ────────────────────────────────────────
  Widget _buildProgressSection(List<Map<String, dynamic>> progressSkills, double overall) {
    if (progressSkills.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in progressSkills) {
      final cat = s['progress_categories']?['title'] ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                Text('${(overall * 100).toInt()}% Complete', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sunsetBright)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: overall,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(AppColors.sunsetBright),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 20),
            ...grouped.entries.take(4).map((e) {
              final catProgress = e.value.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0)) / (e.value.length * 5);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(e.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: catProgress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(catProgress > 0.7 ? const Color(0xFF10B981) : AppColors.sunsetBright),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(width: 36, child: Text('${(catProgress * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sunsetBright), textAlign: TextAlign.right)),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilProgressScreen())),
                child: const Text('Full Progress', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COMPONENTS ──────────────────────────────────────────────
class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});
  final String label; final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _IconBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
