import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_state_provider.dart';
import '../../core/theme/app_colors.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  final List<PaymentMethodConfig> _paymentMethods = [
    PaymentMethodConfig(
      id: 'bank_transfer',
      name: 'Bank Transfer',
      icon: Icons.account_balance,
      enabled: true,
      details: 'Sort Code: 12-34-56\nAccount: 12345678',
    ),
    PaymentMethodConfig(
      id: 'cash',
      name: 'Cash',
      icon: Icons.payments_outlined,
      enabled: true,
      details: 'Accepted on the day of the lesson',
    ),
    PaymentMethodConfig(
      id: 'card',
      name: 'Card Payment',
      icon: Icons.credit_card,
      enabled: true,
      details: 'Via Lesson Tracker Pro Payments (1.9% fee)',
    ),
    PaymentMethodConfig(
      id: 'paypal',
      name: 'PayPal',
      icon: Icons.payment,
      enabled: false,
      details: 'Send payments to instructor@email.com',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMethodDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.sunsetBright),
                      const SizedBox(width: 8),
                      const Text(
                        'Payment Configuration',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Configure which payment methods you accept from pupils. Enabled methods will appear as options when requesting payments.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) => _PaymentMethodCard(
            method: method,
            onToggle: (enabled) {
              setState(() {
                method.enabled = enabled;
              });
              _saveToSettings();
            },
            onEdit: () => _showEditMethodDialog(context, method),
            onDelete: () => _deleteMethod(method.id),
          )),
        ],
      ),
    );
  }

  void _showAddMethodDialog(BuildContext context) {
    final nameController = TextEditingController();
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Method Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Details'),
              maxLines: 3,
            ),
          ],
        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _paymentMethods.add(PaymentMethodConfig(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    icon: Icons.payment,
                    enabled: true,
                    details: detailsController.text,
                  ));
                });
                _saveToSettings();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditMethodDialog(BuildContext context, PaymentMethodConfig method) {
    final detailsController = TextEditingController(text: method.details);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${method.name}'),
        content: TextField(
          controller: detailsController,
          decoration: const InputDecoration(labelText: 'Details'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                method.details = detailsController.text;
              });
              _saveToSettings();
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMethod(String id) {
    setState(() {
      _paymentMethods.removeWhere((m) => m.id == id);
    });
    _saveToSettings();
  }

  void _saveToSettings() {
    final s = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).update(s.copyWith(
      paymentMethods: _paymentMethods.map((m) => {
        'id': m.id, 'name': m.name, 'enabled': m.enabled, 'details': m.details,
      }).toList(),
    ));
  }
}

class PaymentMethodConfig {
  String id;
  String name;
  IconData icon;
  bool enabled;
  String details;

  PaymentMethodConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.enabled,
    required this.details,
  });
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final PaymentMethodConfig method;
  final void Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: method.enabled
                        ? AppColors.sunsetBright.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    method.icon,
                    color: method.enabled ? AppColors.sunsetBright : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: method.enabled ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      Text(
                        method.details,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: method.enabled,
                  onChanged: onToggle,
                  activeThumbColor: AppColors.sunsetBright,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
