import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';
import '../finances/request_payment_form_screen.dart';
import 'lesson_detail_screen.dart';
import 'lesson_form_screen.dart';
import 'open_slot_detail_screen.dart';
import 'open_slot_form_screen.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  DateTime _selected = DateTime.now();
  DateTime _focusMonth = DateTime.now();
  int _filter = 0;

  static const _mn = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  String _fmt(String t) {
    try {
      final p = t.split(':');
      return DateFormat('h:mm a').format(DateTime(2020,1,1,int.parse(p[0]),int.parse(p[1])));
    } catch (_) { return t; }
  }
  String _dur(int m) {
    final h = m ~/ 60; final r = m % 60;
    return h > 0 ? '${h}h${r > 0 ? ' ${r}m' : ''}' : '${r}m';
  }
  String _end(String s, int d) {
    try {
      final p = s.split(':');
      return DateFormat('h:mm a').format(DateTime(2020,1,1,int.parse(p[0]),int.parse(p[1])).add(Duration(minutes: d)));
    } catch (_) { return ''; }
  }
  LessonStatus _ms(String? s) {
    switch (s) {
      case 'completed': return LessonStatus.completed;
      case 'cancelled': return LessonStatus.cancelled;
      case 'no_show': return LessonStatus.noShow;
      default: return LessonStatus.scheduled;
    }
  }
  bool _sd(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> _grid(DateTime m) {
    final f = DateTime(m.year, m.month, 1);
    final l = DateTime(m.year, m.month + 1, 0);
    final s = f.subtract(Duration(days: (f.weekday - 1) % 7));
    final e = l.add(Duration(days: (7 - l.weekday) % 7));
    final r = <DateTime>[];
    var d = s;
    while (!d.isAfter(e)) { r.add(d); d = d.add(const Duration(days: 1)); }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final instructorLessons = ref.watch(instructorLessonsProvider);
    final instructorSlots = ref.watch(instructorSlotsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lessons = (instructorLessons.value ?? []).map((l) {
      final pd = l['pupils'];
      return Lesson(
        id: l['id'], pupilId: l['pupil_id'],
        pupilName: pd != null ? '${pd['first_name'] ?? ''} ${pd['last_name'] ?? ''}'.trim() : 'Unknown',
        date: DateTime.parse(l['date']), time: l['time'],
        duration: l['duration'] ?? 60, rate: l['rate'] ?? 40.0,
        paid: l['paid'] ?? false,
        pickupLocation: l['pickup_location'], dropoffLocation: l['dropoff_location'],
        status: _ms(l['status']), notes: l['notes'],
      );
    }).toList();

    final slots = (instructorSlots.value ?? []).map((s) => OpenSlot(
      date: DateTime.parse(s['date']), startTime: s['start_time'],
      duration: s['duration'] ?? 60,
    )).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lDates = lessons.map((l) => l.date).toSet();
    final sDates = slots.map((s) => s.date).toSet();

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF8F9FA),
      body: _filter == 0 ? _scheduleView(lessons, slots, lDates, sDates, today, now, isDark) : _historyView(lessons, today, now, isDark),
      bottomNavigationBar: _filter == 0 ? _bottomBar(isDark) : _historyBottomBar(isDark),
    );
  }

  // ──────────────────────── SCHEDULE VIEW (filter = All) ────────────────────────
  Widget _scheduleView(List<Lesson> lessons, List<OpenSlot> slots, Set<DateTime> lDates, Set<DateTime> sDates, DateTime today, DateTime now, bool isDark) {
    final dayItems = <dynamic>[
      ...lessons.where((l) => _sd(l.date, _selected)),
      ...slots.where((s) => _sd(s.date, _selected)),
    ];
    dayItems.sort((a, b) {
      final ta = a is Lesson ? a.time : (a as OpenSlot).startTime;
      final tb = b is Lesson ? b.time : (b as OpenSlot).startTime;
      return ta.compareTo(tb);
    });

    // Show only future/current items in schedule view
    final scheduleItems = dayItems.where((i) {
      if (i is! Lesson) return true;
      return !i.date.isBefore(today) || i.status == LessonStatus.scheduled;
    }).toList();

    return Column(
      children: [
        _calendar(isDark, lDates, sDates, today),
        _filterChips(isDark),
        Expanded(
          child: scheduleItems.isEmpty
              ? _emptyState(isDark, 'Clear schedule', 'No lessons scheduled for this day')
              : RefreshIndicator(
                  onRefresh: () async { ref.invalidate(instructorLessonsProvider); ref.invalidate(instructorSlotsProvider); },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: scheduleItems.length,
                    itemBuilder: (_, i) {
                      final item = scheduleItems[i];
                      if (item is Lesson) return _scheduleCard(item, isDark, now);
                      if (item is OpenSlot) return _slotCard(item, isDark);
                      return const SizedBox();
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ──────────────────────── HISTORY VIEW (Overdue / Completed / Cancelled) ────────────────────────
  Widget _historyView(List<Lesson> lessons, DateTime today, DateTime now, bool isDark) {
    List<Lesson> items;
    String title;
    IconData icon;
    Color color;

    switch (_filter) {
      case 1: // Overdue
        items = lessons.where((l) => l.date.isBefore(today) && l.status == LessonStatus.scheduled).toList();
        items.sort((a, b) => b.date.compareTo(a.date));
        title = 'Overdue'; icon = Icons.schedule_send; color = AppColors.warning;
        break;
      case 2: // Completed
        items = lessons.where((l) => l.status == LessonStatus.completed).toList();
        items.sort((a, b) => b.date.compareTo(a.date));
        title = 'Completed'; icon = Icons.check_circle; color = AppColors.success;
        break;
      case 3: // Cancelled
        items = lessons.where((l) => l.status == LessonStatus.cancelled || l.status == LessonStatus.noShow).toList();
        items.sort((a, b) => b.date.compareTo(a.date));
        title = 'Cancelled / No Show'; icon = Icons.cancel; color = AppColors.error;
        break;
      default:
        items = []; title = ''; icon = Icons.error; color = AppColors.error;
    }

    return Column(
      children: [
        _historyHeader(title, icon, color, items.length, isDark),
        _filterChips(isDark),
        Expanded(
          child: items.isEmpty
              ? _emptyState(isDark, 'Nothing here', 'No $title lessons')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _historyCard(items[i], isDark, now, color),
                ),
        ),
      ],
    );
  }

  Widget _historyHeader(String title, IconData icon, Color color, int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? AppColors.darkText : AppColors.lightText)),
              Text('$count lesson${count == 1 ? '' : 's'}', style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
            ],
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
        ],
      ),
    );
  }

  // ──────────────────────── CALENDAR ────────────────────────
  Widget _calendar(bool isDark, Set<DateTime> lDates, Set<DateTime> sDates, DateTime today) {
    final days = _grid(_focusMonth);
    final hd = days.take(7).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () => setState(() => _focusMonth = DateTime(_focusMonth.year, _focusMonth.month - 1)),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              Expanded(
                child: Center(
                  child: Text('${_mn[_focusMonth.month - 1]} ${_focusMonth.year}',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? AppColors.darkText : AppColors.lightText)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () => setState(() => _focusMonth = DateTime(_focusMonth.year, _focusMonth.month + 1)),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: hd.map((d) => Expanded(
              child: Center(
                child: Text(DateFormat('E').format(d).substring(0, 2),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 2),
          Column(
            children: List.generate(days.length ~/ 7, (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: List.generate(7, (col) {
                  final d = days[row * 7 + col];
                  final inM = d.month == _focusMonth.month;
                  final sel = _sd(d, _selected);
                  final isT = _sd(d, today);
                  final has = lDates.any((ld) => _sd(ld, d)) || sDates.any((sd) => _sd(sd, d));
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _selected = d; if (!inM) _focusMonth = DateTime(d.year, d.month); }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.sunsetBright : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${d.day}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: sel || isT ? FontWeight.w800 : FontWeight.w500,
                                  color: !inM ? (isDark ? AppColors.darkMuted : AppColors.lightMuted).withValues(alpha: 0.25)
                                      : sel ? Colors.white
                                      : isT ? AppColors.sunsetBright
                                      : (isDark ? AppColors.darkText : AppColors.lightText),
                                )),
                            if (inM && has)
                              Container(
                                width: 4, height: 4,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: sel ? Colors.white : AppColors.sunsetBright,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            )),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── FILTER CHIPS ────────────────────────
  Widget _filterChips(bool isDark) {
    final labels = ['All', 'Overdue', 'Completed', 'Cancelled'];
    final colors = [AppColors.sunsetBright, AppColors.warning, AppColors.success, AppColors.error];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(4, (i) {
          final active = _filter == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
              child: GestureDetector(
                onTap: () => setState(() => _filter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? colors[i].withValues(alpha: 0.1) : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? colors[i].withValues(alpha: 0.3) : (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(labels[i],
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: active ? colors[i] : (isDark ? AppColors.darkMuted : AppColors.lightMuted))),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────────── SCHEDULE CARD ────────────────────────
  Widget _scheduleCard(Lesson l, bool isDark, DateTime now) {
    final isDue = l.date.isBefore(now) && l.status == LessonStatus.scheduled && !l.paid;
    final sc = isDue ? AppColors.warning : AppColors.sunsetBright;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: l))),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(l.pupilName.isNotEmpty ? l.pupilName[0].toUpperCase() : '?',
                            style: TextStyle(color: sc, fontWeight: FontWeight.w700, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(l.pupilName,
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                                        color: isDark ? AppColors.darkText : AppColors.lightText)),
                              ),
                              if (l.rate > 0)
                                Text('\u00a3${l.rate.toStringAsFixed(0)}',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.sunsetBright)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                              const SizedBox(width: 4),
                              Text('${_fmt(l.time)} \u2212 ${_end(l.time, l.duration)}',
                                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(_dur(l.duration),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (l.pickupLocation != null && l.pickupLocation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.trip_origin, size: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(l.pickupLocation!,
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                if (isDue)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        _actBtn('Complete', Icons.check_circle_outline, AppColors.success, () => _complete(l)),
                        const SizedBox(width: 6),
                        _actBtn('Request', Icons.payments_outlined, AppColors.warning, () => _reqPay(l)),
                        const SizedBox(width: 6),
                        _actBtn('Cancel', Icons.cancel_outlined, AppColors.error, () => _cancel(l)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── HISTORY CARD ────────────────────────
  Widget _historyCard(Lesson l, bool isDark, DateTime now, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: l))),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(l.pupilName.isNotEmpty ? l.pupilName[0].toUpperCase() : '?',
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(l.pupilName,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                                    color: isDark ? AppColors.darkText : AppColors.lightText)),
                          ),
                          Text('\u00a3${l.rate.toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.sunsetBright)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 11, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                          const SizedBox(width: 4),
                          Text(DateFormat('MMM d, yyyy').format(l.date),
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 11, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                          const SizedBox(width: 3),
                          Text('${_fmt(l.time)} \u2212 ${_end(l.time, l.duration)}',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                        ],
                      ),
                      if (l.pickupLocation != null && l.pickupLocation!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.trip_origin, size: 10, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(l.pickupLocation!,
                                    style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      // Overdue action buttons
                      if (l.status == LessonStatus.scheduled && !l.paid)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              _actBtn('Complete', Icons.check_circle_outline, AppColors.success, () => _complete(l)),
                              const SizedBox(width: 6),
                              _actBtn('Request', Icons.payments_outlined, AppColors.warning, () => _reqPay(l)),
                              const SizedBox(width: 6),
                              _actBtn('Cancel', Icons.cancel_outlined, AppColors.error, () => _cancel(l)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l.status == LessonStatus.scheduled ? 'OVERDUE'
                        : l.status == LessonStatus.noShow ? 'NO SHOW'
                        : l.status.name.toUpperCase(),
                    style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slotCard(OpenSlot slot, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OpenSlotDetailScreen(slot: slot))),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(Icons.event_available, color: AppColors.info, size: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Open Slot',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontStyle: FontStyle.italic,
                              color: AppColors.info)),
                      const SizedBox(height: 2),
                      Text('${_fmt(slot.startTime)} \u2212 ${_end(slot.startTime, slot.duration)}',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_dur(slot.duration),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.info)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── BOTTOM BARS ────────────────────────
  Widget _bottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.3))),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenSlotFormScreen())),
              icon: const Icon(Icons.schedule, size: 16),
              label: const Text('Slot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.5)),
                foregroundColor: AppColors.sunsetBright,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.95),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _filter = 0),
            icon: const Icon(Icons.calendar_month, size: 16),
            label: const Text('Back to Schedule', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppColors.sunsetBright,
              side: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── HELPERS ────────────────────────
  Widget _emptyState(bool isDark, String title, String sub) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 48, color: (isDark ? AppColors.darkMuted : AppColors.lightMuted).withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
        ],
      ),
    );
  }

  Widget _actBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _complete(Lesson l) async {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return;
    try {
      await Supabase.instance.client.from('lessons').update({'status': 'completed'}).eq('id', l.id);
      if (mounted) { ref.invalidate(instructorLessonsProvider); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completed'), duration: Duration(seconds: 1))); }
    } catch (e) { if (mounted) _err(e); }
  }

  Future<void> _cancel(Lesson l) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Cancel lesson?'),
      content: Text('${l.pupilName} on ${DateFormat('MMM d').format(l.date)}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(c, true), child: const Text('Yes')),
      ],
    ));
    if (ok != true) return;
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return;
    try {
      await Supabase.instance.client.from('lessons').update({'status': 'cancelled'}).eq('id', l.id);
      if (mounted) { ref.invalidate(instructorLessonsProvider); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelled'))); }
    } catch (e) { if (mounted) _err(e); }
  }

  void _reqPay(Lesson l) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RequestPaymentFormScreen(initialPupilId: l.pupilId)));
  }

  void _err(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyError(e))));
  }
}
