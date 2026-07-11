import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class MultiStepPaymentScreen extends ConsumerStatefulWidget {
  const MultiStepPaymentScreen({super.key});

  @override
  ConsumerState<MultiStepPaymentScreen> createState() => _MultiStepPaymentScreenState();
}

class _MultiStepPaymentScreenState extends ConsumerState<MultiStepPaymentScreen> {
  int _currentStep = 0;
  PaymentType? _paymentType;
  Pupil? _selectedPupil;
  Lesson? _selectedLesson;
  bool _isPackage = false;
  double _customAmount = 0;
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _savePayment() async {
    final settings = ref.read(settingsProvider);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final amount = _isPackage 
        ? settings.hourlyRate * 10 * 0.90 // 10 lesson package with 10% discount
        : (_customAmount > 0 ? _customAmount : settings.hourlyRate);

    try {
      await Supabase.instance.client.from('transactions').insert({
        'instructor_id': user.id,
        'pupil_id': _selectedPupil?.id,
        'pupil_name': _selectedPupil?.fullName ?? 'General',
        'amount': amount,
        'description': _paymentType == PaymentType.block
            ? 'Block payment — ${_selectedPupil?.fullName ?? "General"}'
            : 'Payment — ${_selectedPupil?.fullName ?? "General"}',
        'payment_method': 'bank_transfer',
        'type': 'income',
        'payment_type': _paymentType == PaymentType.block ? 'block' : 'individual',
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });

      if (mounted) {
        ref.invalidate(instructorPaymentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment created')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
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
        title: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(4, (index) {
                final isActive = index <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.sunsetBright : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: _buildCurrentStep(),
          ),
          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.sunsetBright),
                        foregroundColor: AppColors.sunsetBright,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _currentStep == 3 ? _savePayment : _nextStep,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sunsetBright,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_currentStep == 3 ? 'Save Payment' : 'Next', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _PaymentTypeStep(
          selectedType: _paymentType,
          onTypeSelected: (type) => setState(() => _paymentType = type),
        );
      case 1:
        return _SelectPupilStep(
          selectedPupil: _selectedPupil,
          onPupilSelected: (pupil) => setState(() => _selectedPupil = pupil),
        );
      case 2:
        return _SelectLessonStep(
          selectedLesson: _selectedLesson,
          onLessonSelected: (lesson) => setState(() => _selectedLesson = lesson),
        );
      case 3:
        return _AmountStep(
          isPackage: _isPackage,
          customAmount: _customAmount,
          amountController: _amountController,
          onPackageToggle: (isPackage) => setState(() => _isPackage = isPackage),
          onAmountChanged: (amount) => setState(() => _customAmount = amount),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _PaymentTypeStep extends StatelessWidget {
  const _PaymentTypeStep({
    required this.selectedType,
    required this.onTypeSelected,
  });

  final PaymentType? selectedType;
  final Function(PaymentType) onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
          const SizedBox(height: 8),
          Text('What type of payment is this?', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          _PaymentTypeCard(
            icon: Icons.person,
            title: 'Individual Payment',
            description: 'One-off payment for a single lesson',
            type: PaymentType.individual,
            selectedType: selectedType,
            onTap: onTypeSelected,
          ),
          const SizedBox(height: 12),
          _PaymentTypeCard(
            icon: Icons.block,
            title: 'Block Payment',
            description: 'Payment for multiple lessons',
            type: PaymentType.block,
            selectedType: selectedType,
            onTap: onTypeSelected,
          ),
        ],
      ),
    );
  }
}

class _PaymentTypeCard extends StatelessWidget {
  const _PaymentTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.type,
    required this.selectedType,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final PaymentType type;
  final PaymentType? selectedType;
  final Function(PaymentType) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedType == type;
    return InkWell(
      onTap: () => onTap(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.sunsetBright : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.sunsetBright.withValues(alpha: 0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? AppColors.sunsetBright : Colors.grey, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.sunsetBright, size: 24),
          ],
        ),
      ),
    );
  }
}

class _SelectPupilStep extends ConsumerWidget {
  const _SelectPupilStep({
    required this.selectedPupil,
    required this.onPupilSelected,
  });

