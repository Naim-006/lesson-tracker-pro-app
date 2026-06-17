import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _query = '';

  static const _articles = [
    (
      'Getting started',
      'Welcome to Lesson Tracker Pro. Use the + button to add pupils, lessons, and payments. Your data is saved on this device.',
    ),
    (
      'Managing pupils',
      'Go to Pupils to add students with rates, gearbox type, and status (Current, Waiting, Passed). Tap a pupil for lesson history.',
    ),
    (
      'Scheduling lessons',
      'Use Diary for day/week views. Book lessons with pickup/drop-off, duration chips, and recurrence. Open slots show availability.',
    ),
    (
      'Recording payments',
      'Finances tracks income and expenses. Use Quick Add → Payment or mark lessons paid from the lesson detail sheet.',
    ),
    (
      'Test reports',
      'Document practical test results from the drawer → Test Reports. Track manoeuvres, result, and notes per pupil.',
    ),
    (
      'Enquiry management',
      'Track prospective pupils in Enquiry Manager. Update status from New to Converted when they become a pupil.',
    ),
    (
      'Open slots',
      'Publish availability with recurring options and optional online payment flag (integrate Stripe for production).',
    ),
    (
      'Expense tracking',
      'Log fuel, maintenance, and other categories. Attach receipts when cloud storage is connected.',
    ),
    (
      'Exporting data',
      'Export CSV from Finances for your accountant. Select fiscal year dates before sharing.',
    ),
    (
      'Settings',
      'Configure currency, reminders, timezone, and your instructor profile in Settings.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _articles.where((a) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return a.$1.toLowerCase().contains(q) || a.$2.toLowerCase().contains(q);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Tutorials')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search help…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ...filtered.map(
                  (a) => ExpansionTile(
                    title: Text(a.$1),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(a.$2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.mail, color: AppColors.sunsetBright),
                  title: const Text('Contact support'),
                  subtitle: const Text('support@lessontrackerpro.app'),
                  onTap: () => launchUrl(
                    Uri.parse('mailto:support@lessontrackerpro.app'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
