import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../diary/open_slot_form_screen.dart';
import '../finances/request_payment_form_screen.dart';
import 'pupil_detail_screen.dart';
import 'pupil_form_screen.dart';

class PupilsScreen extends ConsumerStatefulWidget {
  const PupilsScreen({super.key});

  @override
  ConsumerState<PupilsScreen> createState() => _PupilsScreenState();
}

class _PupilsScreenState extends ConsumerState<PupilsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Pupil> _filter(List<Pupil> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where((p) =>
            p.fullName.toLowerCase().contains(q) ||
            p.phone.contains(q) ||
            p.email.toLowerCase().contains(q) ||
            (p.postcode?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  PupilStatus _mapStatus(String? status) {
    switch (status) {
      case 'active':
        return PupilStatus.current;
      case 'pending':
        return PupilStatus.waiting;
      case 'passed':
        return PupilStatus.passed;
      case 'archived':
        return PupilStatus.archived;
      default:
        return PupilStatus.current;
    }
  }

  void _showContactsPermissionDialog(BuildContext context) {
    _showImportContactsComingSoon(context);
  }

  void _showImportContactsComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add pupils manually using the + button, or send an invitation link from a pupil\'s profile.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instructorPupils = ref.watch(instructorPupilsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pupils = instructorPupils.value?.map((link) {
      final pupilData = link['pupils'];
      if (pupilData == null) return null;
      return Pupil(
        id: pupilData['id'],
        firstName: pupilData['first_name'] ?? '',
        lastName: pupilData['last_name'] ?? '',
        phone: pupilData['phone'] ?? '',
        email: pupilData['email'] ?? '',
        postcode: pupilData['postcode'],
        pickupAddresses: List<String>.from(pupilData['pickup_addresses'] ?? []),
        status: _mapStatus(pupilData['status']),
        hourlyRate: (pupilData['hourly_rate'] as num?)?.toDouble() ?? 40.0,
        outstandingBalance: 0.0,
      );
    }).whereType<Pupil>().toList() ?? [];

    final currentPupils = _filter(pupils.where((p) => p.status == PupilStatus.current).toList());
    final waitingPupils = _filter(pupils.where((p) => p.status == PupilStatus.waiting).toList());
    final passedPupils = _filter(pupils.where((p) => p.status == PupilStatus.passed).toList());
    final archivedPupils = _filter(pupils.where((p) => p.status == PupilStatus.archived).toList());

    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search pupils...',
                  hintStyle: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                  prefixIcon: Icon(Icons.search, color: isDark ? AppColors.darkMuted : AppColors.lightMuted, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.sunsetBright,
              unselectedLabelColor: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            indicatorColor: AppColors.sunsetBright,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            isScrollable: true,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: [
              Tab(text: 'CURRENT (${currentPupils.length})'),
              Tab(text: 'WAITING (${waitingPupils.length})'),
              Tab(text: 'PASSED (${passedPupils.length})'),
              Tab(text: 'ARCHIVED (${archivedPupils.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PupilList(pupils: currentPupils),
              _PupilList(pupils: waitingPupils),
              _PupilList(pupils: passedPupils),
              _PupilList(pupils: archivedPupils),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FooterActionLink(
                icon: Icons.person_add,
                label: 'Add new pupil',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilFormScreen())),
              ),
              const SizedBox(height: 4),
              _FooterActionLink(
                icon: Icons.event_available,
                label: 'Offer open lesson slot',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenSlotFormScreen())),
              ),
              const SizedBox(height: 4),
              _FooterActionLink(
                icon: Icons.payment,
                label: 'Request payment',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestPaymentFormScreen())),
              ),
              const SizedBox(height: 4),
              _FooterActionLink(
                icon: Icons.contacts,
                label: 'Import contacts',
                onTap: () => _showContactsPermissionDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterActionLink extends StatelessWidget {
  const _FooterActionLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.sunsetBright),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.sunsetBright,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PupilList extends ConsumerWidget {
  const _PupilList({required this.pupils});
  final List<Pupil> pupils;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (pupils.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
            const SizedBox(height: 16),
            Text(
              'No pupils in this list',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pupil to get started',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async { ref.invalidate(instructorPupilsProvider); },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pupils.length,
        itemBuilder: (context, i) {
          final p = pupils[i];
          final waitingDate = DateFormat('MMM d, yyyy').format(p.createdAt);
          return _PupilTile(
            pupil: p,
            waitingDate: waitingDate,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PupilDetailScreen(pupil: p)),
            ),
          );
        },
      ),
    );
  }
}

