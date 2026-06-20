import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

class PupilResourcesScreen extends ConsumerStatefulWidget {
  const PupilResourcesScreen({super.key});

  @override
  ConsumerState<PupilResourcesScreen> createState() => _PupilResourcesScreenState();
}

class _PupilResourcesScreenState extends ConsumerState<PupilResourcesScreen> {
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
        title: const Text('Pupil Resources', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Collections Section
          const Text(
            'Collections',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          _ResourceCollectionTile(
            title: 'Lesson Plans',
            count: 12,
            icon: Icons.description,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View Lesson Plans collection')),
              );
            },
          ),
          const SizedBox(height: 8),
          _ResourceCollectionTile(
            title: 'Handouts',
            count: 8,
            icon: Icons.article,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View Handouts collection')),
              );
            },
          ),
          const SizedBox(height: 8),
          _ResourceCollectionTile(
            title: 'Videos',
            count: 5,
            icon: Icons.video_library,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View Videos collection')),
              );
            },
          ),
          const SizedBox(height: 8),
          _ResourceCollectionTile(
            title: 'Practice Tests',
            count: 3,
            icon: Icons.quiz,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View Practice Tests collection')),
              );
            },
          ),
          const SizedBox(height: 24),

          // Add Resource Button
          OutlinedButton.icon(
            onPressed: () => _showAddResourceDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add resource'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.sunsetBright),
              foregroundColor: AppColors.sunsetBright,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // Share with Pupils Section
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
                      child: const Icon(Icons.share, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Share with Pupils', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Resources you add here can be shared with your pupils. They will be able to view and download them from their pupil portal.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddResourceDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCollection = 'Lesson Plans';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Resource'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Resource Title'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedCollection,
              decoration: const InputDecoration(labelText: 'Collection'),
              items: const ['Lesson Plans', 'Handouts', 'Videos', 'Practice Tests']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => selectedCollection = v!,
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
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resource added')),
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

class _ResourceCollectionTile extends StatelessWidget {
  const _ResourceCollectionTile({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.sunsetBright.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.sunsetBright, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('$count items', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
