import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_state_provider.dart';
import '../../core/theme/app_colors.dart';

class ProgressSyllabusScreen extends ConsumerStatefulWidget {
  const ProgressSyllabusScreen({super.key});

  @override
  ConsumerState<ProgressSyllabusScreen> createState() => _ProgressSyllabusScreenState();
}

class _ProgressSyllabusScreenState extends ConsumerState<ProgressSyllabusScreen> {
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _categories = settings.skillCategories.isNotEmpty 
        ? settings.skillCategories 
        : ['Controls', 'Manoeuvres', 'Junctions', 'Road Positioning', 'Planning & Observation'];
  }

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
        title: const Text('Progress Syllabus', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress Tracking Toggle
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
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable progress tracking', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Track pupil skill development'),
              value: settings.progressTrackingEnabled,
              onChanged: (v) {
                ref.read(settingsProvider.notifier).update(settings.copyWith(progressTrackingEnabled: v));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress tracking updated')),
                );
              },
              activeThumbColor: AppColors.sunsetBright,
            ),
          ),
          const SizedBox(height: 24),

          // Scoring Section
          const Text(
            'Scoring',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Container(
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
              children: [
                ListTile(
                  title: const Text('Progress scale', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Number of scoring levels'),
                  trailing: DropdownButton<int>(
                    value: settings.defaultProgressScale,
                    items: const [1, 3, 5, 10]
                        .map((s) => DropdownMenuItem(value: s, child: Text('1 - $s')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(settingsProvider.notifier).update(settings.copyWith(defaultProgressScale: v));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Progress scale updated')),
                        );
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Scoring system', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('How to calculate overall progress'),
                  trailing: DropdownButton<String>(
                    value: settings.scoringSystem,
                    items: const ['Average', 'Weighted', 'Minimum']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(settingsProvider.notifier).update(settings.copyWith(scoringSystem: v));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Scoring system updated')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Categories Section
          const Text(
            'Skill Categories',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ..._categories.map((category) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CategoryTile(
                  title: category,
                  description: 'Custom category',
                  onTap: () => _showEditCategoryDialog(context, category),
                  onDelete: () => _deleteCategory(category),
                ),
              )),
          const SizedBox(height: 24),

          // Add Category Button
          OutlinedButton.icon(
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add custom category'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.sunsetBright),
              foregroundColor: AppColors.sunsetBright,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // Reorder Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Drag and drop categories to reorder them in pupil progress reports',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Category Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  _categories.add(titleController.text.trim());
                });
                ref.read(settingsProvider.notifier).update(
                  ref.read(settingsProvider).copyWith(skillCategories: _categories),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category added')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, String oldCategory) {
    final titleController = TextEditingController(text: oldCategory);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Category Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  final index = _categories.indexOf(oldCategory);
                  if (index != -1) {
                    _categories[index] = titleController.text.trim();
                  }
                });
                ref.read(settingsProvider.notifier).update(
                  ref.read(settingsProvider).copyWith(skillCategories: _categories),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String category) {
    setState(() {
      _categories.remove(category);
    });
    ref.read(settingsProvider.notifier).update(
      ref.read(settingsProvider).copyWith(skillCategories: _categories),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category deleted')),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.description,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String description;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
              const Icon(Icons.drag_handle, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: onDelete,
                tooltip: 'Delete category',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
