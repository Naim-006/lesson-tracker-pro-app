import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';

class RequestPaymentFormScreen extends ConsumerStatefulWidget {
  const RequestPaymentFormScreen({super.key});

  @override
  ConsumerState<RequestPaymentFormScreen> createState() => _RequestPaymentFormScreenState();
}

class _RequestPaymentFormScreenState extends ConsumerState<RequestPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Pupil? _pupil;
  bool _isPackage = false;
  
  double _amount = 0.0;
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pupil == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a pupil to request payment from.')));
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('instructor_payment_requests').insert({
        'instructor_id': user.id,
        'pupil_id': _pupil!.id,
        'amount': _amount,
        'description': _messageController.text.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment request of £${_amount.toStringAsFixed(2)} sent to ${_pupil!.firstName}.')),
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

  void _updateAmount() {
    setState(() {
      _amount = double.tryParse(_amountController.text) ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final instructorPupils = ref.watch(instructorPupilsProvider);
    
    // Convert Supabase pupil data to local Pupil model
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
        status: PupilStatus.current,
        outstandingBalance: 0.0,
      );
    }).toList() ?? [];
    
    final platformFee = _amount * 0.019;
    final takeHome = _amount - platformFee;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Request Payment', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.sunsetBright,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _send,
              child: const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Pupil Selection Card
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownMenu<Pupil>(
                width: MediaQuery.of(context).size.width - 40,
                label: const Text('Select Pupil'),
                dropdownMenuEntries: pupils.map((p) => DropdownMenuEntry(value: p, label: p.fullName)).toList(),
                onSelected: (p) => setState(() => _pupil = p),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Type Card
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
                        child: const Icon(Icons.payment, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Payment Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Custom Amount')),
                      ButtonSegment(value: true, label: Text('Lesson Package')),
                    ],
                    selected: {_isPackage},
                    onSelectionChanged: (s) => setState(() => _isPackage = s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.sunsetBright.withValues(alpha: 0.1),
                      selectedForegroundColor: AppColors.sunsetBright,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isPackage)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Package (Hours)',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: [2, 5, 10, 20].map((h) => DropdownMenuItem(value: h, child: Text('$h hours package'))).toList(),
                        onChanged: (h) {
                          if (h != null && _pupil != null) {
                            _amountController.text = (h * _pupil!.hourlyRate).toStringAsFixed(2);
                            _updateAmount();
                          } else if (h != null) {
                            _amountController.text = (h * 40).toStringAsFixed(2);
                            _updateAmount();
                          }
                        },
                      ),
                    ),
                  if (!_isPackage)
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (£)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: const Icon(Icons.currency_pound),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _updateAmount(),
                      validator: (v) => v == null || v.isEmpty ? 'Amount is required' : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Message Card
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
                        child: const Icon(Icons.message, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Message to pupil (optional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
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

            // Platform Fee Disclosure Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.sunsetBright.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.2)),
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
                        child: const Icon(Icons.info_outline, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Fee Disclosure', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A platform charge of 1.9% will be applied.\nFrom this £${_amount.toStringAsFixed(2)} payment, you keep £${takeHome.toStringAsFixed(2)}.',
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {},
                    child: const Text('Learn about Lesson Tracker Pro Payments', style: TextStyle(color: AppColors.sunsetBright, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Send Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _send,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Send Payment Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
