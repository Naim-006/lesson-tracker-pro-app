import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/error_handler.dart';
import '../diary/lesson_form_screen.dart';
import '../finances/request_payment_form_screen.dart';
import '../test_reports/test_report_form_screen.dart';
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

  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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
          const SnackBar(content: Text('Error launching URL')),
        );
      }
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(instructorPupilsProvider);
    ref.invalidate(instructorLessonsProvider);
    // Wait for both to complete so the refresh indicator dismisses cleanly.
    await Future.wait([
      ref.read(instructorPupilsProvider.future),
      ref.read(instructorLessonsProvider.future),
    ]);
  }

  Pupil _pupilFromLink(Map<String, dynamic> link, Pupil fallback) {
    final data = link['pupils'] as Map<String, dynamic>? ?? {};
    return _pupilFromRow(data, fallback);
  }

  Pupil _pupilFromRow(Map<String, dynamic> data, Pupil fallback) {
    DateTime? testDate;
    if (data['test_date'] != null) {
      testDate = DateTime.tryParse(data['test_date'].toString());
    }

    return Pupil(
      id: data['id'] as String? ?? fallback.id,
      firstName: data['first_name'] as String? ?? fallback.firstName,
      lastName: data['last_name'] as String? ?? fallback.lastName,
      phone: data['phone'] as String? ?? fallback.phone,
      secondaryPhone: data['secondary_phone'] as String? ?? fallback.secondaryPhone,
      email: data['email'] as String? ?? fallback.email,
      postcode: data['postcode'] as String? ?? fallback.postcode,
      pickupAddresses: data['pickup_addresses'] != null
          ? List<String>.from(data['pickup_addresses'] as List)
          : fallback.pickupAddresses,
      dropoffAddresses: data['dropoff_addresses'] != null
          ? List<String>.from(data['dropoff_addresses'] as List)
          : fallback.dropoffAddresses,
      hourlyRate: (data['hourly_rate'] as num?)?.toDouble() ?? fallback.hourlyRate,
      mechanicalGearboxPreference: _mapGearbox(data['mechanical_gearbox_preference'] as String?),
      status: _mapStatus(data['status'] as String?),
      tags: data['tags'] != null ? List<String>.from(data['tags'] as List) : fallback.tags,
      availability: _mapAvailability(data['availability']),
      weeklyAvailabilityDays: data['weekly_availability_days'] != null
          ? List<String>.from(data['weekly_availability_days'] as List)
          : fallback.weeklyAvailabilityDays,
      notes: data['notes'] as String? ?? fallback.notes,
      aggregatedTotalLessonsCount: data['aggregated_total_lessons_count'] as int? ??
          fallback.aggregatedTotalLessonsCount,
      packageTimePrepaidMinutes: data['package_time_prepaid_minutes'] as int? ??
          fallback.packageTimePrepaidMinutes,
      packageTimeRemainingMinutes: data['package_time_remaining_minutes'] as int? ??
          fallback.packageTimeRemainingMinutes,
      outstandingBalance: (data['outstanding_balance'] as num?)?.toDouble() ??
          fallback.outstandingBalance,
      progressScores: fallback.progressScores,
      progressScaleType: data['progress_scale_type'] as int? ?? fallback.progressScaleType,
      testDate: testDate ?? fallback.testDate,
      testPassed: data['test_passed'] as bool? ?? fallback.testPassed,
    );
  }

  GearboxType _mapGearbox(String? value) {
    switch (value) {
      case 'automatic':
        return GearboxType.automatic;
      case 'any':
        return GearboxType.any;
      default:
        return GearboxType.manual;
    }
  }

  PupilStatus _mapStatus(String? value) {
    switch (value) {
      case 'waiting':
        return PupilStatus.waiting;
      case 'passed':
        return PupilStatus.passed;
      case 'archived':
        return PupilStatus.archived;
      case 'cancelled':
        return PupilStatus.cancelled;
      default:
        return PupilStatus.current;
    }
  }

  Map<String, List<int>> _mapAvailability(dynamic value) {
    if (value == null) return {};
    try {
      final map = value as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, List<int>.from(v as List)));
    } catch (_) {
      return {};
    }
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

  String _formatPackageTime(int minutes) {
    if (minutes <= 0) return '0h 0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Future<void> _updateAvailabilityDays(Pupil pupil, List<String> days) async {
    try {
      await Supabase.instance.client
          .from('pupils')
          .update({'weekly_availability_days': days})
          .eq('id', pupil.id);
      if (mounted) {
        ref.invalidate(instructorPupilsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  Future<void> _updateTestPassed(Pupil pupil, bool? passed) async {
    try {
      await Supabase.instance.client
          .from('pupils')
          .update({'test_passed': passed})
          .eq('id', pupil.id);
      if (mounted) {
        ref.invalidate(instructorPupilsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  void _showNotesDialog(BuildContext context, Pupil pupil) {
    final controller = TextEditingController(text: pupil.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notes'),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Add notes'),
            maxLines: 5,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              try {
                await Supabase.instance.client
                    .from('pupils')
                    .update({'notes': controller.text.trim()})
                    .eq('id', pupil.id);
                if (!mounted) return;
                ref.invalidate(instructorPupilsProvider);
                navigator.pop();
                messenger.showSnackBar(const SnackBar(content: Text('Notes saved')));
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(content: Text(userFriendlyError(e))));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAvailabilityEditor(Pupil pupil) {
    final selected = List<String>.from(pupil.weeklyAvailabilityDays);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Weekly Availability'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _weekDays.map((day) {
                final isSelected = selected.contains(day);
                return CheckboxListTile(
                  value: isSelected,
                  title: Text(day),
                  activeColor: AppColors.sunsetBright,
                  onChanged: (v) {
                    setLocalState(() {
                      if (v == true) {
                        if (!selected.contains(day)) selected.add(day);
                      } else {
                        selected.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _updateAvailabilityDays(pupil, selected);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instructorPupils = ref.watch(instructorPupilsProvider);
    final instructorLessons = ref.watch(instructorLessonsProvider);

    final pupilData = instructorPupils.value?.firstWhere(
      (link) => link['pupils']?['id'] == widget.pupil.id,
      orElse: () => <String, dynamic>{},
    );

    final pupil = pupilData != null && pupilData.isNotEmpty
        ? _pupilFromLink(pupilData, widget.pupil)
        : widget.pupil;

    final lessons = instructorLessons.value?.where((l) => l['pupil_id'] == pupil.id).map((lesson) {
          final pupilData = lesson['pupils'];
          final String pupilName = pupilData != null
              ? '${pupilData['first_name'] ?? ''} ${pupilData['last_name'] ?? ''}'.trim()
              : 'Unknown';
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse(lesson['date']);
          } catch (_) {
            parsedDate = DateTime.now();
          }
          return Lesson(
            id: lesson['id'] as String?,
            pupilId: lesson['pupil_id'],
            pupilName: pupilName.isNotEmpty ? pupilName : 'Unknown',
            date: parsedDate,
            time: lesson['time'],
            duration: lesson['duration'] ?? 60,
            rate: (lesson['rate'] as num?)?.toDouble() ?? 0.0,
            pickupLocation: lesson['pickup_location'] ?? '',
            status: _mapLessonStatus(lesson['status']),
            notes: lesson['notes'] ?? '',
          );
        }).toList() ??
        [];

    lessons.sort((a, b) => b.date.compareTo(a.date));

    final upcomingLessons = lessons
        .where((l) => l.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .toList();
    final pastLessons = lessons.where((l) => l.date.isBefore(DateTime.now())).toList();

    final totalEarned = pastLessons
        .where((l) => l.status == LessonStatus.completed)
        .fold<double>(0, (sum, l) => sum + l.rate);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.sunsetBright,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context, pupil),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatBlock(
                        title: 'LESSONS',
                        value: '${lessons.length}',
                        icon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBlock(
                        title: 'EARNED',
                        value: '£${totalEarned.toStringAsFixed(0)}',
                        icon: Icons.payments,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBlock(
                        title: 'PKG TIME',
                        value: _formatPackageTime(pupil.packageTimeRemainingMinutes),
                        icon: Icons.timer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ActionButton(
                        icon: Icons.phone,
                        label: 'Call',
                        onTap: pupil.phone.isNotEmpty
                            ? () => _launchUrl('tel:${pupil.phone}')
                            : null,
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: Icons.message,
                        label: 'Text',
                        onTap: pupil.phone.isNotEmpty
                            ? () => _launchUrl('sms:${pupil.phone}')
                            : null,
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: Icons.directions,
                        label: 'Directions',
                        onTap: pupil.pickupAddresses.isNotEmpty
                            ? () => _launchUrl(
                                'https://maps.google.com/?q=${Uri.encodeComponent(pupil.pickupAddresses.first)}')
                            : null,
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: Icons.note_add,
                        label: 'Notes',
                        onTap: () => _showNotesDialog(context, pupil),
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: Icons.add_circle,
                        label: 'Lesson',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonFormScreen(initialPupil: pupil),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: Icons.assignment_turned_in,
                        label: 'Test',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TestReportFormScreen(pupil: pupil),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: Icons.request_page,
                        label: 'Payment',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestPaymentFormScreen(initialPupilId: pupil.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
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
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(context, pupil, upcomingLessons, pastLessons),
                  _buildContactTab(context, pupil),
                  _buildLocationsTab(context, pupil),
                  _buildAvailabilityTab(context, pupil),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Pupil pupil) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.sunsetBright,
                AppColors.sunsetBright.withValues(alpha: 0.7),
              ],
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
                          ).then((_) => ref.invalidate(instructorPupilsProvider)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                              '£${pupil.hourlyRate.toStringAsFixed(0)}/hr · ${labelEnum(pupil.mechanicalGearboxPreference)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    labelEnum(pupil.status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (pupil.testPassed != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (pupil.testPassed! ? AppColors.success : AppColors.error)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      pupil.testPassed! ? 'Test Passed' : 'Test Failed',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
    );
  }

  Widget _buildDetailsTab(
    BuildContext context,
    Pupil pupil,
    List<Lesson> upcomingLessons,
    List<Lesson> pastLessons,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _InfoCard(
          title: 'Student Overview',
          icon: Icons.person_outline,
          children: [
            _infoRow(Icons.flag, 'Status', labelEnum(pupil.status)),
            _infoRow(Icons.settings, 'Gearbox', labelEnum(pupil.mechanicalGearboxPreference)),
            if (pupil.testDate != null)
              _infoRow(
                Icons.event,
                'Test Date',
                DateFormat('d MMM yyyy').format(pupil.testDate!),
              ),
            _infoRow(
              Icons.account_balance_wallet,
              'Outstanding Balance',
              '£${pupil.outstandingBalance.toStringAsFixed(2)}',
            ),
            _infoRow(
              Icons.timer_outlined,
              'Package Time',
              '${_formatPackageTime(pupil.packageTimeRemainingMinutes)} remaining',
            ),
            if (pupil.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pupil.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.sunsetBright.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sunsetBright,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (pupil.notes != null && pupil.notes!.isNotEmpty) ...[
          _InfoCard(
            title: 'Latest Note',
            icon: Icons.notes,
            children: [
              Text(pupil.notes!),
            ],
          ),
          const SizedBox(height: 20),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Lessons', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LessonFormScreen(initialPupil: pupil)),
              ),
              child: const Text('Add', style: TextStyle(color: AppColors.sunsetBright, fontWeight: FontWeight.w600)),
            ),
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
          _EmptyState(icon: Icons.event_busy, message: 'No upcoming lessons.')
        else
          ...upcomingLessons.take(3).map((l) => _LessonTile(lesson: l)),
        const SizedBox(height: 24),
        const Text('Lesson History', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 12),
        if (pastLessons.isEmpty)
          _EmptyState(icon: Icons.history, message: 'No past lessons.')
        else
          ...pastLessons.take(5).map((l) => _HistoryTile(lesson: l)),
      ],
    );
  }

  Widget _buildContactTab(BuildContext context, Pupil pupil) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _InfoCard(
          title: 'Contact Information',
          icon: Icons.contact_phone,
          children: [
            _ContactTile(
              icon: Icons.phone,
              title: pupil.phone.isNotEmpty ? pupil.phone : 'No phone number',
              subtitle: 'Primary Phone',
              onTap: pupil.phone.isNotEmpty ? () => _launchUrl('tel:${pupil.phone}') : null,
            ),
            if (pupil.secondaryPhone != null && pupil.secondaryPhone!.isNotEmpty)
              _ContactTile(
                icon: Icons.phone_forwarded,
                title: pupil.secondaryPhone!,
                subtitle: 'Secondary Phone',
                onTap: () => _launchUrl('tel:${pupil.secondaryPhone}'),
              ),
            _ContactTile(
              icon: Icons.email,
              title: pupil.email.isNotEmpty ? pupil.email : 'No email',
              subtitle: 'Email Address',
              onTap: pupil.email.isNotEmpty ? () => _launchUrl('mailto:${pupil.email}') : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationsTab(BuildContext context, Pupil pupil) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _InfoCard(
          title: 'Pickup Addresses',
          icon: Icons.flight_takeoff,
          children: pupil.pickupAddresses.isEmpty
              ? [_EmptyState(icon: Icons.location_off, message: 'None provided.')]
              : pupil.pickupAddresses
                  .map((a) => _AddressTile(
                        address: a,
                        icon: Icons.flight_takeoff,
                        onTap: () => _launchUrl('https://maps.google.com/?q=${Uri.encodeComponent(a)}'),
                      ))
                  .toList(),
        ),
        const SizedBox(height: 20),
        _InfoCard(
          title: 'Drop-off Addresses',
          icon: Icons.flight_land,
          children: pupil.dropoffAddresses.isEmpty
              ? [_EmptyState(icon: Icons.location_off, message: 'None provided.')]
              : pupil.dropoffAddresses
                  .map((a) => _AddressTile(
                        address: a,
                        icon: Icons.flight_land,
                        onTap: () => _launchUrl('https://maps.google.com/?q=${Uri.encodeComponent(a)}'),
                      ))
                  .toList(),
        ),
        const SizedBox(height: 20),
        _InfoCard(
          title: 'Postcode / Area',
          icon: Icons.map,
          children: [
            _infoRow(Icons.map, 'Assigned Postcode', pupil.postcode ?? 'No postcode'),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityTab(BuildContext context, Pupil pupil) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _InfoCard(
          title: 'Weekly Availability Days',
          icon: Icons.calendar_today,
          action: TextButton.icon(
            onPressed: () => _showAvailabilityEditor(pupil),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
          children: pupil.weeklyAvailabilityDays.isEmpty
              ? [_EmptyState(icon: Icons.calendar_today, message: 'No preferred days set.')]
              : [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: pupil.weeklyAvailabilityDays.map((day) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.sunsetBright.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sunsetBright,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
        ),
        const SizedBox(height: 20),
        _InfoCard(
          title: 'Test Result',
          icon: Icons.assignment_turned_in,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pupil.testPassed == null
                        ? 'Not recorded'
                        : pupil.testPassed!
                            ? 'Passed'
                            : 'Failed',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () => _showTestResultEditor(pupil),
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _showTestResultEditor(Pupil pupil) {
    bool? passed = pupil.testPassed;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Update Test Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Not recorded'),
                    selected: passed == null,
                    selectedColor: AppColors.sunsetBright.withValues(alpha: 0.2),
                    onSelected: (_) => setLocalState(() => passed = null),
                  ),
                  ChoiceChip(
                    label: const Text('Passed'),
                    selected: passed == true,
                    selectedColor: AppColors.success.withValues(alpha: 0.2),
                    onSelected: (_) => setLocalState(() => passed = true),
                  ),
                  ChoiceChip(
                    label: const Text('Failed'),
                    selected: passed == false,
                    selectedColor: AppColors.error.withValues(alpha: 0.2),
                    onSelected: (_) => setLocalState(() => passed = false),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _updateTestPassed(pupil, passed);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.sunsetBright),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Icon(icon, color: AppColors.sunsetBright, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.sunsetBright),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.shade100
              : AppColors.sunsetBright.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled
                ? Colors.grey.shade300
                : AppColors.sunsetBright.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: disabled ? Colors.grey : AppColors.sunsetBright, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: disabled ? Colors.grey : AppColors.sunsetBright,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.icon, required this.children, this.action});
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                child: Icon(icon, color: AppColors.sunsetBright, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sunsetBright.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.sunsetBright, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address, required this.icon, required this.onTap});
  final String address;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.sunsetBright.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.sunsetBright, size: 18),
        ),
        title: Text(address, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.map, color: AppColors.sunsetBright, size: 20),
        onTap: onTap,
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
        title: Text(DateFormat('EEEE, MMM d').format(lesson.date),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${lesson.time} (${lesson.duration} mins)'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(DateFormat('d MMM yyyy').format(lesson.date),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${lesson.time} · ${labelEnum(lesson.status)}'),
        trailing: Text('£${lesson.rate.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
