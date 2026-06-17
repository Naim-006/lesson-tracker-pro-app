import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/theme/app_colors.dart';

class LessonLengthsScreen extends ConsumerStatefulWidget {
  const LessonLengthsScreen({super.key});

  @override
  ConsumerState<LessonLengthsScreen> createState() => _LessonLengthsScreenState();
}

class _LessonLengthsScreenState extends ConsumerState<LessonLengthsScreen> {
  final List<int> _customLengths = [];

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
        title: const Text('Lesson Lengths', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Default Duration Card
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
                      child: const Icon(Icons.schedule, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Default Duration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: settings.defaultLessonDuration,
                    decoration: InputDecoration(
                      labelText: 'Default lesson length',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [30, 45, 60, 90, 120]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m minutes')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(settingsProvider.notifier).update(settings.copyWith(defaultLessonDuration: v));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Default duration updated')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Available Lengths Section
          const Text(
            'Available Lesson Lengths',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...([30, 45, 60, 90, 120].map((mins) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LengthTile(
              title: '$mins minutes',
              enabled: settings.lessonLengths.contains(mins),
              onTap: () {
                final lengths = List<int>.from(settings.lessonLengths);
                if (lengths.contains(mins)) {
                  lengths.remove(mins);
                } else {
                  lengths.add(mins);
                }
                lengths.sort();
                ref.read(settingsProvider.notifier).update(settings.copyWith(lessonLengths: lengths));
              },
            ),
          ))),
          const SizedBox(height: 24),

          // Add Custom Length Button
          OutlinedButton.icon(
            onPressed: () => _showAddLengthDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add custom length'),
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

  void _showAddLengthDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Length'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Duration (minutes)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                final s = ref.read(settingsProvider);
                final lengths = List<int>.from(s.lessonLengths);
                if (!lengths.contains(minutes)) {
                  lengths.add(minutes);
                  lengths.sort();
                  ref.read(settingsProvider.notifier).update(s.copyWith(lessonLengths: lengths));
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$minutes minute length added')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _LengthTile extends StatelessWidget {
  const _LengthTile({
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final bool enabled;
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
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Switch(
                value: enabled,
                onChanged: (_) => onTap(),
                activeColor: AppColors.sunsetBright,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
