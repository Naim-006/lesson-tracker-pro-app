import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/error_handler.dart';

class PupilFormScreen extends ConsumerStatefulWidget {
  const PupilFormScreen({super.key, this.existing});

  final Pupil? existing;

  @override
  ConsumerState<PupilFormScreen> createState() => _PupilFormScreenState();
}

class _PupilFormScreenState extends ConsumerState<PupilFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _postcode;
  late final TextEditingController _pickupAddress;
  late final TextEditingController _dropoffAddress;
  late final TextEditingController _notes;
  late final TextEditingController _rate;
  GearboxType _gearbox = GearboxType.manual;

  bool _showLocations = false;
  final List<String> _availabilityDays = [];

  final _daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _first = TextEditingController(text: e?.firstName ?? '');
    _last = TextEditingController(text: e?.lastName ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _postcode = TextEditingController(text: e?.postcode ?? '');
    _pickupAddress = TextEditingController(text: e?.pickupAddresses.isNotEmpty == true ? e!.pickupAddresses.first : '');
    _dropoffAddress = TextEditingController(text: e?.dropoffAddresses.isNotEmpty == true ? e!.dropoffAddresses.first : '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _rate = TextEditingController(
      text: (e?.hourlyRate ?? 40).toStringAsFixed(0),
    );
    if (e != null) {
      _gearbox = e.mechanicalGearboxPreference;
      _availabilityDays.addAll(e.weeklyAvailabilityDays);
      if (_pickupAddress.text.isNotEmpty || _dropoffAddress.text.isNotEmpty) {
        _showLocations = true;
      }
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _email.dispose();
    _postcode.dispose();
    _pickupAddress.dispose();
    _dropoffAddress.dispose();
    _notes.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (widget.existing == null) {
        // Check for duplicate email before creating
        final email = _email.text.trim();
        if (email.isNotEmpty) {
          final dupPupil = await Supabase.instance.client
              .from('pupils')
              .select('id')
              .eq('instructor_id', user.id)
              .eq('email', email)
              .maybeSingle();
          if (dupPupil != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('A pupil with this email already exists in your list')),
              );
            }
            return;
          }
        }
      }

      if (widget.existing != null) {
        // Update existing pupil — use correct schema column names
        await Supabase.instance.client.from('pupils').update({
          'first_name': _first.text.trim(),
          'last_name': _last.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'postcode': _postcode.text.trim().isEmpty ? null : _postcode.text.trim(),
          'pickup_addresses': _pickupAddress.text.trim().isEmpty ? [] : [_pickupAddress.text.trim()],
          'dropoff_addresses': _dropoffAddress.text.trim().isEmpty ? [] : [_dropoffAddress.text.trim()],
          'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          'weekly_availability_days': _availabilityDays,
          'mechanical_gearbox_preference': _gearbox.name,
          'hourly_rate': double.tryParse(_rate.text) ?? 40.0,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.existing!.id);

        Logger.info('Pupil updated: ${_first.text.trim()} ${_last.text.trim()}');
      } else {
        // Create new pupil — insert directly into pupils table
        // Pupils added manually by instructor are offline pupils without an auth account
        final insertResult = await Supabase.instance.client.from('pupils').insert({
          'instructor_id': user.id,
          'first_name': _first.text.trim(),
          'last_name': _last.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'postcode': _postcode.text.trim().isEmpty ? null : _postcode.text.trim(),
          'pickup_addresses': _pickupAddress.text.trim().isEmpty ? [] : [_pickupAddress.text.trim()],
          'dropoff_addresses': _dropoffAddress.text.trim().isEmpty ? [] : [_dropoffAddress.text.trim()],
          'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          'weekly_availability_days': _availabilityDays,
          'mechanical_gearbox_preference': _gearbox.name,
          'hourly_rate': double.tryParse(_rate.text) ?? 40.0,
          'status': 'current',
        }).select('id').single();

        Logger.info('Pupil created: ${_first.text.trim()} ${_last.text.trim()}');

        // Create the instructor-pupil link
        await Supabase.instance.client.from('instructor_pupil_links').insert({
          'instructor_id': user.id,
          'pupil_id': insertResult['id'],
          'status': 'active',
        });

        // Create a pending invitation so the pupil can sign up later
        final emailStr = _email.text.trim().toLowerCase();
        if (emailStr.isNotEmpty) {
          final existingInv = await Supabase.instance.client
              .from('pupil_invitations')
              .select('id')
              .eq('email', emailStr)
              .eq('instructor_id', user.id)
              .maybeSingle();
          if (existingInv == null) {
            await Supabase.instance.client.from('pupil_invitations').insert({
              'instructor_id': user.id,
              'email': emailStr,
              'first_name': _first.text.trim(),
              'last_name': _last.text.trim(),
              'phone': _phone.text.trim(),
              'status': 'pending',
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      if (mounted) {
        ref.invalidate(instructorPupilsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existing == null ? 'Pupil added successfully' : 'Pupil updated successfully')),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('Error saving pupil', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }


  void _toggleDay(String day) {
    setState(() {
      if (_availabilityDays.contains(day)) {
        _availabilityDays.remove(day);
      } else {
        _availabilityDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existing == null ? 'New pupil' : 'Edit pupil',
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
            // Personal Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
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
                        child: const Icon(Icons.person, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _first,
                          decoration: InputDecoration(
                            labelText: 'First name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _last,
                          decoration: InputDecoration(
                            labelText: 'Last name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final trimmed = v.trim();
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _postcode,
                    decoration: InputDecoration(
                      labelText: 'Postcode',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Locations Card
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text('Locations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  subtitle: const Text('Pickup & Dropoff overrides', style: TextStyle(fontSize: 13)),
                  initiallyExpanded: _showLocations,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _pickupAddress,
                            decoration: InputDecoration(
                              labelText: 'Pickup Location',
                              prefixIcon: const Icon(Icons.flight_takeoff),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dropoffAddress,
                            decoration: InputDecoration(
                              labelText: 'Dropoff Location',
                              prefixIcon: const Icon(Icons.flight_land),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rate & Gearbox Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
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
                        child: const Icon(Icons.payments, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Rate & Gearbox', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rate,
                          decoration: InputDecoration(
                            labelText: 'Hourly rate (£)',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<GearboxType>(
                            initialValue: _gearbox,
                            decoration: InputDecoration(
                              labelText: 'Gearbox',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: GearboxType.values
                                .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(labelEnum(g)),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _gearbox = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Availability Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
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
                      const Text('Weekly Availability', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _daysOfWeek.map((day) {
                      final isSelected = _availabilityDays.contains(day);
                      return ChoiceChip(
                        label: Text(day, style: const TextStyle(fontWeight: FontWeight.w600)),
                        selected: isSelected,
                        onSelected: (_) => _toggleDay(day),
                        selectedColor: AppColors.sunsetBright,
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
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
}
