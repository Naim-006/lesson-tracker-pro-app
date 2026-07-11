import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/utils/route_transitions.dart';
import '../diary/lesson_detail_screen.dart';
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

  Future<void> _openInMaps(String query) async {
    final uri = Uri.parse(GeocodingService.googleMapsQueryUrl(query));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showLessonDetail(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(lesson: lesson),
      ),
    );
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
      final String pupilName = pupilData != null
          ? '${pupilData['first_name'] ?? ''} ${pupilData['last_name'] ?? ''}'.trim()
          : 'Unknown';
      return Lesson(
        id: l['id'],
        pupilId: l['pupil_id'],
        pupilName: pupilName.isNotEmpty ? pupilName : 'Unknown',
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
    final hasLocation = lesson.pickupLocation != null && lesson.pickupLocation!.isNotEmpty;
    final mapUrl = hasLocation ? GeocodingService.staticMapUrl(lesson.pickupLocation!, width: 800, height: 300, zoom: 15) : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GestureDetector(
        onTap: () => _showLessonDetail(lesson),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? AppColors.darkCard : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Map section
              if (hasLocation)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.network(
                      mapUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return _mapPlaceholder(isDark);
                      },
                      errorBuilder: (_, __, ___) => _mapPlaceholder(isDark),
                    ),
                  ),
                )
              else
                _mapPlaceholder(isDark),
              // Content section
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.sunsetBright.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.navigation, size: 12, color: AppColors.sunsetBright),
                              const SizedBox(width: 4),
                              Text(
                                'UP NEXT',
                                style: TextStyle(
                                  color: AppColors.sunsetBright,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (lesson.rate > 0)
                          Text(
                            '\u00a3${lesson.rate.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppColors.sunsetBright,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.sunsetBright.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: AppColors.sunsetBright,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
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
                                style: TextStyle(
                                  color: isDark ? AppColors.darkText : AppColors.lightText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12,
                                      color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_formatTime(lesson.time)} - ${_calculateEndTime(lesson.time, lesson.duration)}',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 20,
                            color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                      ],
                    ),
                    if (hasLocation || (lesson.dropoffLocation != null && lesson.dropoffLocation!.isNotEmpty)) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (hasLocation)
                              _buildMapStop(Icons.trip_origin, lesson.pickupLocation!, isDark, isFirst: true),
                            if (lesson.dropoffLocation != null && lesson.dropoffLocation!.isNotEmpty)
                              _buildMapStop(Icons.location_on, lesson.dropoffLocation!, isDark, isLast: true),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapPlaceholder(bool isDark) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFE8F0FE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 36,
                color: isDark ? AppColors.darkMuted : const Color(0xFF9AA0A6)),
            const SizedBox(height: 8),
            Text(
              'No location set',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkMuted : const Color(0xFF9AA0A6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStop(IconData icon, String label, bool isDark, {bool isFirst = false, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 6),
      child: GestureDetector(
        onTap: () => _openInMaps(label),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.sunsetBright),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.map, size: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(_TimelineLesson item, bool isDark) {
    final lesson = item.lesson;
    final statusColor = lesson.status == LessonStatus.completed
        ? AppColors.success
        : lesson.status == LessonStatus.cancelled
            ? AppColors.error
            : lesson.status == LessonStatus.noShow
                ? AppColors.warning
                : AppColors.sunsetBright;
    final hasLocation = lesson.pickupLocation != null && lesson.pickupLocation!.isNotEmpty;
    final mapUrl = hasLocation ? GeocodingService.staticMapUrl(lesson.pickupLocation!, width: 300, height: 300, zoom: 15) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showLessonDetail(lesson),
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Map thumbnail on left
                  if (hasLocation)
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      child: SizedBox(
                        width: 100,
                        child: Image.network(
                          mapUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFE8F0FE));
                          },
                          errorBuilder: (_, __, ___) =>
                              Container(color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFE8F0FE)),
                        ),
                      ),
                    ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lesson.pupilName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                ),
                              ),
                              if (lesson.status != LessonStatus.scheduled)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lesson.status.name.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 11,
                                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${_formatTime(lesson.time)} - ${_calculateEndTime(lesson.time, lesson.duration)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (lesson.pickupLocation != null && lesson.pickupLocation!.isNotEmpty)
                            _buildCardStop(Icons.trip_origin, lesson.pickupLocation!, isDark),
                          if (lesson.dropoffLocation != null && lesson.dropoffLocation!.isNotEmpty)
                            _buildCardStop(Icons.location_on, lesson.dropoffLocation!, isDark),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (lesson.rate > 0)
                                Text(
                                  '\u00a3${lesson.rate.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: lesson.paid ? AppColors.success : AppColors.sunsetBright,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if (lesson.paid) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle, size: 12, color: AppColors.success),
                                const SizedBox(width: 2),
                                Text(
                                  'PAID',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Icon(Icons.chevron_right, size: 16,
                                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardStop(IconData icon, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onTap: () => _openInMaps(label),
        child: Row(
          children: [
            Icon(icon, size: 11, color: AppColors.sunsetBright),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.map, size: 9, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
          ],
        ),
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