Color _statusColor(PupilStatus status) {
  switch (status) {
    case PupilStatus.current:
      return AppColors.success;
    case PupilStatus.waiting:
      return AppColors.warning;
    case PupilStatus.passed:
      return AppColors.info;
    case PupilStatus.archived:
      return AppColors.lightMuted;
    case PupilStatus.cancelled:
      return AppColors.error;
  }
}

String _statusLabel(PupilStatus status) {
  switch (status) {
    case PupilStatus.current:
      return 'Active';
    case PupilStatus.waiting:
      return 'Waiting';
    case PupilStatus.passed:
      return 'Passed';
    case PupilStatus.archived:
      return 'Archived';
    case PupilStatus.cancelled:
      return 'Cancelled';
  }
}

class _PupilTile extends StatelessWidget {
  const _PupilTile({
    required this.pupil,
    required this.waitingDate,
    required this.onTap,
  });

  final Pupil pupil;
  final String waitingDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.sunsetBright, AppColors.sunset],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    pupil.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                            child: Text(
                              pupil.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(pupil.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _statusLabel(pupil.status),
                            style: TextStyle(
                              color: _statusColor(pupil.status),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.drive_eta, size: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${pupil.aggregatedTotalLessonsCount} sessions',
                          style: TextStyle(
                            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (pupil.postcode != null && pupil.postcode!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on, size: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                          const SizedBox(width: 4),
                          Text(
                            pupil.postcode!,
                            style: TextStyle(
                              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (pupil.status == PupilStatus.waiting)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Waiting since: $waitingDate',
                          style: TextStyle(
                            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PupilMenuButton(pupil: pupil),
            ],
          ),
        ),
      ),
    );
  }
}

class _PupilMenuButton extends ConsumerWidget {
  const _PupilMenuButton({required this.pupil});

  final Pupil pupil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: isDark ? AppColors.darkMuted : AppColors.lightMuted, size: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      onSelected: (v) async {
        if (v == 'call') {
          await launchUrl(Uri.parse('tel:${pupil.phone}'));
        } else if (v == 'email' && pupil.email.isNotEmpty) {
          await launchUrl(Uri.parse('mailto:${pupil.email}'));
        } else if (v == 'edit') {
          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PupilFormScreen(existing: pupil),
            ),
          );
        } else if (v == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Pupil'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This will revoke the pupil\'s access:'),
                  SizedBox(height: 8),
                  Text('\u2022 Pupil will not be able to log in'),
                  Text('\u2022 All data and progress will be preserved'),
                  Text('\u2022 Auth account stays intact'),
                  SizedBox(height: 12),
                  Text('They can be reactivated anytime from the Registration screen.'),
                  SizedBox(height: 8),
                  Text('This can be undone.', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;

          try {
            await Supabase.instance.client.functions.invoke(
              'delete-pupil',
              body: { 'pupil_id': pupil.id },
            );

            if (context.mounted) {
              ref.invalidate(instructorPupilsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pupil deleted')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'call', child: Row(children: [Icon(Icons.call, size: 18), SizedBox(width: 12), Text('Call')])),
        const PopupMenuItem(value: 'email', child: Row(children: [Icon(Icons.email, size: 18), SizedBox(width: 12), Text('Email')])),
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 12), Text('Edit')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
      ],
    );
  }
}
