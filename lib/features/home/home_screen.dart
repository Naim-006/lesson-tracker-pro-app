import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/utils/route_transitions.dart';
import '../settings/settings_screen.dart';
import '../settings/teaching_resources_screen.dart';
import '../test_reports/test_reports_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _today = true;

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return DateFormat('h:mm a').format(DateTime(2020, 1, 1, h, m));
    } catch (_) {
      return timeStr;
    }
  }

  String _formatDuration(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _calculateEndTime(String startTime, int durationMins) {
    try {
      final parts = startTime.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(2020, 1, 1, h, m).add(Duration(minutes: durationMins));
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _getDayHeader(DateTime date, DateTime now) {
    final tomorrow = now.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    final tomorrowOnly = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final nowOnly = DateTime(now.year, now.month, now.day);

    if (dateOnly == tomorrowOnly) return 'TOMORROW';
    if (dateOnly == nowOnly) return 'TODAY';
    return DateFormat('EEEE').format(date).toUpperCase();
  }

  LessonStatus _mapLessonStatus(String? status) {
    switch (status) {
      case 'completed': return LessonStatus.completed;
      case 'cancelled': return LessonStatus.cancelled;
      case 'no_show': return LessonStatus.noShow;
      default: return LessonStatus.scheduled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(instructorLessonsProvider);
    final pupilsAsync = ref.watch(instructorPupilsProvider);
    final slotsAsync = ref.watch(instructorSlotsProvider);
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(instructorLessonsProvider);
        ref.invalidate(instructorPupilsProvider);
        ref.invalidate(instructorSlotsProvider);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(isDark)),
          SliverToBoxAdapter(child: _buildKpiRow(lessonsAsync, pupilsAsync, isDark)),
          SliverToBoxAdapter(child: _buildToggle(isDark)),
          SliverToBoxAdapter(child: _buildQuickAccess(isDark)),
          if (lessonsAsync.isLoading || pupilsAsync.isLoading || slotsAsync.isLoading)
            const SliverToBoxAdapter(child: LoadingShimmer(itemCount: 4))
          else
            _buildContent(lessonsAsync, slotsAsync, now, isDark),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(now),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Schedule',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, slideInRoute(const SettingsScreen())),
            child: AvatarCircle(
              initials: 'AD',
              size: 44,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(AsyncValue<List<Map<String, dynamic>>> lessonsAsync, AsyncValue<List<Map<String, dynamic>>> pupilsAsync, bool isDark) {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final todayLessons = lessonsAsync.valueOrNull?.where((l) => l['date'] == todayStr).toList() ?? [];
    final totalPupils = pupilsAsync.valueOrNull?.length ?? 0;
    final todayIncome = todayLessons.fold<double>(0, (sum, l) => sum + ((l['rate'] as num?)?.toDouble() ?? 0));
    final todayCount = todayLessons.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _KpiCard(icon: Icons.school, value: '$todayCount', label: "Today's\nLessons", color: AppColors.sunsetBright, isDark: isDark, flex: 1),
          const SizedBox(width: 8),
          _KpiCard(icon: Icons.currency_pound, value: '\u00a3${todayIncome.toStringAsFixed(0)}', label: 'Today\nIncome', color: AppColors.success, isDark: isDark, flex: 1),
          const SizedBox(width: 8),
          _KpiCard(icon: Icons.people, value: '$totalPupils', label: 'Active\nPupils', color: AppColors.info, isDark: isDark, flex: 1),
        ],
      ),
    );
  }

  Widget _buildToggle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: _toggleSegment('TODAY', _today, isDark)),
            Expanded(child: _toggleSegment('NEXT 7 DAYS', !_today, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _toggleSegment(String label, bool active, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _today = label == 'TODAY'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? AppColors.sunsetBright : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [
            BoxShadow(
              color: AppColors.sunsetBright.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccess(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        _QuickAccessChip(icon: Icons.menu_book, label: 'Resources', color: AppColors.info, onTap: () => Navigator.push(context, slideInRoute(const TeachingResourcesScreen()))),
        const SizedBox(width: 8),
        _QuickAccessChip(icon: Icons.assignment_turned_in, label: 'Test Reports', color: AppColors.warning, onTap: () => Navigator.push(context, slideInRoute(const TestReportsScreen()))),
        const SizedBox(width: 8),
        _QuickAccessChip(icon: Icons.settings, label: 'Settings', color: AppColors.sunsetBright, onTap: () => Navigator.push(context, slideInRoute(const SettingsScreen()))),
      ]),
    );
  }

  Widget _buildContent(AsyncValue<List<Map<String, dynamic>>> lessonsAsync, AsyncValue<List<Map<String, dynamic>>> slotsAsync, DateTime now, bool isDark) {
    final lessons = _parseLessons(lessonsAsync);
    final slots = _parseSlots(slotsAsync);

    if (_today) {
      final todayLessons = lessons.where((l) =>
        l.date.year == now.year && l.date.month == now.month && l.date.day == now.day
      ).toList()..sort((a, b) => a.time.compareTo(b.time));

      final todaySlots = slots.where((s) =>
        s.date.year == now.year && s.date.month == now.month && s.date.day == now.day
      ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

      final items = _mergeItems(todayLessons, todaySlots);

      if (items.isEmpty) {
        return SliverToBoxAdapter(child: _buildEmptyState(isDark));
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          if (item is _TimelineLesson && index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUpNextCard(item, isDark),
                if (items.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      'Later today',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            );
          }
          return item is _TimelineLesson
              ? _buildLessonCard(item, isDark)
              : _buildSlotCard(item as _TimelineSlot, isDark);
        }, childCount: items.length),
      );
    }

    final items = _buildNext7Days(now, lessons, slots);
    if (items.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(isDark));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final entry = items[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: _DayHeaderLabel(text: _getDayHeader(entry.date, now)),
            ),
            ...entry.items.map((item) {
              return item is _TimelineLesson
                  ? _buildLessonCard(item, isDark)
                  : _buildSlotCard(item as _TimelineSlot, isDark);
            }),
          ],
        );
      }, childCount: items.length),
    );
  }

  List<Lesson> _parseLessons(AsyncValue<List<Map<String, dynamic>>> asyncValue) {
    return asyncValue.valueOrNull?.map((l) {
      final pupilData = l['pupils'];
      final profile = pupilData?['profiles'];
      return Lesson(
        id: l['id'],
        pupilId: l['pupil_id'],
        pupilName: profile?['full_name'] ?? 'Unknown',
        date: DateTime.parse(l['date']),
        time: l['time'] ?? '',
        duration: l['duration'] ?? 60,
        rate: (l['rate'] as num?)?.toDouble() ?? 0,
        pickupLocation: l['pickup_location'] as String?,
        dropoffLocation: l['dropoff_location'] as String?,
        status: _mapLessonStatus(l['status']),
        paid: l['paid'] ?? false,
        notes: l['notes'] as String?,
      );
    }).toList() ?? [];
  }

  List<OpenSlot> _parseSlots(AsyncValue<List<Map<String, dynamic>>> asyncValue) {
    return asyncValue.valueOrNull?.map((s) {
      return OpenSlot(
        id: s['id'],
        date: DateTime.parse(s['date']),
        startTime: s['start_time'] ?? '',
        duration: s['duration'] ?? 60,
      );
    }).toList() ?? [];
  }

  int _compareTime(String a, String b) {
    return a.compareTo(b);
  }

  List<dynamic> _mergeItems(List<Lesson> lessons, List<OpenSlot> slots) {
    final items = <dynamic>[];
    int li = 0, si = 0;
    while (li < lessons.length || si < slots.length) {
      if (si >= slots.length || (li < lessons.length && _compareTime(lessons[li].time, slots[si].startTime) <= 0)) {
        final l = lessons[li++];
        items.add(_TimelineLesson(l));
      } else {
        final s = slots[si++];
        items.add(_TimelineSlot(s));
      }
    }
    return items;
  }

  List<_DateGroup> _buildNext7Days(DateTime now, List<Lesson> lessons, List<OpenSlot> slots) {
    final groups = <_DateGroup>[];
    for (int i = 0; i <= 7; i++) {
      final date = now.add(Duration(days: i));
      final dayLessons = lessons.where((l) =>
        l.date.year == date.year && l.date.month == date.month && l.date.day == date.day
      ).toList()..sort((a, b) => a.time.compareTo(b.time));

      final daySlots = slots.where((s) =>
        s.date.year == date.year && s.date.month == date.month && s.date.day == date.day
      ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

      if (dayLessons.isNotEmpty || daySlots.isNotEmpty) {
        final items = <dynamic>[];
        int li = 0, si = 0;
        while (li < dayLessons.length || si < daySlots.length) {
          if (si >= daySlots.length || (li < dayLessons.length && _compareTime(dayLessons[li].time, daySlots[si].startTime) <= 0)) {
            items.add(_TimelineLesson(dayLessons[li++]));
          } else {
            items.add(_TimelineSlot(daySlots[si++]));
          }
        }
        groups.add(_DateGroup(date: date, items: items));
      }
    }
    return groups;
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: AppEmptyState(
        icon: Icons.event_busy,
        title: _today ? 'No lessons or slots today' : 'Nothing scheduled for the week',
        subtitle: 'Tap + to create a lesson or open slot',
      ),
    );
  }

  Widget _buildUpNextCard(_TimelineLesson item, bool isDark) {
    final lesson = item.lesson;
    final initials = lesson.pupilName.isNotEmpty
        ? lesson.pupilName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';

    return AppCard(
      variant: CardVariant.gradient,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      gradient: LinearGradient(
        colors: isDark
            ? [AppColors.darkCard, AppColors.darkCardElevated]
            : [AppColors.sunsetBright, AppColors.sunset],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: 24,
      contentPadding: const EdgeInsets.all(24),
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
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.pupilName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatTime(lesson.time)} - ${_calculateEndTime(lesson.time, lesson.duration)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (lesson.rate > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\u00a3${lesson.rate.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (lesson.pickupLocation != null && lesson.pickupLocation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.trip_origin, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lesson.pickupLocation!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          if (lesson.dropoffLocation != null && lesson.dropoffLocation!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lesson.dropoffLocation!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                _formatDuration(lesson.duration),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(_TimelineLesson item, bool isDark) {
    final lesson = item.lesson;
    final initials = lesson.pupilName.isNotEmpty
        ? lesson.pupilName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';

    return AppCard(
      variant: CardVariant.outlined,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {},
      child: Row(
        children: [
          AvatarCircle(initials: initials, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.pupilName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(lesson.time)} - ${_calculateEndTime(lesson.time, lesson.duration)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                ),
                if (lesson.pickupLocation != null && lesson.pickupLocation!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    lesson.pickupLocation!,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sunsetBright.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(lesson.duration),
                  style: const TextStyle(
                    color: AppColors.sunsetBright,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (lesson.rate > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '\u00a3${lesson.rate.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(_TimelineSlot item, bool isDark) {
    final slot = item.slot;
    return AppCard(
      variant: CardVariant.outlined,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.event_available, color: AppColors.info, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open Slot',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(slot.startTime)} - ${_calculateEndTime(slot.startTime, slot.duration)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDuration(slot.duration),
              style: const TextStyle(
                color: AppColors.info,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineLesson {
  final Lesson lesson;
  const _TimelineLesson(this.lesson);
}

class _TimelineSlot {
  final OpenSlot slot;
  const _TimelineSlot(this.slot);
}

class _DateGroup {
  final DateTime date;
  final List<dynamic> items;
  const _DateGroup({required this.date, required this.items});
}

class _DayHeaderLabel extends StatelessWidget {
  final String text;
  const _DayHeaderLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sunsetBright.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.sunsetBright,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  final int flex;

  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessChip extends StatelessWidget {
  const _QuickAccessChip({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
