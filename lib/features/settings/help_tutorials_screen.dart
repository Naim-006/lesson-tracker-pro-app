import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

class HelpTutorialsScreen extends ConsumerStatefulWidget {
  const HelpTutorialsScreen({super.key});

  @override
  ConsumerState<HelpTutorialsScreen> createState() => _HelpTutorialsScreenState();
}

class _HelpTutorialsScreenState extends ConsumerState<HelpTutorialsScreen> {
  final List<TutorialItem> _tutorials = [
    TutorialItem(
      title: 'Getting Started',
      description: 'Learn the basics of Lesson Tracker Pro',
      icon: Icons.play_circle_outline,
      duration: '5 min',
    ),
    TutorialItem(
      title: 'Managing Pupils',
      description: 'Add and manage your pupil list',
      icon: Icons.people_outline,
      duration: '8 min',
    ),
    TutorialItem(
      title: 'Scheduling Lessons',
      description: 'Create and manage lesson schedules',
      icon: Icons.calendar_today,
      duration: '6 min',
    ),
    TutorialItem(
      title: 'Tracking Finances',
      description: 'Monitor income and expenses',
      icon: Icons.account_balance_wallet,
      duration: '7 min',
    ),
    TutorialItem(
      title: 'Test Reports',
      description: 'Generate and manage test reports',
      icon: Icons.assessment,
      duration: '4 min',
    ),
    TutorialItem(
      title: 'Progress Tracking',
      description: 'Track pupil progress with syllabus',
      icon: Icons.trending_up,
      duration: '9 min',
    ),
  ];

  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I add a new pupil?',
      answer: 'Go to the Pupils screen and tap "Add new pupil" in the footer. Fill in the pupil details and save.',
    ),
    FAQItem(
      question: 'Can I sync with my calendar?',
      answer: 'Yes! Go to Settings > Account and enable calendar sync. You can choose to sync with Google, Apple, or Outlook calendars.',
    ),
    FAQItem(
      question: 'How do I track mileage?',
      answer: 'Use the Quick Add FAB and select "Mileage". Enter your start and end mileage, and optionally add an expense.',
    ),
    FAQItem(
      question: 'Can I customize my rates?',
      answer: 'Yes! Go to Settings > Teaching > Pricing and Packages to set up your lesson rates and packages.',
    ),
  ];

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
        title: const Text('Help & Tutorials', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
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
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tutorials Section
          const Text(
            'Video Tutorials',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 16),
          ..._tutorials.map((tutorial) => _TutorialTile(tutorial: tutorial)),
          const SizedBox(height: 24),

          // FAQs Section
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 16),
          ..._faqs.map((faq) => _FAQTile(faq: faq)),
          const SizedBox(height: 24),

          // Contact Support
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sunsetBright, AppColors.sunsetBright.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Need more help?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact our support team',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening support chat...')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class TutorialItem {
  final String title;
  final String description;
  final IconData icon;
  final String duration;

  TutorialItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.duration,
  });
}

class _TutorialTile extends StatelessWidget {
  const _TutorialTile({required this.tutorial});
  final TutorialItem tutorial;

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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.sunsetBright.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(tutorial.icon, color: AppColors.sunsetBright, size: 28),
        ),
        title: Text(tutorial.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(tutorial.description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(tutorial.duration, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${tutorial.title}...')),
          );
        },
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}

class _FAQTile extends StatefulWidget {
  const _FAQTile({required this.faq});
  final FAQItem faq;

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _expanded = false;

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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(widget.faq.question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        onExpansionChanged: (v) => setState(() => _expanded = v),
        trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.sunsetBright),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(widget.faq.answer, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
