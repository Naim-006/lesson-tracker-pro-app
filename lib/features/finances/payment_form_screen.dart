import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/error_handler.dart';
import 'income_category_picker_screen.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  Pupil? _pupil;
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  PaymentMethod _method = PaymentMethod.bankTransfer;
  PaymentType _paymentType = PaymentType.individual;
  DateTime _date = DateTime.now();
  String? _category;
  String? _receiptPath;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() => _receiptPath = image.path);
      }
    }
  }

  void _showNumericKeypad(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Amount'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(
              _amount.text.isEmpty ? '£0.00' : '£${_amount.text}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _KeypadButton('1', () => _updateAmount('1')),
                _KeypadButton('2', () => _updateAmount('2')),
                _KeypadButton('3', () => _updateAmount('3')),
                _KeypadButton('4', () => _updateAmount('4')),
                _KeypadButton('5', () => _updateAmount('5')),
                _KeypadButton('6', () => _updateAmount('6')),
                _KeypadButton('7', () => _updateAmount('7')),
                _KeypadButton('8', () => _updateAmount('8')),
                _KeypadButton('9', () => _updateAmount('9')),
                _KeypadButton('.', () => _updateAmount('.')),
                _KeypadButton('0', () => _updateAmount('0')),
                _KeypadButton('⌫', () => _backspace()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _updateAmount(String value) {
    setState(() {
      if (_amount.text.isEmpty && value == '.') {
        _amount.text = '0.';
      } else {
        _amount.text += value;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_amount.text.isNotEmpty) {
        _amount.text = _amount.text.substring(0, _amount.text.length - 1);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amt = double.tryParse(_amount.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('payments').insert({
        'instructor_id': user.id,
        'pupil_id': _pupil?.id,
        'amount': amt,
        'description': _paymentType == PaymentType.block
            ? 'Block payment — ${_pupil?.fullName ?? "General"}'
            : 'Payment — ${_pupil?.fullName ?? "General"}',
        'payment_method': _mapPaymentMethod(_method),
        'type': _mapPaymentType(_paymentType),
        'status': 'completed',
      });

      if (mounted) {
        ref.invalidate(instructorPaymentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment created')),
        );
        Logger.info('Payment created: $amt for ${_pupil?.fullName ?? "General"}');
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      Logger.error('Error saving payment', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  String _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return 'cash';
      case PaymentMethod.bankTransfer: return 'bank_transfer';
      case PaymentMethod.card: return 'card';
      case PaymentMethod.online: return 'online';
      default: return 'bank_transfer';
    }
  }

  String _mapPaymentType(PaymentType type) {
    switch (type) {
      case PaymentType.individual: return 'individual';
      case PaymentType.block: return 'block';
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructorPupils = ref.watch(instructorPupilsProvider);

    // Convert Supabase data to local Pupil models
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
        hourlyRate: 40.0,
      );
    }).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.w700)),
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
            // Pupil Selection Card
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownMenu<Pupil?>(
                width: MediaQuery.of(context).size.width - 40,
                label: const Text('Pupil (Optional)'),
                dropdownMenuEntries: [
                  const DropdownMenuEntry(value: null, label: 'General / No Pupil'),
                  ...pupils.map((p) => DropdownMenuEntry(value: p, label: p.fullName)),
                ],
                onSelected: (p) => setState(() => _pupil = p),
              ),
            ),
            const SizedBox(height: 20),
            
            // Receipt Card
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
                        child: const Icon(Icons.receipt, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Receipt', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_receiptPath != null)
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _receiptPath = null),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _pickReceipt,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add receipt'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.sunsetBright),
                        foregroundColor: AppColors.sunsetBright,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Card
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
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.currency_pound, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Payment Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _amount,
                      decoration: InputDecoration(
                        labelText: 'Amount (£)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      keyboardType: TextInputType.none,
                      readOnly: true,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                      onTap: () => _showNumericKeypad(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Payment Method Card
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
                      const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PaymentMethod.values.map((m) {
                      final isSelected = _method == m;
                      return ChoiceChip(
                        label: Text(labelEnum(m), style: const TextStyle(fontWeight: FontWeight.w600)),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _method = m),
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

            // Payment Details Card
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
                        child: const Icon(Icons.description, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<PaymentType>(
                      initialValue: _paymentType,
                      decoration: InputDecoration(
                        labelText: 'Payment type',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: PaymentType.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(labelEnum(t))))
                          .toList(),
                      onChanged: (v) => setState(() => _paymentType = v!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(_category ?? 'Select category'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final category = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const IncomeCategoryPickerScreen()),
                        );
                        if (category != null) {
                          setState(() => _category = category);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
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
                                Text('Date Received', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(DateFormat('dd/MM/yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                    maxLines: 3,
                  ),
                ],
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
                child: const Text('Save Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
