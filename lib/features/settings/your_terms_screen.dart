import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_state_provider.dart';
import '../../core/theme/app_colors.dart';

class YourTermsScreen extends ConsumerStatefulWidget {
  const YourTermsScreen({super.key});

  @override
  ConsumerState<YourTermsScreen> createState() => _YourTermsScreenState();
}

class _YourTermsScreenState extends ConsumerState<YourTermsScreen> {
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
        title: const Text('Your Terms', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cancellation Period Card
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
                      child: const Icon(Icons.event_busy, color: AppColors.sunsetBright, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Cancellation Period', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: settings.cancellationPeriod,
                    decoration: InputDecoration(
                      labelText: 'Minimum notice required',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [12, 24, 48, 72]
                        .map((h) => DropdownMenuItem(value: h, child: Text('$h hours')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(settingsProvider.notifier).update(settings.copyWith(cancellationPeriod: v));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cancellation period updated')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Terms Document Card
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
                    const Text('Terms Document', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Terms & conditions text',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 6,
                    controller: TextEditingController(text: settings.termsAndConditions ?? ''),
                    onChanged: (v) {
                      ref.read(settingsProvider.notifier).update(settings.copyWith(termsAndConditions: v));
                    },
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showUploadDialog(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload PDF document'),
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

          // View Terms Button
          FilledButton.icon(
            onPressed: () {
              if (settings.termsAndConditions != null && settings.termsAndConditions!.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Terms & Conditions'),
                    content: SingleChildScrollView(
                      child: Text(settings.termsAndConditions!),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No terms to display')),
                );
              }
            },
            icon: const Icon(Icons.visibility),
            label: const Text('View current terms'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sunsetBright,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select a PDF file to upload'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document uploaded successfully')),
              );
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }
}
