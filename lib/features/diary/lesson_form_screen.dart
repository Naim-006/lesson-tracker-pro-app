import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';
import 'location_picker_screen.dart';

class LessonFormScreen extends ConsumerStatefulWidget {
  const LessonFormScreen({super.key, this.existing});

  final Lesson? existing;

  @override
  ConsumerState<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends ConsumerState<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Pupil? _pupil;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _duration = 60;
  LessonType _type = LessonType.drivingLesson;
  final _pickup = TextEditingController();
  final _dropoff = TextEditingController();
  final _notes = TextEditingController();
  bool _recurring = false;
  String _recurrencePattern = 'Weekly';
  bool _shared = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _date = e.date;
      _time = TimeOfDay(
        hour: int.parse(e.time.split(':')[0]),
        minute: int.parse(e.time.split(':')[1]),
      );
      _duration = e.duration;
      _type = e.type;
      _pickup.text = e.pickupLocation ?? '';
      _dropoff.text = e.dropoffLocation ?? '';
      _notes.text = e.notes ?? '';
      _recurring = e.isRecurring;
      _shared = e.sharedWithPupil;
    }
  }

  @override
  void dispose() {
    _pickup.dispose();
    _dropoff.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pupil == null && widget.existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a pupil')));
      return;
    }
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final finalPupilId = _pupil?.id ?? widget.existing!.pupilId;
    final finalRate = _pupil != null ? _pupil!.hourlyRate : (widget.existing?.rate ?? 40.0) / ((widget.existing?.duration ?? 60) / 60);

    final lessonData = {
      'instructor_id': user.id,
      'pupil_id': finalPupilId,
      'date': _date.toIso8601String().split('T')[0],
      'time': '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      'duration': _duration,
      'rate': finalRate * (_duration / 60),
      'pickup_location': _pickup.text.trim().isEmpty ? null : _pickup.text.trim(),
      'dropoff_location': _dropoff.text.trim().isEmpty ? null : _dropoff.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'status': widget.existing == null ? 'scheduled' : _mapLessonStatus(widget.existing!.status),
    };

    try {
      if (widget.existing != null) {
        await Supabase.instance.client
            .from('lessons')
            .update(lessonData)
            .eq('id', widget.existing!.id);
      } else {
        await Supabase.instance.client.from('lessons').insert(lessonData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lesson created')),
          );
        }
      }
      if (mounted) {
        ref.invalidate(instructorLessonsProvider);
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

  String _mapLessonStatus(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return 'completed';
      case LessonStatus.cancelled:
        return 'cancelled';
      case LessonStatus.noShow:
        return 'no_show';
      default:
        return 'scheduled';
    }
  }

  String _formatTime(TimeOfDay t) {
    final dt = DateTime(2020, 1, 1, t.hour, t.minute);
    return DateFormat('h:mm a').format(dt);
  }

  String _calculateEndTime() {
    final dt = DateTime(2020, 1, 1, _time.hour, _time.minute).add(Duration(minutes: _duration));
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final instructorPupils = ref.watch(instructorPupilsProvider);

    // Convert Supabase data to local Pupil models
    final pupils = instructorPupils.value?.map((link) {
      final pupilData = link['pupils'] ?? <String, dynamic>{};
      return Pupil(
        id: pupilData['id'],
        firstName: pupilData['first_name'] ?? '',
        lastName: pupilData['last_name'] ?? '',
        phone: pupilData['phone'] ?? '',
        email: pupilData['email'] ?? '',
        postcode: pupilData['postcode'],
        pickupAddresses: pupilData['pickup_addresses'] != null
            ? List<String>.from(pupilData['pickup_addresses'])
            : [],
        hourlyRate: (pupilData['hourly_rate'] as num?)?.toDouble() ?? 40.0,
      );
    }).toList() ?? [];
    
    // Pre-select pupil if editing
    if (_pupil == null && widget.existing != null) {
      try {
        _pupil = pupils.firstWhere((p) => p.id == widget.existing!.pupilId);
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existing == null ? 'Book Lesson' : 'Edit Lesson',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.sunsetBright,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _save,
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Searchable Pupil Dropdown
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownMenu<Pupil>(
                initialSelection: _pupil,
                width: MediaQuery.of(context).size.width - 40,
                label: const Text('Select Pupil'),
                dropdownMenuEntries: pupils.map((p) => DropdownMenuEntry(value: p, label: p.fullName)).toList(),
                onSelected: (p) {
                  setState(() {
                    _pupil = p;
                    if (p != null && p.pickupAddresses.isNotEmpty) {
                      _pickup.text = p.pickupAddresses.first;
                    }
                    if (p != null && p.dropoffAddresses.isNotEmpty) {
                      _dropoff.text = p.dropoffAddresses.first;
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Lesson Type
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<LessonType>(
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: 'Lesson Type',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: LessonType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(labelEnum(t))))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
            ),
            const SizedBox(height: 24),

            // Visual Booking Bar
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          '${_formatTime(_time)} — ${_calculateEndTime()}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_date),
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date / Time Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.sunsetBright),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(DateFormat('dd/MM/yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
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
                                Text('Start Time', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(_time.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Duration Pills
            Text('Duration', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDurationChip(60, '1 hour'),
                _buildDurationChip(120, '2 hours'),
                _buildDurationChip(180, '3 hours'),
                ChoiceChip(
                  label: const Text('Custom +'),
                  selected: ![60, 120, 180].contains(_duration),
                  onSelected: (_) async {
                    final res = await showDialog<int>(
                      context: context,
                      builder: (c) {
                        int customVal = 90;
                        return AlertDialog(
                          title: const Text('Custom Duration (mins)'),
                          content: TextFormField(
                            initialValue: '90',
                            keyboardType: TextInputType.number,
                            onChanged: (v) => customVal = int.tryParse(v) ?? 90,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, customVal), child: const Text('OK'))
                          ],
                        );
                      }
                    );
                    if (res != null) {
                      setState(() => _duration = res);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Locations Card
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
                        child: const Icon(Icons.location_on, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Locations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LocationField(
                    label: 'Pickup location',
                    icon: Icons.trip_origin,
                    value: _pickup.text,
                    hint: 'e.g. SW1A 1AA',
                    onTap: () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationPickerScreen(initialAddress: _pickup.text),
                        ),
                      );
                      if (result != null) {
                        _pickup.text = result;
                        setState(() {});
                      }
                    },
                    onClear: () {
                      _pickup.clear();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  _LocationField(
                    label: 'Drop-off location',
                    icon: Icons.location_on,
                    value: _dropoff.text,
                    hint: 'e.g. BN1 1AA',
                    onTap: () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationPickerScreen(initialAddress: _dropoff.text),
                        ),
                      );
                      if (result != null) {
                        _dropoff.text = result;
                        setState(() {});
                      }
                    },
                    onClear: () {
                      _dropoff.clear();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Shared with Pupil Warning Banner
            if (_shared)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SHARED WITH PUPIL', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber)),
                          const SizedBox(height: 4),
                          Text('This lesson and locations will be visible in their companion app.', style: TextStyle(fontSize: 12, color: Colors.amber.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: const Text('Share with pupil', style: TextStyle(fontWeight: FontWeight.w700)),
                value: _shared,
                onChanged: (v) => setState(() => _shared = v),
                activeThumbColor: AppColors.sunsetBright,
              ),
            ),
            const SizedBox(height: 24),

            // Recurrence Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text('Recurring Lesson', style: TextStyle(fontWeight: FontWeight.w700)),
                    value: _recurring,
                    onChanged: (v) => setState(() => _recurring = v),
                    activeThumbColor: AppColors.sunsetBright,
                  ),
                  if (_recurring)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _recurrencePattern,
                        decoration: InputDecoration(
                          labelText: 'Pattern',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        items: ['Daily', 'Working Days', 'Weekly'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                        onChanged: (v) => setState(() => _recurrencePattern = v!),
                      ),
                    ),
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
                  TextFormField(
                    controller: _notes,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int mins, String label) {
    final isSelected = _duration == mins;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
      selected: isSelected,
      onSelected: (_) => setState(() => _duration = mins),
      selectedColor: AppColors.sunsetBright,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final IconData icon;
  final String value;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.sunsetBright.withValues(alpha: 0.05)
              : (isDark ? AppColors.darkCard : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: hasValue
              ? Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: hasValue ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasValue ? value : hint,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? (isDark ? AppColors.darkText : AppColors.lightText)
                          : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasValue)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.close, size: 14, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            Icon(
              Icons.search,
              size: 18,
              color: hasValue ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
            ),
          ],
        ),
      ),
    );
  }
}
