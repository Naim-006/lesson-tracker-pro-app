import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay? _time;
  bool _allDay = false;
  bool _syncExternal = false;
  String? _selectedCalendar;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('calendar_events').insert({
        'instructor_id': user.id,
        'title': _title.text.trim(),
        'description': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
        'event_date': _date.toIso8601String().split('T')[0],
        'event_time': _allDay || _time == null
            ? null
            : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
        'is_all_day': _allDay,
      });

      if (mounted) {
        ref.invalidate(instructorCalendarEventsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  void _showCalendarPicker(BuildContext context) {
    final calendars = ['Lesson Tracker Pro', 'Google Calendar', 'Apple Calendar', 'Outlook'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Calendar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: calendars.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(calendars[i]),
                onTap: () {
                  setState(() => _selectedCalendar = calendars[i]);
                  Navigator.pop(ctx);
                },
                trailing: _selectedCalendar == calendars[i] ? const Icon(Icons.check, color: AppColors.sunsetBright) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_date.year, _date.month, 1);
    final lastDayOfMonth = DateTime(_date.year, _date.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday % 7;
    
    final days = <Widget>[];
    
    // Add empty cells for days before the first day of the month
    for (int i = 0; i < startingWeekday; i++) {
      days.add(const SizedBox.shrink());
    }
    
    // Add days of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final dayDate = DateTime(_date.year, _date.month, day);
      final isSelected = dayDate.year == _date.year && dayDate.month == _date.month && dayDate.day == _date.day;
      final isToday = dayDate.year == DateTime.now().year && dayDate.month == DateTime.now().month && dayDate.day == DateTime.now().day;
      
      days.add(
        GestureDetector(
          onTap: () => setState(() => _date = dayDate),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.sunsetBright : (isToday ? AppColors.sunsetBright.withValues(alpha: 0.2) : Colors.transparent),
              borderRadius: BorderRadius.circular(18),
              border: isToday && !isSelected ? Border.all(color: AppColors.sunsetBright, width: 2) : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isToday ? AppColors.sunsetBright : Colors.grey.shade700),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Wrap(
          children: days,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _date = DateTime.now()),
          child: const Text('Today', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.sunsetBright)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New event', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.sunsetBright,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Title Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sunsetBright.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.event, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Event Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _location,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Calendar Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sunsetBright.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Calendar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _showCalendarPicker(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note, color: AppColors.sunsetBright),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Select calendar', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_selectedCalendar ?? 'Lesson Tracker Pro', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Date & Time Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sunsetBright.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text('All day', style: TextStyle(fontWeight: FontWeight.w700)),
                    value: _allDay,
                    onChanged: (v) => setState(() => _allDay = v),
                    activeThumbColor: AppColors.sunsetBright,
                  ),
                ),
                const SizedBox(height: 16),
                // Inline Calendar Widget
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Month navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() => _date = DateTime(_date.year, _date.month - 1, 1));
                            },
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(_date),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() => _date = DateTime(_date.year, _date.month + 1, 1));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Weekday headers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            .map((d) => Text(
                                  d,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      // Calendar grid
                      _buildCalendarGrid(),
                    ],
                  ),
                ),
                if (!_allDay) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _time ?? TimeOfDay.now(),
                      );
                      if (t != null) setState(() => _time = t);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.sunsetBright),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Time', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(_time?.format(context) ?? 'Not set', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notes Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sunsetBright.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.note, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Notes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notes,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sync Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              title: const Text('Sync to Lesson Tracker Pro', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Export event to external calendar', style: TextStyle(fontSize: 12)),
              value: _syncExternal,
              onChanged: (v) => setState(() => _syncExternal = v),
              activeThumbColor: AppColors.sunsetBright,
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sunsetBright, AppColors.sunsetBright.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sunsetBright.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
