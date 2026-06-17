import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/theme/app_colors.dart';

class PricingPackagesScreen extends ConsumerStatefulWidget {
  const PricingPackagesScreen({super.key});

  @override
  ConsumerState<PricingPackagesScreen> createState() => _PricingPackagesScreenState();
}

class _PricingPackagesScreenState extends ConsumerState<PricingPackagesScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pricing & Packages', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hourly Rate Card
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
                      child: const Icon(Icons.attach_money, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Hourly Rate', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: const Text('Standard rate', style: TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Text(
                      '${settings.currencySymbol}${settings.hourlyRate.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.sunsetBright),
                    ),
                    onTap: () => _showRateDialog(context, settings, ref, 'Standard rate', settings.hourlyRate),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Packages Section
          const Text(
            'Lesson Packages',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          _PackageTile(
            title: '5 Lesson Package',
            price: settings.hourlyRate * 5 * 0.95,
            discount: '5% off',
            currency: settings.currencySymbol,
            onTap: () => _showPackageDialog(context, settings, ref, '5 Lesson Package', 5, 0.95),
          ),
          const SizedBox(height: 8),
          _PackageTile(
            title: '10 Lesson Package',
            price: settings.hourlyRate * 10 * 0.90,
            discount: '10% off',
            currency: settings.currencySymbol,
            onTap: () => _showPackageDialog(context, settings, ref, '10 Lesson Package', 10, 0.90),
          ),
          const SizedBox(height: 8),
          _PackageTile(
            title: '20 Lesson Package',
            price: settings.hourlyRate * 20 * 0.85,
            discount: '15% off',
            currency: settings.currencySymbol,
            onTap: () => _showPackageDialog(context, settings, ref, '20 Lesson Package', 20, 0.85),
          ),
          const SizedBox(height: 24),

          // Add Package Button
          OutlinedButton.icon(
            onPressed: () => _showAddPackageDialog(context, settings),
            icon: const Icon(Icons.add),
            label: const Text('Add custom package'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.sunsetBright),
              foregroundColor: AppColors.sunsetBright,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPackageDialog(BuildContext context, AppSettings settings) {
    final titleController = TextEditingController();
    final lessonsController = TextEditingController(text: '5');
    final discountController = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Package'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Package Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lessonsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Lessons'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discount (%)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty && lessonsController.text.isNotEmpty) {
                    final s = ref.read(settingsProvider);
                    final packages = List<Map<String, dynamic>>.from(s.customPackages);
                    packages.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleController.text,
                      'lessons': int.tryParse(lessonsController.text) ?? 5,
                      'discount': double.tryParse(discountController.text) ?? 5,
                    });
                    ref.read(settingsProvider.notifier).update(s.copyWith(customPackages: packages));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Custom package added')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context, AppSettings settings, WidgetRef ref, String title, double currentRate) {
    final controller = TextEditingController(text: currentRate.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Rate (${settings.currencySymbol})',
            prefixIcon: const Icon(Icons.attach_money),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final rate = double.tryParse(controller.text) ?? currentRate;
              ref.read(settingsProvider.notifier).update(settings.copyWith(hourlyRate: rate));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rate updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPackageDialog(BuildContext context, AppSettings settings, WidgetRef ref, String title, int lessons, double discount) {
    final price = settings.hourlyRate * lessons * discount;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lessons: $lessons'),
            const SizedBox(height: 8),
            Text('Discount: ${((1 - discount) * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 8),
            Text('Total: ${settings.currencySymbol}${price.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.title,
    required this.price,
    required this.discount,
    required this.currency,
    required this.onTap,
  });

  final String title;
  final double price;
  final String discount;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(discount, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Text(
                '$currency${price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.sunsetBright),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
