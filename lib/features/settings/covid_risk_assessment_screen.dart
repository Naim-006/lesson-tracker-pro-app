import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/theme/app_colors.dart';

class CovidRiskAssessmentScreen extends ConsumerStatefulWidget {
  const CovidRiskAssessmentScreen({super.key});

  @override
  ConsumerState<CovidRiskAssessmentScreen> createState() => _CovidRiskAssessmentScreenState();
}

class _CovidRiskAssessmentScreenState extends ConsumerState<CovidRiskAssessmentScreen> {
  final List<RiskItem> _riskItems = [
    RiskItem(
      title: 'Vehicle ventilation',
      description: 'Keep windows open for fresh air circulation',
      completed: true,
    ),
    RiskItem(
      title: 'Face coverings',
      description: 'Wear face coverings in enclosed spaces',
      completed: true,
    ),
    RiskItem(
      title: 'Hand sanitizer',
      description: 'Provide hand sanitizer for pupils',
      completed: false,
    ),
    RiskItem(
      title: 'Vehicle cleaning',
      description: 'Clean vehicle between lessons',
      completed: true,
    ),
    RiskItem(
      title: 'Health screening',
      description: 'Ask pupils about symptoms before lessons',
      completed: true,
    ),
    RiskItem(
      title: 'Social distancing',
      description: 'Maintain distance where possible',
      completed: false,
    ),
  ];
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
        title: const Text('COVID-19 Risk Assessment', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info Card
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
            child: Row(
              children: [
                Icon(Icons.warning, color: AppColors.sunsetBright, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Risk Assessment',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Risk Items
          const Text(
            'Safety Measures',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 16),
          ..._riskItems.map((item) => _RiskItemTile(
                item: item,
                onChanged: (completed) {
                  setState(() {
                    item.completed = completed;
                  });
                },
              )),
          const SizedBox(height: 24),

          // Additional Notes
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
                const Text(
                  'Additional Notes',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add any additional safety measures...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
              onPressed: () {
                final s = ref.read(settingsProvider);
                ref.read(settingsProvider.notifier).update(s.copyWith(
                  covidSafetyEnabled: true,
                  covidRiskData: {
                    'items': _riskItems.map((r) => {'title': r.title, 'description': r.description, 'completed': r.completed}).toList(),
                    'notes': _notesController.text,
                  },
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Risk assessment saved')),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Assessment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class RiskItem {
  String title;
  String description;
  bool completed;

  RiskItem({
    required this.title,
    required this.description,
    required this.completed,
  });
}

class _RiskItemTile extends StatelessWidget {
  const _RiskItemTile({required this.item, required this.onChanged});
  final RiskItem item;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(item.description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        value: item.completed,
        onChanged: onChanged,
        activeColor: AppColors.sunsetBright,
      ),
    );
  }
}
