import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import 'lesson_detail_sheet.dart';
import 'lesson_form_screen.dart';
import 'open_slot_detail_screen.dart';
import 'open_slot_form_screen.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  bool _weekView = false;
  DateTime _focused = DateTime.now();

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(2020, 1, 1, h, m);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  String _formatDuration(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h 0m';
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

  LessonStatus _mapLessonStatus(String? status) {
    switch (status) {
      case 'completed':
        return LessonStatus.completed;
      case 'cancelled':
        return LessonStatus.cancelled;
      case 'no_show':
        return LessonStatus.noShow;
      default:
        return LessonStatus.scheduled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructorLessons = ref.watch(instructorLessonsProvider);
    final instructorSlots = ref.watch(instructorSlotsProvider);
    final instructorPupils = ref.watch(instructorPupilsProvider);
    final instructorCalendarEvents = ref.watch(instructorCalendarEventsProvider);
    final days = _weekView
        ? List.generate(7, (i) => _focused.subtract(Duration(days: _focused.weekday - 1)).add(Duration(days: i)))
        : [_focused];

    // Convert Supabase data to local models
    final lessons = instructorLessons.value?.map((lesson) {
      final pupilData = lesson['pupils'];
      final profile = pupilData?['profiles'];
      return Lesson(
        pupilId: lesson['pupil_id'],
        pupilName: profile?['full_name'] ?? 'Unknown',
        date: DateTime.parse(lesson['date']),
        time: lesson['time'],
        duration: lesson['duration'] ?? 60,
        rate: lesson['rate'] ?? 40.0,
        pickupLocation: lesson['pickup_location'] ?? '',
        status: _mapLessonStatus(lesson['status']),
        notes: lesson['notes'] ?? '',
      );
    }).toList() ?? [];

    final slots = instructorSlots.value?.map((slot) {
      return OpenSlot(
        date: DateTime.parse(slot['date']),
        startTime: slot['start_time'],
        duration: slot['duration'] ?? 60,
      );
    }).toList() ?? [];

    // Convert pupils from Supabase
    final pupils = instructorPupils.value?.map((link) {
      final pupilData = link['pupils'];
      final profile = pupilData?['profiles'];
      return Pupil(
        id: pupilData['id'],
        firstName: profile?['full_name']?.split(' ').first ?? '',
        lastName: profile?['full_name']?.split(' ').last ?? '',
        phone: profile?['phone'] ?? '',
        email: profile?['email'] ?? '',
        postcode: pupilData['postcode'],
        pickupAddresses: pupilData['address'] != null ? [pupilData['address']] : [],
        outstandingBalance: 0.0, // Will need to calculate from payments
      );
    }).toList() ?? [];

    // Convert calendar events from Supabase
    final events = instructorCalendarEvents.value?.map((event) {
      return CalendarEvent(
        id: event['id'],
        title: event['title'],
        date: DateTime.parse(event['date']),
        time: event['time'],
        endTime: event['end_time'],
        isAllDay: event['is_all_day'] ?? false,
        notes: event['description'],
        location: event['location'],
      );
    }).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.lightBorder.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _weekView = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: !_weekView ? AppColors.sunsetBright : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'DAY',
                          style: TextStyle(
                            color: !_weekView ? Colors.white : AppColors.lightMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _weekView = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _weekView ? AppColors.sunsetBright : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'WEEK',
                          style: TextStyle(
                            color: _weekView ? Colors.white : AppColors.lightMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Month Nav & Day Strip
        if (!_weekView)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightBorder.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20, color: AppColors.lightText),
                        onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month - 1, _focused.day)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_focused),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.lightText),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightBorder.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20, color: AppColors.lightText),
                        onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month + 1, _focused.day)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _focused = DateTime.now()),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: AppColors.sunsetBright,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: 14,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final day = DateTime(_focused.year, _focused.month, _focused.day).subtract(const Duration(days: 7)).add(Duration(days: i));
                      final isSelected = day.day == _focused.day && day.month == _focused.month && day.year == _focused.year;
                      return GestureDetector(
                        onTap: () => setState(() => _focused = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.sunsetBright : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: !isSelected ? Border.all(color: AppColors.lightBorder.withValues(alpha: 0.6)) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E').format(day),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.lightMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('d').format(day),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.lightText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightBorder.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20, color: AppColors.lightText),
                    onPressed: () => setState(() => _focused = _focused.subtract(const Duration(days: 7))),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
                Text(
                  'Week of ${DateFormat('MMM d').format(days.first)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.lightText),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightBorder.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20, color: AppColors.lightText),
                    onPressed: () => setState(() => _focused = _focused.add(const Duration(days: 7))),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(instructorLessonsProvider);
              ref.invalidate(instructorSlotsProvider);
              ref.invalidate(instructorCalendarEventsProvider);
            },
            child: _weekView
                ? _WeekGridView(focused: _focused)
                : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  children: days.expand((day) {
              final dayLessons = lessons.where((l) => l.date.year == day.year && l.date.month == day.month && l.date.day == day.day).toList();
              final daySlots = slots.where((s) => s.date.year == day.year && s.date.month == day.month && s.date.day == day.day).toList();
              final dayEvents = events.where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day).toList();

              final timelineItems = <dynamic>[...dayLessons, ...daySlots, ...dayEvents];
              timelineItems.sort((a, b) {
                String timeA = a is Lesson ? a.time : (a is OpenSlot ? a.startTime : (a is CalendarEvent ? (a.time ?? '00:00') : '00:00'));
                String timeB = b is Lesson ? b.time : (b is OpenSlot ? b.startTime : (b is CalendarEvent ? (b.time ?? '00:00') : '00:00'));
                return timeA.compareTo(timeB);
              });

              return [
                if (timelineItems.isEmpty)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available, size: 56, color: AppColors.lightMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 24),
                        const Text(
                          'No lessons or events',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightText),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap the buttons below to add one',
                          style: TextStyle(fontSize: 14, color: AppColors.lightMuted),
                        ),
                      ],
                    ),
                  )
                else
                  ...timelineItems.map((item) {
                    if (item is Lesson) {
                      final pupil = pupils.firstWhere((p) => p.id == item.pupilId, orElse: () => Pupil(firstName: '', lastName: '', phone: ''));
                      final outBalance = pupil.outstandingBalance;
                      final isUnpaid = !item.paid;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => LessonDetailSheet(lesson: item),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.lightBorder.withValues(alpha: 0.5), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.pupilName.isNotEmpty ? item.pupilName[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: AppColors.info,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.pupilName,
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.lightText),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isUnpaid || outBalance > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'DUE \u00a3${(outBalance > 0 ? outBalance : item.rate).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: AppColors.error,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 13, color: AppColors.lightMuted),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${_formatTime(item.time)} - ${_calculateEndTime(item.time, item.duration)}',
                                              style: const TextStyle(color: AppColors.lightMuted, fontSize: 12),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.lightBorder.withValues(alpha: 0.5),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _formatDuration(item.duration),
                                                style: const TextStyle(color: AppColors.lightMuted, fontSize: 10, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item.pickupLocation != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Row(
                                              children: [
                                                Icon(Icons.location_on, size: 12, color: AppColors.lightMuted),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    item.pickupLocation!,
                                                    style: const TextStyle(fontSize: 11, color: AppColors.lightMuted),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    } else if (item is OpenSlot) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OpenSlotDetailScreen(slot: item))),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.lightBorder, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.sunsetBright.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.event_available, color: AppColors.sunsetBright, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '[Open Slot]',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.lightText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 13, color: AppColors.lightMuted),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${_formatTime(item.startTime)} - ${_calculateEndTime(item.startTime, item.duration)}',
                                              style: const TextStyle(color: AppColors.lightMuted, fontSize: 12),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.lightBorder.withValues(alpha: 0.5),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _formatDuration(item.duration),
                                                style: const TextStyle(color: AppColors.lightMuted, fontSize: 10, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    } else if (item is CalendarEvent) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.lightBorder.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(Icons.event, color: AppColors.lightMuted, size: 22),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.lightText),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 13, color: AppColors.lightMuted),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.isAllDay ? 'All Day' : '${_formatTime(item.time ?? "00:00")} - ${_formatTime(item.endTime ?? "00:00")}',
                                          style: const TextStyle(color: AppColors.lightMuted, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  }),
              ];
            }).toList(),
          ),
          ),
        ),

        // Bottom Action Buttons
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.lightCard,
            border: Border(top: BorderSide(color: AppColors.lightBorder.withValues(alpha: 0.6))),
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonFormScreen())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Lesson', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sunsetBright,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenSlotFormScreen())),
                  icon: const Icon(Icons.schedule, size: 16),
                  label: const Text('Open slot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.6)),
                    foregroundColor: AppColors.sunsetBright,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekGridView extends ConsumerWidget {
  const _WeekGridView({required this.focused});
  final DateTime focused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = List.generate(7, (i) => focused.subtract(Duration(days: focused.weekday - 1)).add(Duration(days: i)));
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(7, (i) {
                final isToday = days[i].day == DateTime.now().day &&
                    days[i].month == DateTime.now().month &&
                    days[i].year == DateTime.now().year;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.sunsetBright.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekdays[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isToday ? AppColors.sunsetBright : AppColors.lightMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${days[i].day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isToday ? AppColors.sunsetBright : AppColors.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
