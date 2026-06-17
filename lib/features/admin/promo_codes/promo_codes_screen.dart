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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Text(
                        'Promo Codes',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
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
                // Promo codes list
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
    );
  }

  Widget _buildPromoCodeCard(Map<String, dynamic> promoCode) {
    final code = promoCode['code'] as String?;
    final discount = promoCode['discount_percent'] as num?;
    final maxUses = promoCode['max_uses'] as int?;
    final usedCount = promoCode['used_count'] as int?;
    final isActive = promoCode['is_active'] as bool? ?? false;
    final validUntil = promoCode['valid_until'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
                  style: TextStyle(
                    color: AppColors.sunset,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Spacer(),
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
        color: Colors.grey.shade50,
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
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreatePromoCodeDialog() {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final maxUsesController = TextEditingController();
    final validUntilController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                controller: validUntilController,
                decoration: const InputDecoration(
                  labelText: 'Valid Until (YYYY-MM-DD)',
                  hintText: 'Leave empty for no expiry',
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
            onPressed: () async {
              // Create promo code
              try {
                await Supabase.instance.client.from('promo_codes').insert({
                  'code': codeController.text.trim().toUpperCase(),
                  'discount_percent': int.tryParse(discountController.text) ?? 0,
                  'max_uses': maxUsesController.text.isEmpty ? null : int.tryParse(maxUsesController.text),
                  'valid_until': validUntilController.text.isEmpty ? null : validUntilController.text,
                  'is_active': true,
                  'used_count': 0,
                });
                if (mounted) {
                  Navigator.pop(context);
                  _loadPromoCodes();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating promo code: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditPromoCodeDialog(Map<String, dynamic> promoCode) {
    final codeController = TextEditingController(text: promoCode['code'] as String? ?? '');
    final discountController = TextEditingController(
      text: (promoCode['discount_percent'] as num?)?.toString() ?? '',
    );
    final maxUsesController = TextEditingController(
      text: (promoCode['max_uses'] as int?)?.toString() ?? '',
    );
    final validUntilController = TextEditingController(
      text: (promoCode['valid_until'] as String?)?.split('T').first ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                controller: validUntilController,
                decoration: const InputDecoration(
                  labelText: 'Valid Until (YYYY-MM-DD)',
                  hintText: 'Leave empty for no expiry',
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
            onPressed: () async {
              try {
                await Supabase.instance.client.from('promo_codes').update({
                  'code': codeController.text.trim().toUpperCase(),
                  'discount_percent': int.tryParse(discountController.text) ?? 0,
                  'max_uses': maxUsesController.text.isEmpty ? null : int.tryParse(maxUsesController.text),
                  'valid_until': validUntilController.text.isEmpty ? null : validUntilController.text,
                }).eq('id', promoCode['id']);
                if (mounted) {
                  Navigator.pop(context);
                  _loadPromoCodes();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating promo code: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
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
          SnackBar(content: Text(newActive ? 'Promo code activated' : 'Promo code deactivated')),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.from('promo_codes').delete().eq('id', promoCode['id']);
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
