import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';

class EnquiryFormScreen extends ConsumerStatefulWidget {
  const EnquiryFormScreen({super.key});

  @override
  ConsumerState<EnquiryFormScreen> createState() => _EnquiryFormScreenState();
}

class _EnquiryFormScreenState extends ConsumerState<EnquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _postcode = TextEditingController();
  final _notes = TextEditingController();
  ExperienceLevel _experience = ExperienceLevel.beginner;
  GearboxType _gearbox = GearboxType.manual;
  bool _hasProvisional = false;
  int _priorHours = 0;
  bool _anyTime = false;
  final List<String> _availabilityDays = [];
  final _daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String _instructorName = '';
  String _instructorEmail = '';
  String _instructorPhone = '';

  @override
  void initState() {
    super.initState();
    _loadInstructorProfile();
    _loadCachedFormData();
  }

  Future<void> _loadInstructorProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, email, phone')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _instructorName = profile['full_name'] as String? ?? '';
          _instructorEmail = profile['email'] as String? ?? user.email ?? '';
          _instructorPhone = profile['phone'] as String? ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCachedFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedFirstName = prefs.getString('enquiry_first_name');
      if (cachedFirstName != null && cachedFirstName.isNotEmpty) {
        _firstName.text = cachedFirstName;
        _lastName.text = prefs.getString('enquiry_last_name') ?? '';
        _phone.text = prefs.getString('enquiry_phone') ?? '';
        _email.text = prefs.getString('enquiry_email') ?? '';
        _address.text = prefs.getString('enquiry_address') ?? '';
        _postcode.text = prefs.getString('enquiry_postcode') ?? '';
        _notes.text = prefs.getString('enquiry_notes') ?? '';
        final expStr = prefs.getString('enquiry_experience');
        if (expStr != null) {
          _experience = ExperienceLevel.values.firstWhere(
            (e) => e.name == expStr, orElse: () => ExperienceLevel.beginner);
        }
        final gearStr = prefs.getString('enquiry_gearbox');
        if (gearStr != null) {
          _gearbox = GearboxType.values.firstWhere(
            (g) => g.name == gearStr, orElse: () => GearboxType.manual);
        }
        _hasProvisional = prefs.getBool('enquiry_has_provisional') ?? false;
        _priorHours = prefs.getInt('enquiry_prior_hours') ?? 0;
        _anyTime = prefs.getBool('enquiry_any_time') ?? false;
        final daysStr = prefs.getString('enquiry_availability_days');
        if (daysStr != null && daysStr.isNotEmpty) {
          _availabilityDays.addAll(daysStr.split(','));
        }
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _cacheFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('enquiry_first_name', _firstName.text.trim());
      await prefs.setString('enquiry_last_name', _lastName.text.trim());
      await prefs.setString('enquiry_phone', _phone.text.trim());
      await prefs.setString('enquiry_email', _email.text.trim());
      await prefs.setString('enquiry_address', _address.text.trim());
      await prefs.setString('enquiry_postcode', _postcode.text.trim());
      await prefs.setString('enquiry_notes', _notes.text.trim());
      await prefs.setString('enquiry_experience', _experience.name);
      await prefs.setString('enquiry_gearbox', _gearbox.name);
      await prefs.setBool('enquiry_has_provisional', _hasProvisional);
      await prefs.setInt('enquiry_prior_hours', _priorHours);
      await prefs.setBool('enquiry_any_time', _anyTime);
      await prefs.setString('enquiry_availability_days', _availabilityDays.join(','));
    } catch (_) {}
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _postcode.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _mapExperienceLevel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner: return 'beginner';
      case ExperienceLevel.intermediate: return 'intermediate';
      case ExperienceLevel.advanced: return 'advanced';
    }
  }

  String _mapGearboxType(GearboxType gearbox) {
    switch (gearbox) {
      case GearboxType.manual: return 'manual';
      case GearboxType.automatic: return 'automatic';
      default: return 'manual';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_firstName.text.trim().isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('enquiries').insert({
        'instructor_id': user.id,
        'instructor_name': _instructorName,
        'instructor_email': _instructorEmail,
        'instructor_phone': _instructorPhone,
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'postcode': _postcode.text.trim().isEmpty ? null : _postcode.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'experience_level': _mapExperienceLevel(_experience),
        'gearbox_preference': _mapGearboxType(_gearbox),
        'has_provisional_license': _hasProvisional,
        'prior_practice_hours': _priorHours,
        'weekly_availability': _anyTime ? _daysOfWeek : _availabilityDays,
      });

      await _cacheFormData();

      if (mounted) {
        ref.invalidate(instructorEnquiriesProvider);
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Enquiry', style: TextStyle(fontWeight: FontWeight.w700)),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Managed by
            if (_instructorName.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sunsetBright.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sunsetBright.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.support_agent, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Managed by $_instructorName',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.sunsetBright)),
                          if (_instructorEmail.isNotEmpty)
                            Text(_instructorEmail, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          if (_instructorPhone.isNotEmpty)
                            Text(_instructorPhone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Personal Info Card
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
                          controller: _firstName,
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
                          controller: _lastName,
                          decoration: InputDecoration(
                            labelText: 'Last name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.all(16),
                          ),
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
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _address,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _postcode,
                          decoration: InputDecoration(
                            labelText: 'Postcode',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Driving Experience Card
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
                        child: const Icon(Icons.drive_eta, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Driving Experience', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<GearboxType>(
                      initialValue: _gearbox,
                      decoration: InputDecoration(
                        labelText: 'Transmission Preference',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: GearboxType.values
                          .map((g) => DropdownMenuItem(value: g, child: Text(labelEnum(g))))
                          .toList(),
                      onChanged: (v) => setState(() => _gearbox = v!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<ExperienceLevel>(
                      initialValue: _experience,
                      decoration: InputDecoration(
                        labelText: 'Experience Level',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: ExperienceLevel.values
                          .map((e) => DropdownMenuItem(value: e, child: Text(labelEnum(e))))
                          .toList(),
                      onChanged: (v) => setState(() => _experience = v!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('Prior Practice Hours: ', style: TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => setState(() { if (_priorHours > 0) _priorHours--; }),
                        ),
                        Text('$_priorHours', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _priorHours++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: const Text('Has Provisional Licence', style: TextStyle(fontWeight: FontWeight.w700)),
                      value: _hasProvisional,
                      onChanged: (v) => setState(() => _hasProvisional = v),
                      activeThumbColor: AppColors.sunsetBright,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Availability Card
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
                      const Text('Availability', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: const Text('Any Time', style: TextStyle(fontWeight: FontWeight.w700)),
                      value: _anyTime,
                      activeColor: AppColors.sunsetBright,
                      onChanged: (v) => setState(() {
                        _anyTime = v ?? false;
                        if (_anyTime) _availabilityDays.clear();
                      }),
                    ),
                  ),
                  if (!_anyTime) ...[
                    const SizedBox(height: 16),
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
}
