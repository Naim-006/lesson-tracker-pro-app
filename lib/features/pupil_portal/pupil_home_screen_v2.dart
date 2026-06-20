import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/supabase_pupil_provider.dart';
import '../../core/theme/app_colors.dart';
import 'slot_request_screen.dart';
import 'pupil_progress_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final profileAsync = ref.watch(pupilProfileProvider);
    final upcomingLessonsAsync = ref.watch(pupilUpcomingLessonsProvider);
    final progressSkillsAsync = ref.watch(pupilProgressSkillsProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)),
      error: (_, __) => const Center(child: Text('Error loading profile')),
      data: (profile) {
        return upcomingLessonsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)),
          error: (_, __) => const Center(child: Text('Error loading lessons')),
          data: (upcomingLessons) {
            return progressSkillsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)),
              error: (_, __) => const Center(child: Text('Error loading progress')),
              data: (progressSkills) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(pupilProfileProvider);
                    ref.invalidate(pupilUpcomingLessonsProvider);
                    ref.invalidate(pupilProgressSkillsProvider);
                  },
                  color: AppColors.sunsetBright,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHero(isDark, profile)),
                      SliverToBoxAdapter(child: _buildStatChips(isDark, upcomingLessons, progressSkills)),
                      SliverToBoxAdapter(child: _buildUpNext(isDark, upcomingLessons)),
                      SliverToBoxAdapter(child: _buildQuickActions(isDark)),
                      SliverToBoxAdapter(child: _buildProgressSnapshot(isDark, progressSkills)),
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
  }

  // ─── Hero Section ─────────────────────────────────────────
  Widget _buildHero(bool isDark, Map<String, dynamic>? profile) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);
    final firstName = _firstName(profile);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [AppColors.sunsetBright, const Color(0xFFE85D3A)],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_greeting()}, $firstName',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Center(
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, color: Colors.white.withValues(alpha: 0.9), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your driving journey continues',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stat Chips ───────────────────────────────────────────
  Widget _buildStatChips(bool isDark, List<Map<String, dynamic>> upcomingLessons, List<Map<String, dynamic>> progressSkills) {
    final nextLesson = upcomingLessons.isNotEmpty ? upcomingLessons.first : null;
    final progress = _overallProgress(progressSkills);
    final totalHours = progressSkills.length * 0.5; // rough estimate

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatChip(
            value: nextLesson != null ? _formatLessonTime(nextLesson) : 'None',
            label: 'Next Lesson',
            icon: Icons.access_time_rounded,
            color: AppColors.sunsetBright,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatChip(
            value: '${totalHours.toStringAsFixed(0)}h',
            label: 'Hours Learned',
            icon: Icons.timer_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatChip(
            value: '${(progress * 100).toInt()}%',
            label: 'Progress',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  String _formatLessonTime(Map<String, dynamic> lesson) {
    try {
      final date = DateTime.parse(lesson['date']);
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return lesson['time'] ?? 'Today';
      }
      if (date.difference(now).inDays == 1) return 'Tomorrow';
      return DateFormat('EEE').format(date);
    } catch (_) {
      return '--';
    }
  }

  // ─── Up Next Card ─────────────────────────────────────────
  Widget _buildUpNext(bool isDark, List<Map<String, dynamic>> upcomingLessons) {
    if (upcomingLessons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotRequestScreen())),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.sunsetBright.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.event_available_rounded, color: AppColors.sunsetBright, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No upcoming lessons',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to book your next slot',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                        ),
                      ),
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
    final instructor = lesson['instructors'];
    final date = DateTime.parse(lesson['date']);
    final name = instructor?['full_name'] ?? instructor?['business_name'] ?? 'Instructor';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [AppColors.sunsetBright, const Color(0xFFE85D3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.sunsetBright.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'UP NEXT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\u00a3${lesson['rate'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lesson['time'] ?? ''} · ${lesson['duration'] ?? 60} min',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    DateFormat('EEEE, MMM d · h:mm a').format(date),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (lesson['pickup_location'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.trip_origin_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lesson['pickup_location'],
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Quick Actions ────────────────────────────────────────
  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionChip(
                icon: Icons.calendar_month_rounded,
                label: 'Book',
                color: AppColors.sunsetBright,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotRequestScreen())),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.trending_up_rounded,
                label: 'Progress',
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilProgressScreen())),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.chat_rounded,
                label: 'Chat',
                color: const Color(0xFF3B82F6),
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilMessagingScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Progress Snapshot ────────────────────────────────────
  Widget _buildProgressSnapshot(bool isDark, List<Map<String, dynamic>> progressSkills) {
    if (progressSkills.isEmpty) return const SizedBox.shrink();

    final progress = _overallProgress(progressSkills);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in progressSkills) {
      final cat = s['progress_categories']?['name'] ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                ),
              ),
              Flexible(
                child: Text(
                  '${(progress * 100).toInt()}% overall',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sunsetBright,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...grouped.entries.take(3).map((e) {
            final catSkills = e.value;
            final catProgress = catSkills.fold<double>(0, (s, sk) => s + ((sk['skill_level'] as int?) ?? 0)) /
                (catSkills.length * 5);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: catProgress,
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(AppColors.sunsetBright),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${(catProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.sunsetBright,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Stat Chip ──────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

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
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Chip ────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
