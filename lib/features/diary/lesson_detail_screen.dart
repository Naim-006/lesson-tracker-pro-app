import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/utils/error_handler.dart';
import '../finances/request_payment_form_screen.dart';
import 'lesson_form_screen.dart';
import 'mark_paid_dialog.dart';

class LessonDetailScreen extends ConsumerStatefulWidget {
  const LessonDetailScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  late Lesson _lesson;

  @override
  void initState() {
    super.initState();
    _lesson = widget.lesson;
  }

  String _mapLessonStatus(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed: return 'completed';
      case LessonStatus.cancelled: return 'cancelled';
      case LessonStatus.noShow: return 'no_show';
      default: return 'scheduled';
    }
  }

  Future<void> _updateLessonStatus(LessonStatus status) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('lessons').update({
        'status': _mapLessonStatus(status),
      }).eq('id', _lesson.id);

      if (mounted) {
        ref.invalidate(instructorLessonsProvider);
        ref.invalidate(instructorPupilsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lesson ${_mapLessonStatus(status)}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  Future<void> _deleteLesson() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete the lesson with ${_lesson.pupilName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await Supabase.instance.client.from('lessons').delete().eq('id', _lesson.id);
      if (mounted) {
        ref.invalidate(instructorLessonsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson deleted')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  Future<void> _markPaid() async {
    final result = await showModalBottomSheet<MarkPaidResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarkPaidDialog(lesson: _lesson),
    );
    if (result != null && mounted) {
      ref.invalidate(instructorLessonsProvider);
      ref.invalidate(instructorPaymentsProvider);
      setState(() => _lesson = _lesson.copyWith(paid: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.skipRecording
            ? 'Lesson marked as paid'
            : 'Lesson marked as paid — ${_capitalize(result.paymentMethod!)}')),
      );
    }
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return DateFormat('h:mm a').format(DateTime(2020, 1, 1, h, m));
    } catch (_) {
      return timeStr;
    }
  }

  String _formatDuration(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _calculateEndTime(String startTime, int durationMins) {
    try {
      final parts = startTime.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(2020, 1, 1, h, m).add(Duration(minutes: durationMins));
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(LessonStatus s) {
    switch (s) {
      case LessonStatus.completed: return AppColors.success;
      case LessonStatus.cancelled: return AppColors.error;
      case LessonStatus.noShow: return AppColors.warning;
      case LessonStatus.scheduled: return AppColors.sunsetBright;
    }
  }

  String _statusLabel(LessonStatus s) {
    switch (s) {
      case LessonStatus.scheduled: return 'Scheduled';
      case LessonStatus.completed: return 'Completed';
      case LessonStatus.cancelled: return 'Cancelled';
      case LessonStatus.noShow: return 'No Show';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pupilAsync = ref.watch(pupilByIdProvider(_lesson.pupilId));
    final unpaidLessonsAsync = ref.watch(pupilUnpaidLessonsProvider(_lesson.pupilId));
    final statusColor = _statusColor(_lesson.status);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Lesson Details', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LessonFormScreen(existing: _lesson)),
              ).then((_) => ref.invalidate(instructorLessonsProvider));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(instructorLessonsProvider);
          ref.invalidate(pupilByIdProvider(_lesson.pupilId));
          ref.invalidate(pupilUnpaidLessonsProvider(_lesson.pupilId));
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _lesson.status == LessonStatus.completed
                        ? Icons.check_circle
                        : _lesson.status == LessonStatus.cancelled
                            ? Icons.cancel
                            : _lesson.status == LessonStatus.noShow
                                ? Icons.warning
                                : Icons.schedule,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _statusLabel(_lesson.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (_lesson.paid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PAID',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lesson Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _lesson.pupilName.isNotEmpty
                                ? _lesson.pupilName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
                                : '?',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
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
                              _lesson.pupilName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(_lesson.date),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  // Time & Duration
                  _infoRow(Icons.access_time, 'Time', '${_formatTime(_lesson.time)} - ${_calculateEndTime(_lesson.time, _lesson.duration)}', isDark),
                  const SizedBox(height: 12),
                  _infoRow(Icons.hourglass_bottom, 'Duration', _formatDuration(_lesson.duration), isDark),
                  const SizedBox(height: 12),
                  // Lesson Type
                  _infoRow(Icons.category, 'Type', labelEnum(_lesson.type), isDark),
                  const SizedBox(height: 12),
                  // Rate
                  _infoRow(Icons.currency_pound, 'Rate', '\u00a3${_lesson.rate.toStringAsFixed(2)}', isDark),
                  if (_lesson.pickupLocation != null && _lesson.pickupLocation!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _locationRow(Icons.trip_origin, 'Pickup', _lesson.pickupLocation!, isDark),
                  ],
                  if (_lesson.dropoffLocation != null && _lesson.dropoffLocation!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _locationRow(Icons.location_on, 'Drop-off', _lesson.dropoffLocation!, isDark),
                  ],
                  if (_lesson.notes != null && _lesson.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(Icons.note, 'Notes', _lesson.notes!, isDark),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pupil Contact Card
            pupilAsync.when(
              data: (pupil) {
                if (pupil == null) return const SizedBox.shrink();
                final phone = pupil['phone'] as String? ?? '';
                final email = pupil['email'] as String? ?? '';
                final secondaryPhone = pupil['secondary_phone'] as String? ?? '';

                if (phone.isEmpty && email.isEmpty && secondaryPhone.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.contact_phone, color: AppColors.info, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('Pupil Contact', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(phone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.call, size: 18, color: AppColors.success),
                                onPressed: () => _launchPhone(phone),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                            ],
                          ),
                        ),
                      if (secondaryPhone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(Icons.phone_forwarded, size: 16, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(secondaryPhone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.call, size: 18, color: AppColors.success),
                                onPressed: () => _launchPhone(secondaryPhone),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                            ],
                          ),
                        ),
                      if (email.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.email, size: 16, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, size: 18, color: AppColors.info),
                              onPressed: () => _launchEmail(email),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Unpaid / Payment Due Section
            unpaidLessonsAsync.when(
              data: (unpaidLessons) {
                if (unpaidLessons.isEmpty) return const SizedBox.shrink();

                final totalDue = unpaidLessons.fold<double>(0, (sum, l) {
                  final rate = (l['rate'] as num?)?.toDouble() ?? 0;
                  return sum + rate;
                });

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          const Text('Payment Due', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const Spacer(),
                          Text(
                            '${unpaidLessons.length} lessons',
                            style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Total outstanding: ',
                            style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                          ),
                          Text(
                            '\u00a3${totalDue.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.warning),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RequestPaymentFormScreen(initialPupilId: _lesson.pupilId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.request_quote, size: 18),
                          label: const Text('Request Payment'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (unpaidLessonsAsync.value?.isNotEmpty == true) const SizedBox(height: 20),

            // Action Buttons
            if (_lesson.status != LessonStatus.completed) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _updateLessonStatus(LessonStatus.completed),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text('Mark Complete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sunsetBright,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (!_lesson.paid && _lesson.status == LessonStatus.completed) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _markPaid,
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('Mark as Paid'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: AppColors.success),
                    foregroundColor: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonFormScreen(existing: _lesson),
                        ),
                      ).then((_) => ref.invalidate(instructorLessonsProvider));
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (!_lesson.paid)
                  SizedBox(width: 12),
                if (!_lesson.paid)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestPaymentFormScreen(initialPupilId: _lesson.pupilId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.request_quote, size: 18),
                      label: const Text('Request'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: AppColors.sunsetBright,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Cancel / Delete
            Row(
              children: [
                if (_lesson.status != LessonStatus.cancelled)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _updateLessonStatus(LessonStatus.cancelled),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel Lesson'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppColors.warning,
                      ),
                    ),
                  ),
                if (_lesson.status != LessonStatus.cancelled) const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _deleteLesson,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMaps(String query) async {
    final uri = Uri.parse(GeocodingService.googleMapsQueryUrl(query));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationRow(IconData icon, String label, String address, bool isDark) {
    return GestureDetector(
      onTap: () => _openInMaps(address),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.info),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 12, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    'MAP',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.info,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
