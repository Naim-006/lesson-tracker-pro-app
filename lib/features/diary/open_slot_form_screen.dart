import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';
import 'specific_pupil_picker_sheet.dart';

class OpenSlotFormScreen extends ConsumerStatefulWidget {
  const OpenSlotFormScreen({super.key});

  @override
  ConsumerState<OpenSlotFormScreen> createState() => _OpenSlotFormScreenState();
}

class _OpenSlotFormScreenState extends ConsumerState<OpenSlotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 16, minute: 0);
  int _duration = 60;
  
  bool _multiSlot = false;
  String _frequency = 'Weekly';
  int _count = 5;

  String _groupFilter = 'current';
  String _gearboxFilter = 'Any';
  final Set<String> _selectedPupilIds = {};
  
  final _messageController = TextEditingController();
  bool _requireOnlinePay = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_groupFilter == 'specific' && _selectedPupilIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pupil')),
      );
      return;
    }
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final slotData = {
      'instructor_id': user.id,
      'date': _date.toIso8601String().split('T')[0],
      'start_time': '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      'duration': _duration,
      'is_recurring': _multiSlot,
      'recurrence_type': _multiSlot ? _frequency.toLowerCase().replaceAll(' ', '_') : null,
      'accepts_online_payment': _requireOnlinePay,
      'group_filter': _groupFilter == 'specific' ? 'specific_pupils' : 'current_pupils_only',
      'gearbox_filter': _mapGearboxFilter(_gearboxFilter),
      'target_pupil_ids': _groupFilter == 'specific' ? _selectedPupilIds.toList() : <String>[],
      'custom_message': _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      'slot_count': _multiSlot ? _count : 1,
      'status': 'tentative',
    };

    try {
      await Supabase.instance.client.from('open_slots').insert(slotData);
      
      final durationHrs = (_duration / 60).toStringAsFixed(1).replaceAll('.0', '');
      final timeStr = DateFormat('HH:mm').format(DateTime(2020, 1, 1, _time.hour, _time.minute));
      final audience = _groupFilter == 'specific'
          ? '${_selectedPupilIds.length} selected pupil${_selectedPupilIds.length == 1 ? '' : 's'}'
          : 'all current pupils';
      
      if (mounted) {
        ref.invalidate(instructorSlotsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open slot offered to $audience · $durationHrs hr at $timeStr')),
        );
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

  String _mapGearboxFilter(String filter) {
    switch (filter) {
      case 'Manual':
        return 'manual';
      case 'Automatic':
        return 'automatic';
      default:
        return 'any';
    }
  }

  List<SelectablePupil> _activePupils(List<Map<String, dynamic>> links) {
    return links
        .where((link) => link['status'] == 'active')
        .map((link) {
          final pupilData = link['pupils'] as Map<String, dynamic>? ?? {};
          final createdRaw = pupilData['created_at'] as String? ?? link['created_at'] as String?;
          return SelectablePupil(
            id: pupilData['id'] as String,
            fullName: '${pupilData['first_name'] ?? ''} ${pupilData['last_name'] ?? ''}'.trim(),
            sortDate: createdRaw != null ? DateTime.parse(createdRaw) : DateTime.fromMillisecondsSinceEpoch(0),
          );
        })
        .where((p) => p.id.isNotEmpty && p.fullName.isNotEmpty)
        .toList();
  }

  Future<void> _openPupilPicker(List<SelectablePupil> pupils) async {
    final result = await showSpecificPupilPicker(
      context: context,
      pupils: pupils,
      initialSelection: _selectedPupilIds,
    );
    if (result != null) {
      setState(() {
        _selectedPupilIds
          ..clear()
          ..addAll(result);
      });
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
    final activePupils = _activePupils(instructorPupils.value ?? []);
    final pupilNameById = {for (final p in activePupils) p.id: p.fullName};
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Offer Open Slot', style: TextStyle(fontWeight: FontWeight.w700)),
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
            // Visual Booking Bar with Tentative Dashed border
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.sunsetBright.withValues(alpha: 0.1), AppColors.sunsetBright.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.sunsetBright.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, color: AppColors.sunsetBright, size: 28),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          '${_formatTime(_time)} — ${_calculateEndTime()}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.sunsetBright),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(DateFormat('EEEE, MMMM d, yyyy').format(_date), style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date / Time Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => _date = d);
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
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _time);
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

            // Duration Card
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
                        child: const Icon(Icons.timer, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Duration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDurationChip(60, '1 hour'),
                      _buildDurationChip(180, '3 hours'),
                      ChoiceChip(
                        label: const Text('Custom +', style: TextStyle(fontWeight: FontWeight.w600)),
                        selected: ![60, 180].contains(_duration),
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Multi-slot Generation Card
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
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: const Text('Generate Multiple Slots', style: TextStyle(fontWeight: FontWeight.w700)),
                    value: _multiSlot,
                    onChanged: (v) => setState(() => _multiSlot = v),
                    activeThumbColor: AppColors.sunsetBright,
                  ),
                  if (_multiSlot)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _frequency,
                                decoration: InputDecoration(
                                  labelText: 'Frequency',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: ['Daily', 'Working Days', 'Weekly', 'Fortnightly'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                onChanged: (v) => setState(() => _frequency = v!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: '$_count',
                              decoration: InputDecoration(
                                labelText: 'Count (1-50)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _count = int.tryParse(v) ?? 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Open to Card
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
                        child: const Icon(Icons.person_add, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Open to', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _OpenToOption(
                            label: 'All current pupils',
                            subtitle: 'Visible to active pupils',
                            selected: _groupFilter == 'current',
                            onTap: () => setState(() {
                              _groupFilter = 'current';
                              _selectedPupilIds.clear();
                            }),
                          ),
                        ),
                        Expanded(
                          child: _OpenToOption(
                            label: 'Specific pupils',
                            subtitle: 'Choose who can see it',
                            selected: _groupFilter == 'specific',
                            onTap: () => setState(() => _groupFilter = 'specific'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_groupFilter == 'current') ...[
                    const SizedBox(height: 12),
                    Text(
                      'This slot will be visible to all ${activePupils.length} active pupil${activePupils.length == 1 ? '' : 's'} linked to you.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                    ),
                  ],
                  if (_groupFilter == 'specific') ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: activePupils.isEmpty
                          ? null
                          : () => _openPupilPicker(activePupils),
                      icon: const Icon(Icons.group_add),
                      label: Text(
                        _selectedPupilIds.isEmpty
                            ? 'Select pupils'
                            : '${_selectedPupilIds.length} pupil${_selectedPupilIds.length == 1 ? '' : 's'} selected',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.sunsetBright),
                        foregroundColor: AppColors.sunsetBright,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (_selectedPupilIds.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedPupilIds.map((id) {
                          return Chip(
                            label: Text(pupilNameById[id] ?? 'Pupil'),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => setState(() => _selectedPupilIds.remove(id)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gearbox Card
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
            child: const Icon(
              Icons.settings,
              color: AppColors.sunsetBright,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Gearbox Filter',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonFormField<String>(
          initialValue: _gearboxFilter,
          decoration: const InputDecoration(
            labelText: 'Gearbox',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: ['Any', 'Manual', 'Automatic']
              .map(
                (val) => DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _gearboxFilter = v!),
        ),
      ),
    ],
  ),
),
const SizedBox(height: 24),

            // Options Card
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
                        child: const Icon(Icons.settings, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Options', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Custom notification message (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: const Text('Require payment', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Pupils must pay first to confirm booking', style: TextStyle(fontSize: 12)),
                      value: _requireOnlinePay,
                      onChanged: (v) => setState(() => _requireOnlinePay = v),
                      activeThumbColor: AppColors.sunsetBright,
                    ),
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
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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

class _OpenToOption extends StatelessWidget {
  const _OpenToOption({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.sunsetBright : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