  final Pupil? selectedPupil;
  final Function(Pupil?) onPupilSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Pupil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
          const SizedBox(height: 8),
          Text('Who is making this payment?', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          _PupilCard(
            pupil: null,
            isSelected: selectedPupil == null,
            onTap: () => onPupilSelected(null),
          ),
          const SizedBox(height: 12),
          ...pupils.map((pupil) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PupilCard(
              pupil: pupil,
              isSelected: selectedPupil == pupil,
              onTap: () => onPupilSelected(pupil),
            ),
          )),
        ],
      ),
    );
  }
}

class _PupilCard extends StatelessWidget {
  const _PupilCard({
    required this.pupil,
    required this.isSelected,
    required this.onTap,
  });

  final Pupil? pupil;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.sunsetBright : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? AppColors.sunsetBright.withValues(alpha: 0.1) : Colors.grey.shade200,
              child: Text(
                pupil?.firstName.isNotEmpty == true ? pupil!.firstName[0] : '?',
                style: TextStyle(
                  color: isSelected ? AppColors.sunsetBright : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                pupil?.fullName ?? 'General / No Pupil',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.sunsetBright, size: 24),
          ],
        ),
      ),
    );
  }
}

class _SelectLessonStep extends ConsumerWidget {
  const _SelectLessonStep({
    required this.selectedLesson,
    required this.onLessonSelected,
  });

  final Lesson? selectedLesson;
  final Function(Lesson?) onLessonSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructorLessons = ref.watch(instructorLessonsProvider);

    // Convert Supabase data to local Lesson models
    final lessons = instructorLessons.value?.map((lessonData) {
      final pupil = lessonData['pupils'] ?? <String, dynamic>{};
      final String pupilName = '${pupil['first_name'] ?? ''} ${pupil['last_name'] ?? ''}'.trim();
      return Lesson(
        id: lessonData['id'],
        pupilId: pupil['id'] ?? '',
        pupilName: pupilName.isNotEmpty ? pupilName : 'Unknown',
        date: DateTime.parse(lessonData['date']),
        time: lessonData['start_time'] ?? '',
        duration: lessonData['duration'] ?? 60,
        rate: 40.0,
        status: lessonData['status'] == 'completed' ? LessonStatus.completed : LessonStatus.scheduled,
      );
    }).toList() ?? [];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Lesson', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
          const SizedBox(height: 8),
          Text('Which lesson is this payment for? (Optional)', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          _LessonCard(
            lesson: null,
            isSelected: selectedLesson == null,
            onTap: () => onLessonSelected(null),
          ),
          const SizedBox(height: 12),
          ...lessons.take(5).map((lesson) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LessonCard(
              lesson: lesson,
              isSelected: selectedLesson == lesson,
              onTap: () => onLessonSelected(lesson),
            ),
          )),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.isSelected,
    required this.onTap,
  });

  final Lesson? lesson;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.sunsetBright : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.sunsetBright.withValues(alpha: 0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event, color: isSelected ? AppColors.sunsetBright : Colors.grey, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson?.pupilName ?? 'No specific lesson',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  if (lesson != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      lesson!.time,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.sunsetBright, size: 24),
          ],
        ),
      ),
    );
  }
}

class _AmountStep extends StatelessWidget {
  const _AmountStep({
    required this.isPackage,
    required this.customAmount,
    required this.amountController,
    required this.onPackageToggle,
    required this.onAmountChanged,
  });

  final bool isPackage;
  final double customAmount;
  final TextEditingController amountController;
  final Function(bool) onPackageToggle;
  final Function(double) onAmountChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
          const SizedBox(height: 8),
          Text('How much is being paid?', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          
          // Package Option
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPackage ? AppColors.sunsetBright : Colors.grey.shade300,
                width: isPackage ? 2 : 1,
              ),
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
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isPackage ? AppColors.sunsetBright.withValues(alpha: 0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.card_giftcard, color: isPackage ? AppColors.sunsetBright : Colors.grey, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('10 Lesson Package', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('10% discount applied', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Switch(
                      value: isPackage,
                      onChanged: onPackageToggle,
                      activeThumbColor: AppColors.sunsetBright,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Custom Amount
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
                const Text('Custom Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount (£)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => onAmountChanged(double.tryParse(v) ?? 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
