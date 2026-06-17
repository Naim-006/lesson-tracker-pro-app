import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/theme/app_colors.dart';

class WorkHoursScreen extends ConsumerStatefulWidget {
  const WorkHoursScreen({super.key});

  @override
  ConsumerState<WorkHoursScreen> createState() => _WorkHoursScreenState();
}

class _WorkHoursScreenState extends ConsumerState<WorkHoursScreen> {
  final Map<String, bool> _workingDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };

  final Map<String, TimeOfDay> _startTime = {
    'Monday': const TimeOfDay(hour: 9, minute: 0),
    'Tuesday': const TimeOfDay(hour: 9, minute: 0),
    'Wednesday': const TimeOfDay(hour: 9, minute: 0),
    'Thursday': const TimeOfDay(hour: 9, minute: 0),
    'Friday': const TimeOfDay(hour: 9, minute: 0),
    'Saturday': const TimeOfDay(hour: 9, minute: 0),
    'Sunday': const TimeOfDay(hour: 9, minute: 0),
  };

  final Map<String, TimeOfDay> _endTime = {
    'Monday': const TimeOfDay(hour: 17, minute: 0),
    'Tuesday': const TimeOfDay(hour: 17, minute: 0),
    'Wednesday': const TimeOfDay(hour: 17, minute: 0),
    'Thursday': const TimeOfDay(hour: 17, minute: 0),
    'Friday': const TimeOfDay(hour: 17, minute: 0),
    'Saturday': const TimeOfDay(hour: 17, minute: 0),
    'Sunday': const TimeOfDay(hour: 17, minute: 0),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Hours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: AppColors.sunsetBright),
                      const SizedBox(width: 8),
                      const Text(
                        'Working Schedule',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select the days you work and set your working hours for each day.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._workingDays.keys.map((day) => _DayCard(
            day: day,
            isWorking: _workingDays[day]!,
            startTime: _startTime[day]!,
            endTime: _endTime[day]!,
            onToggle: (v) => setState(() => _workingDays[day] = v),
            onStartTimeChange: (t) => setState(() => _startTime[day] = t),
            onEndTimeChange: (t) => setState(() => _endTime[day] = t),
          )),
        ],
      ),
    );
  }

  void _saveSettings() {
    final workHours = <String, dynamic>{};
    for (final day in _workingDays.keys) {
      workHours[day] = {
        'isWorking': _workingDays[day],
        'startTime': '${_startTime[day]!.hour.toString().padLeft(2, '0')}:${_startTime[day]!.minute.toString().padLeft(2, '0')}',
        'endTime': '${_endTime[day]!.hour.toString().padLeft(2, '0')}:${_endTime[day]!.minute.toString().padLeft(2, '0')}',
      };
    }
    final s = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).update(s.copyWith(workHours: workHours));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Work hours saved successfully')),
    );
    Navigator.pop(context);
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isWorking,
    required this.startTime,
    required this.endTime,
    required this.onToggle,
    required this.onStartTimeChange,
    required this.onEndTimeChange,
  });

  final String day;
  final bool isWorking;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final void Function(bool) onToggle;
  final void Function(TimeOfDay) onStartTimeChange;
  final void Function(TimeOfDay) onEndTimeChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Switch(
                  value: isWorking,
                  onChanged: onToggle,
                  activeColor: AppColors.sunsetBright,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isWorking ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
                if (isWorking) ...[
                  _TimeButton(
                    label: 'Start',
                    time: startTime,
                    onTap: () => _selectTime(context, startTime, onStartTimeChange),
                  ),
                  const SizedBox(width: 8),
                  _TimeButton(
                    label: 'End',
                    time: endTime,
                    onTap: () => _selectTime(context, endTime, onEndTimeChange),
                  ),
                ],
              ],
            ),
            if (!isWorking)
              const Padding(
                padding: EdgeInsets.only(left: 56, top: 8),
                child: Text(
                  'Day off',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectTime(BuildContext context, TimeOfDay initialTime, void Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.sunsetBright,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
