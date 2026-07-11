import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/supabase_pupil_provider.dart';
import '../../core/theme/app_colors.dart';

class PupilInstructorScreen extends ConsumerWidget {
  const PupilInstructorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkAsync = ref.watch(pupilInstructorLinkProvider);
    final vehiclesAsync = ref.watch(pupilInstructorVehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Instructor'),
        backgroundColor: AppColors.sunsetBright,
        foregroundColor: Colors.white,
      ),
      body: linkAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)),
        error: (_, __) => const Center(child: Text('Error loading instructor')),
        data: (link) {
          final instructor = link?['instructors'] as Map<String, dynamic>?;
          if (instructor == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No instructor linked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          final name = instructor['full_name'] as String? ?? 'Instructor';
          final business = instructor['business_name'] as String?;
          final phone = instructor['phone'] as String?;
          final email = instructor['email'] as String?;
          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pupilInstructorLinkProvider);
              ref.invalidate(pupilInstructorVehiclesProvider);
            },
            color: AppColors.sunsetBright,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                        child: Center(child: Text(initial, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white))),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                      if (business != null && business.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(business, style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.85))),
                        ),
                      Text('Driving Instructor', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (phone != null || email != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.contact_phone_rounded, color: AppColors.sunsetBright, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text('Contact', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (phone != null && phone.isNotEmpty) ...[
                          InkWell(
                            onTap: () async { final u = Uri.parse('tel:$phone'); if (await canLaunchUrl(u)) await launchUrl(u); },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.phone_rounded, color: AppColors.success, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(phone, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                      Text('Phone', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                    ],
                                  )),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (email != null && email.isNotEmpty) ...[
                          InkWell(
                            onTap: () async { final u = Uri.parse('mailto:$email'); if (await canLaunchUrl(u)) await launchUrl(u); },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.email_rounded, color: AppColors.info, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(email, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                  ],
                                )),
                                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                vehiclesAsync.when(
                  loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (vehicles) {
                    if (vehicles.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.directions_car_rounded, color: AppColors.sunsetBright, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text('Vehicles', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              const Spacer(),
                              Text('${vehicles.length} ${vehicles.length == 1 ? 'car' : 'cars'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...vehicles.map((v) {
                            final make = v['make'] as String? ?? '';
                            final model = v['model'] as String? ?? '';
                            final gearbox = v['gearbox'] as String? ?? 'manual';
                            final isPrimary = v['is_primary'] as bool? ?? false;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        make.isNotEmpty ? make[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('$make $model', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                            if (isPrimary)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                                  child: const Text('PRIMARY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.sunsetBright)),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          gearbox == 'automatic' ? 'Automatic' : gearbox == 'any' ? 'Manual/Auto' : 'Manual',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (v['registration_plate'] != null)
                                    Text(v['registration_plate'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sunsetBright, letterSpacing: 1)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
