import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

class SelectCalendarScreen extends ConsumerStatefulWidget {
  const SelectCalendarScreen({super.key});

  @override
  ConsumerState<SelectCalendarScreen> createState() => _SelectCalendarScreenState();
}

class _SelectCalendarScreenState extends ConsumerState<SelectCalendarScreen> {
  String? _selectedCalendar;

  final List<String> _calendars = [
    'Lesson Tracker Pro',
    'Google Calendar',
    'Apple Calendar',
    'Outlook',
    'iCloud',
  ];

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
        title: const Text('Select Calendar', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.sunsetBright,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _selectedCalendar != null
                  ? () => Navigator.pop(context, _selectedCalendar)
                  : null,
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _calendars.length,
        itemBuilder: (context, index) {
          final calendar = _calendars[index];
          final isSelected = _selectedCalendar == calendar;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.sunsetBright.withValues(alpha: 0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: isSelected ? AppColors.sunsetBright : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              title: Text(
                calendar,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isSelected ? AppColors.sunsetBright : Colors.black87,
                ),
              ),
              subtitle: Text(
                _getCalendarDescription(calendar),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              trailing: isSelected
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sunsetBright,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 20),
                    )
                  : null,
              onTap: () => setState(() => _selectedCalendar = calendar),
            ),
          );
        },
      ),
    );
  }

  String _getCalendarDescription(String calendar) {
    switch (calendar) {
      case 'Lesson Tracker Pro':
        return 'Default Lesson Tracker Pro calendar';
      case 'Google Calendar':
        return 'Sync with Google account';
      case 'Apple Calendar':
        return 'Sync with Apple ID';
      case 'Outlook':
        return 'Sync with Microsoft account';
      case 'iCloud':
        return 'Sync with iCloud calendar';
      default:
        return '';
    }
  }
}
