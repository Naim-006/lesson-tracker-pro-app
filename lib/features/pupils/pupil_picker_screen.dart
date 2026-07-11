import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class PupilPickerScreen extends ConsumerStatefulWidget {
  const PupilPickerScreen({super.key});

  @override
  ConsumerState<PupilPickerScreen> createState() => _PupilPickerScreenState();
}

class _PupilPickerScreenState extends ConsumerState<PupilPickerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      case 'cancelled':
        return PupilStatus.cancelled;
      default:
        return PupilStatus.current;
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructorPupils = ref.watch(instructorPupilsProvider);

    // Convert Supabase data to local Pupil models
    final pupils = instructorPupils.value?.map((link) {
      final pupilData = link['pupils'] ?? <String, dynamic>{};
      return Pupil(
        id: pupilData['id'],
        firstName: pupilData['first_name'] ?? '',
        lastName: pupilData['last_name'] ?? '',
        phone: pupilData['phone'] ?? '',
        email: pupilData['email'] ?? '',
        postcode: pupilData['postcode'],
        pickupAddresses: pupilData['pickup_addresses'] != null
            ? List<String>.from(pupilData['pickup_addresses'])
            : [],
        status: _mapStatus(link['status']),
        outstandingBalance: 0.0,
      );
    }).toList() ?? [];

    final activePupils = _filter(pupils.where((p) => p.status != PupilStatus.cancelled).toList());
    final cancelledPupils = _filter(pupils.where((p) => p.status == PupilStatus.cancelled).toList());

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Pupil', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search pupils...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.sunsetBright,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.sunsetBright,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: [
                Tab(text: 'ACTIVE (${activePupils.length})'),
                Tab(text: 'CANCELLED (${cancelledPupils.length})'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PupilList(pupils: activePupils),
                _PupilList(pupils: cancelledPupils),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PupilList extends StatelessWidget {
  const _PupilList({required this.pupils});
  final List<Pupil> pupils;

  @override
  Widget build(BuildContext context) {
    if (pupils.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.sunsetBright.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_search,
                  size: 48,
                  color: AppColors.sunsetBright.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No pupils found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pupils.length,
      itemBuilder: (context, i) {
        final p = pupils[i];
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
          child: InkWell(
            onTap: () => Navigator.pop(context, p),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.sunsetBright,
                          AppColors.sunsetBright.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        p.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.drive_eta, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${p.aggregatedTotalLessonsCount} sessions',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (p.postcode != null && p.postcode!.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                p.postcode!,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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
            ),
          ),
        );
      },
    );
  }
}
