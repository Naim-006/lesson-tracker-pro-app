import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class PromoCodesScreen extends ConsumerStatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  ConsumerState<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends ConsumerState<PromoCodesScreen> {
  List<Map<String, dynamic>> _promoCodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromoCodes();
  }

  Future<void> _loadPromoCodes() async {
    try {
      final response = await Supabase.instance.client
          .from('promo_codes')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _promoCodes = response as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isExpired(Map<String, dynamic> promoCode) {
    final validUntil = promoCode['valid_until'] as String?;
    if (validUntil == null || validUntil.isEmpty) return false;
    try {
      final date = DateTime.parse(validUntil);
      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPromoCodes,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: Theme.of(context).colorScheme.surface,
                    child: Row(
                      children: [
                        Text(
                          'Promo Codes',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _showCreatePromoCodeDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Promo Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sunset,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _promoCodes.isEmpty
                        ? const Center(
                            child: Text('No promo codes found'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _promoCodes.length,
                            itemBuilder: (context, index) {
                              final promoCode = _promoCodes[index];
                              return _buildPromoCodeCard(promoCode);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPromoCodeCard(Map<String, dynamic> promoCode) {
    final code = promoCode['code'] as String?;
    final discount = promoCode['discount_percent'] as num?;
    final maxUses = promoCode['max_uses'] as int?;
    final usedCount = promoCode['used_count'] as int?;
    final isActive = promoCode['is_active'] as bool? ?? false;
    final validUntil = promoCode['valid_until'] as String?;
    final assignedUserId = promoCode['assigned_user_id'] as String?;
    final maxUsesPerUser = promoCode['max_uses_per_user'] as int?;
    final expired = _isExpired(promoCode);

    final cardColor = Theme.of(context).colorScheme.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.sunset.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code ?? 'N/A',
                  style: const TextStyle(
                    color: AppColors.sunset,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Spacer(),
              if (expired)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Expired',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Discount',
                  value: '${discount?.toString() ?? '0'}%',
                  icon: Icons.percent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  title: 'Uses',
                  value: '${usedCount ?? 0}/${maxUses ?? '∞'}',
                  icon: Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  title: 'Valid Until',
                  value: validUntil != null ? _formatDate(validUntil) : 'No expiry',
                  icon: Icons.calendar_today,
                ),
              ),
            ],
          ),
          if (assignedUserId != null && assignedUserId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppColors.info.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned to: $assignedUserId',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.info.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (maxUsesPerUser != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.repeat, size: 16, color: AppColors.warning.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Text(
                    'Max uses per user: $maxUsesPerUser',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.warning.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditPromoCodeDialog(promoCode),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _togglePromoCodeActive(promoCode),
                  icon: Icon(isActive ? Icons.block : Icons.check_circle),
                  label: Text(isActive ? 'Deactivate' : 'Activate'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deletePromoCode(promoCode),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime? initialDate,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    onPicked(picked);
  }

  void _showCreatePromoCodeDialog() {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final maxUsesController = TextEditingController();
    final maxUsesPerUserController = TextEditingController();
    final assignedUserController = TextEditingController();
    DateTime? selectedDate;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Promo Code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    hintText: 'e.g., SUMMER2024',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: discountController,
                  decoration: const InputDecoration(
                    labelText: 'Discount (%)',
                    hintText: 'e.g., 20',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxUsesController,
                  decoration: const InputDecoration(
                    labelText: 'Max Uses (optional)',
                    hintText: 'Leave empty for unlimited',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxUsesPerUserController,
                  decoration: const InputDecoration(
                    labelText: 'Max Uses Per User (optional)',
                    hintText: 'e.g., 3',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: assignedUserController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned User ID (optional)',
                    hintText: 'Leave empty for any user',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    await _pickDate(
                      context: context,
                      initialDate: selectedDate,
                      onPicked: (date) {
                        setDialogState(() {
                          selectedDate = date;
                        });
                      },
                    );
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Valid Until',
                      hintText: 'Tap to select date',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'No expiry',
                          style: TextStyle(
                            color: selectedDate != null
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey.shade600,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setDialogState(() {
                                    selectedDate = null;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today,
                                size: 18, color: Colors.grey.shade600),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                                        final validUntilStr = selectedDate?.toIso8601String().split('T').first;
                          final data = <String, dynamic>{
                            'code': codeController.text.trim().toUpperCase(),
                            'discount_percent':
                                int.tryParse(discountController.text) ?? 0,
                            'max_uses': maxUsesController.text.isEmpty
                                ? null
                                : int.tryParse(maxUsesController.text),
                            'max_uses_per_user': maxUsesPerUserController.text.isEmpty
                                ? null
                                : int.tryParse(maxUsesPerUserController.text),
                            'assigned_user_id': assignedUserController.text.isEmpty
                                ? null
                                : assignedUserController.text.trim(),
                            'valid_until': validUntilStr,
                            'is_active': true,
                            'used_count': 0,
                          };
                          final nav = Navigator.of(context);
                          await Supabase.instance.client
                              .from('promo_codes')
                              .insert(data);
                          nav.pop();
                          _loadPromoCodes();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error creating promo code: $e')),
                          );
                        }
                        if (mounted) {
                          setDialogState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPromoCodeDialog(Map<String, dynamic> promoCode) {
    final codeController =
        TextEditingController(text: promoCode['code'] as String? ?? '');
    final discountController = TextEditingController(
      text: (promoCode['discount_percent'] as num?)?.toString() ?? '',
    );
    final maxUsesController = TextEditingController(
      text: (promoCode['max_uses'] as int?)?.toString() ?? '',
    );
    final maxUsesPerUserController = TextEditingController(
      text: (promoCode['max_uses_per_user'] as int?)?.toString() ?? '',
    );
    final assignedUserController = TextEditingController(
      text: (promoCode['assigned_user_id'] as String?) ?? '',
    );

    DateTime? selectedDate;
    final validUntil = promoCode['valid_until'] as String?;
    if (validUntil != null && validUntil.isNotEmpty) {
      try {
        selectedDate = DateTime.parse(validUntil);
      } catch (_) {}
    }

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Promo Code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    hintText: 'e.g., SUMMER2024',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: discountController,
                  decoration: const InputDecoration(
                    labelText: 'Discount (%)',
                    hintText: 'e.g., 20',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxUsesController,
                  decoration: const InputDecoration(
                    labelText: 'Max Uses (optional)',
                    hintText: 'Leave empty for unlimited',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxUsesPerUserController,
                  decoration: const InputDecoration(
                    labelText: 'Max Uses Per User (optional)',
                    hintText: 'e.g., 3',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: assignedUserController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned User ID (optional)',
                    hintText: 'Leave empty for any user',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    await _pickDate(
                      context: context,
                      initialDate: selectedDate,
                      onPicked: (date) {
                        setDialogState(() {
                          selectedDate = date;
                        });
                      },
                    );
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Valid Until',
                      hintText: 'Tap to select date',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'No expiry',
                          style: TextStyle(
                            color: selectedDate != null
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey.shade600,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setDialogState(() {
                                    selectedDate = null;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today,
                                size: 18, color: Colors.grey.shade600),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        final validUntilStr = selectedDate?.toIso8601String().split('T').first;
                        final data = <String, dynamic>{
                          'code': codeController.text.trim().toUpperCase(),
                          'discount_percent':
                              int.tryParse(discountController.text) ?? 0,
                          'max_uses': maxUsesController.text.isEmpty
                              ? null
                              : int.tryParse(maxUsesController.text),
                          'max_uses_per_user':
                              maxUsesPerUserController.text.isEmpty
                                  ? null
                                  : int.tryParse(maxUsesPerUserController.text),
                          'assigned_user_id':
                              assignedUserController.text.isEmpty
                                  ? null
                                  : assignedUserController.text.trim(),
                          'valid_until': validUntilStr,
                        };
                        final nav = Navigator.of(context);
                        await Supabase.instance.client
                            .from('promo_codes')
                            .update(data)
                            .eq('id', promoCode['id']);
                        nav.pop();
                        _loadPromoCodes();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error updating promo code: $e')),
                          );
                        }
                        if (mounted) {
                          setDialogState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePromoCodeActive(Map<String, dynamic> promoCode) async {
    final newActive = !(promoCode['is_active'] as bool? ?? false);
    try {
      await Supabase.instance.client
          .from('promo_codes')
          .update({'is_active': newActive})
          .eq('id', promoCode['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  newActive ? 'Promo code activated' : 'Promo code deactivated')),
        );
        _loadPromoCodes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating promo code: $e')),
        );
      }
    }
  }

  Future<void> _deletePromoCode(Map<String, dynamic> promoCode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Promo Code'),
        content: Text('Are you sure you want to delete "${promoCode['code']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client
          .from('promo_codes')
          .delete()
          .eq('id', promoCode['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promo code deleted')),
        );
        _loadPromoCodes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting promo code: $e')),
        );
      }
    }
  }
}
