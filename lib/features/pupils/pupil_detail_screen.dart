import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/error_handler.dart';
import 'progress_matrix_screen.dart';
import 'pupil_form_screen.dart';

class PupilDetailScreen extends ConsumerStatefulWidget {
  const PupilDetailScreen({super.key, required this.pupil});

  final Pupil pupil;

  @override
  ConsumerState<PupilDetailScreen> createState() => _PupilDetailScreenState();
}

class _PupilDetailScreenState extends ConsumerState<PupilDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final u = Uri.parse(urlString);
      if (await canLaunchUrl(u)) {
        await launchUrl(u);
        Logger.info('Launched URL: $urlString');
      } else {
        Logger.warning('Could not launch URL: $urlString');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch: $urlString')),
          );
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Error launching URL: $urlString', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructorPupils = ref.watch(instructorPupilsProvider);
    final instructorLessons = ref.watch(instructorLessonsProvider);

    // Convert Supabase data to local Pupil model
    final pupilData = instructorPupils.value?.firstWhere(
      (link) => link['pupils']?['id'] == widget.pupil.id,
      orElse: () => <String, dynamic>{},
    );
    
    final pupil = pupilData != null && pupilData.isNotEmpty ? Pupil(
      id: pupilData['pupils']?['id'] ?? widget.pupil.id,
      firstName: pupilData['pupils']?['profiles']?['full_name']?.split(' ').first ?? widget.pupil.firstName,
      lastName: pupilData['pupils']?['profiles']?['full_name']?.split(' ').last ?? widget.pupil.lastName,
      phone: pupilData['pupils']?['profiles']?['phone'] ?? widget.pupil.phone,
      email: pupilData['pupils']?['profiles']?['email'] ?? widget.pupil.email,
      postcode: pupilData['pupils']?['postcode'],
      pickupAddresses: pupilData['pupils']?['address'] != null ? [pupilData['pupils']!['address']] : widget.pupil.pickupAddresses,
      hourlyRate: 40.0, // Default rate
      notes: pupilData['pupils']?['notes'],
    ) : widget.pupil;

    // Convert Supabase lessons to local Lesson models
    final lessons = instructorLessons.value?.where((l) => l['pupil_id'] == pupil.id).map((lesson) {
      final pupilData = lesson['pupils'];
      final profile = pupilData?['profiles'];
      return Lesson(
        pupilId: lesson['pupil_id'],
        pupilName: profile?['full_name'] ?? 'Unknown',
        date: DateTime.parse(lesson['date']),
        time: lesson['time'],
        duration: lesson['duration'] ?? 60,
        rate: lesson['rate'] ?? 40.0,
        pickupLocation: lesson['pickup_location'] ?? '',
        status: _mapLessonStatus(lesson['status']),
        notes: lesson['notes'] ?? '',
      );
    }).toList() ?? [];
    
    lessons.sort((a, b) => b.date.compareTo(a.date));
    
    final upcomingLessons = lessons.where((l) => l.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
    final pastLessons = lessons.where((l) => l.date.isBefore(DateTime.now())).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sunsetBright, AppColors.sunsetBright.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PupilFormScreen(existing: pupil),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  pupil.initials,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.sunsetBright,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pupil.fullName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '£${pupil.hourlyRate.toStringAsFixed(0)}/hr',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatBlock(title: 'LESSONS', value: '${lessons.length}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBlock(title: 'EARNED', value: '£${lessons.fold<double>(0, (sum, l) => sum + l.rate).toStringAsFixed(0)}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBlock(title: 'PKG TIME', value: 'N/A'),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(icon: Icons.phone, label: 'Call', onTap: () => _launchUrl('tel:${pupil.phone}')),
                    const SizedBox(width: 12),
                    _ActionButton(icon: Icons.message, label: 'Text', onTap: () => _launchUrl('sms:${pupil.phone}')),
                    const SizedBox(width: 12),
                    _ActionButton(icon: Icons.directions, label: 'Directions', onTap: () {
                      if (pupil.pickupAddresses.isNotEmpty) {
                        _launchUrl('https://maps.google.com/?q=${pupil.pickupAddresses.first}');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No address available')));
                      }
                    }),
                    const SizedBox(width: 12),
                    _ActionButton(icon: Icons.note_add, label: 'Notes', onTap: () {
                      _showNotesDialog(context, pupil);
                    }),
                  ],
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          
          // Tab Bar
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.sunsetBright,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppColors.sunsetBright,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'DETAILS'),
                  Tab(text: 'CONTACT'),
                  Tab(text: 'LOCATIONS'),
                  Tab(text: 'AVAILABILITY'),
                ],
              ),
            ),
          ),
          
          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // DETAILS Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (pupil.notes != null && pupil.notes!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Latest Note', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(pupil.notes!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Upcoming Lessons', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        TextButton(onPressed: (){}, child: const Text('Add', style: TextStyle(color: AppColors.sunsetBright, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.sunsetBright, AppColors.sunsetBright.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FilledButton.icon(
                        icon: const Icon(Icons.analytics),
                        label: const Text('View Progress Matrix'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProgressMatrixScreen(pupil: pupil)),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (upcomingLessons.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No upcoming lessons.', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    else
                      ...upcomingLessons.take(3).map((l) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.sunsetBright.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.event, color: AppColors.sunsetBright),
                          ),
                          title: Text(DateFormat('EEEE, MMM d').format(l.date), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${l.time} (${l.duration} mins)'),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      )),
                    const SizedBox(height: 24),
                    const Text('Lesson History', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 12),
                    if (pastLessons.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No past lessons.', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    else
                      ...pastLessons.take(5).map((l) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(DateFormat('d MMM yyyy').format(l.date), style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${l.time} · ${labelEnum(l.status)}'),
                          trailing: Text('£${l.rate.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      )),
                  ],
                ),

                // CONTACT Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    InkWell(
                      onTap: pupil.phone.isNotEmpty ? () => _launchUrl('tel:${pupil.phone}') : null,
                      child: _ContactTile(
                        icon: Icons.phone,
                        title: pupil.phone.isNotEmpty ? pupil.phone : 'No phone number',
                        subtitle: 'Primary Phone',
                      ),
                    ),
                    InkWell(
                      onTap: pupil.email.isNotEmpty ? () => _launchUrl('mailto:${pupil.email}') : null,
                      child: _ContactTile(
                        icon: Icons.email,
                        title: pupil.email.isNotEmpty ? pupil.email : 'No email',
                        subtitle: 'Email Address',
                      ),
                    ),
                  ],
                ),

                // LOCATIONS Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('Pickup Addresses', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 12),
                    if (pupil.pickupAddresses.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.location_off, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('None provided.', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    else
                      ...pupil.pickupAddresses.map((a) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.sunsetBright.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.flight_takeoff, color: AppColors.sunsetBright),
                          ),
                          title: Text(a, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.map, color: AppColors.sunsetBright),
                          onTap: () => _launchUrl('https://maps.google.com/?q=${Uri.encodeComponent(a)}'),
                        ),
                      )),
                    const SizedBox(height: 24),
                    _ContactTile(
                      icon: Icons.map,
                      title: pupil.postcode ?? 'No postcode',
                      subtitle: 'Assigned Postcode / Area',
                    ),
                  ],
                ),

                // AVAILABILITY Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('Weekly Availability Days', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No preferred days set.', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Availability Windows (Matrix)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.grid_view, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('This area will display a heatmap or time-block matrix.', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LessonStatus _mapLessonStatus(String? status) {
    switch (status) {
      case 'completed':
        return LessonStatus.completed;
      case 'cancelled':
        return LessonStatus.cancelled;
      case 'no_show':
        return LessonStatus.noShow;
      default:
        return LessonStatus.scheduled;
    }
  }

  void _showNotesDialog(BuildContext context, Pupil pupil) {
    final controller = TextEditingController(text: pupil.notes ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Add notes'),
          maxLines: 5,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('pupils')
                    .update({'notes': controller.text.trim()})
                    .eq('id', pupil.id);
                if (mounted) {
                  ref.invalidate(instructorPupilsProvider);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notes saved')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(userFriendlyError(e))),
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
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.sunsetBright)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.sunsetBright.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.sunsetBright, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppColors.sunsetBright, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.sunsetBright.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.sunsetBright, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ),
    );
  }
}
