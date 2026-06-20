import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import 'enquiry_form_screen.dart';

class EnquiryScreen extends ConsumerStatefulWidget {
  const EnquiryScreen({super.key});

  @override
  ConsumerState<EnquiryScreen> createState() => _EnquiryScreenState();
}

class _EnquiryScreenState extends ConsumerState<EnquiryScreen> {
  String _query = '';

  Color _statusColor(EnquiryStatus s) {
    switch (s) {
      case EnquiryStatus.pending: return AppColors.info;
      case EnquiryStatus.contacted: return AppColors.warning;
      case EnquiryStatus.interested: return AppColors.sunsetBright;
      case EnquiryStatus.converted: return AppColors.success;
      case EnquiryStatus.notInterested: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enquiries = ref.watch(instructorEnquiriesProvider);
    final list = enquiries.value ?? [];

    final filteredList = list
        .where((e) => _query.isEmpty || _fullName(e).toLowerCase().contains(_query.toLowerCase()))
        .toList();

    // Simulate a few "incoming leads" from pending enquiries
    final pending = filteredList.where((e) => e['status'] == 'pending').toList();
    final others = filteredList.where((e) => e['status'] != 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnquiryFormScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Incoming leads queue
          if (pending.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inbox, size: 16, color: AppColors.info),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'INCOMING LEADS (${pending.length} PENDING)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.info),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...pending.take(3).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.info.withValues(alpha: 0.15),
                          child: Text(_firstInitial(e), style: const TextStyle(color: AppColors.info, fontSize: 13)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_fullName(e), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(_mapGearbox(e['gearbox_preference']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _acceptLead(e),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('VIEW LEAD', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search enquiries…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // Full list
          Expanded(
            child: filteredList.isEmpty
                ? const Center(child: Text('No enquiries', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: others.length,
                    itemBuilder: (context, i) {
                      final e = others[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(_mapEnquiryStatus(e['status'])).withValues(alpha: 0.15),
                            child: Text(_firstInitial(e),
                                style: TextStyle(color: _statusColor(_mapEnquiryStatus(e['status'])), fontWeight: FontWeight.bold)),
                          ),
                          title: Text(_fullName(e), style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${_mapEnquiryStatusLabel(e['status'])} · ${_mapExperience(e['experience_level'])}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(_mapEnquiryStatus(e['status'])).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_mapEnquiryStatusLabel(e['status']),
                                style: TextStyle(color: _statusColor(_mapEnquiryStatus(e['status'])), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          onTap: () => _showDetail(context, e),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _fullName(Map<String, dynamic> e) {
    final first = e['first_name'] as String? ?? '';
    final last = e['last_name'] as String? ?? '';
    final full = '$first $last'.trim();
    return full.isNotEmpty ? full : (e['name'] as String? ?? 'Unknown');
  }

  String _firstInitial(Map<String, dynamic> e) {
    final first = e['first_name'] as String? ?? '';
    if (first.isNotEmpty) return first[0].toUpperCase();
    final name = e['name'] as String? ?? '';
    return name.isNotEmpty ? name[0] : '?';
  }

  String _mapGearbox(String? preference) {
    switch (preference) {
      case 'manual': return 'Manual';
      case 'automatic': return 'Automatic';
      default: return 'Any';
    }
  }

  String _mapExperience(String? level) {
    switch (level) {
      case 'beginner': return 'Beginner';
      case 'intermediate': return 'Intermediate';
      case 'experienced': return 'Experienced';
      default: return 'Unknown';
    }
  }

  EnquiryStatus _mapEnquiryStatus(String? status) {
    switch (status) {
      case 'pending': return EnquiryStatus.pending;
      case 'contacted': return EnquiryStatus.contacted;
      case 'interested': return EnquiryStatus.interested;
      case 'converted': return EnquiryStatus.converted;
      case 'not_interested': return EnquiryStatus.notInterested;
      default: return EnquiryStatus.pending;
    }
  }

  String _mapEnquiryStatusLabel(String? status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'contacted': return 'Contacted';
      case 'interested': return 'Interested';
      case 'converted': return 'Converted';
      case 'not_interested': return 'Not Interested';
      default: return 'Pending';
    }
  }

  Future<void> _acceptLead(Map<String, dynamic> enquiry) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final firstName = enquiry['first_name'] as String? ?? '';
      final lastName = enquiry['last_name'] as String? ?? '';
      final email = enquiry['email'] as String? ?? '';

      // Create invitation for the pupil to sign up
      final uuid = const Uuid();
      final invitationCode = uuid.v4().substring(0, 8).toUpperCase();

      await Supabase.instance.client.from('pupil_invitations').insert({
        'instructor_id': user.id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': enquiry['phone'] as String? ?? '',
        'postcode': enquiry['postcode'] as String? ?? '',
        'invitation_code': invitationCode,
        'status': 'pending',
        'source': 'enquiry',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update enquiry status
      await Supabase.instance.client
          .from('enquiries')
          .update({'status': 'converted'})
          .eq('id', enquiry['id']);

      if (mounted) {
        ref.invalidate(instructorPupilsProvider);
        ref.invalidate(instructorEnquiriesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation sent to $firstName $lastName (Code: $invitationCode)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showDetail(BuildContext context, Map<String, dynamic> e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(_fullName(e), style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if ((e['phone'] as String? ?? '').isNotEmpty) Text(e['phone'] as String? ?? '', style: const TextStyle(color: Colors.grey)),
            if ((e['email'] as String? ?? '').isNotEmpty) Text(e['email'] as String? ?? '', style: const TextStyle(color: Colors.grey)),
            if ((e['notes'] as String? ?? '').isNotEmpty) ...[const SizedBox(height: 8), Text(e['notes'] as String? ?? '')],
            const SizedBox(height: 16),
            Row(
              children: [
                if ((e['phone'] as String? ?? '').isNotEmpty) ...[
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    onPressed: () => launchUrl(Uri.parse('tel:${e['phone']}')),
                  )),
                  const SizedBox(width: 8),
                ],
                if ((e['email'] as String? ?? '').isNotEmpty) ...[
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.email),
                    label: const Text('Email'),
                    onPressed: () => launchUrl(Uri.parse('mailto:${e['email']}')),
                  )),
                  const SizedBox(width: 8),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);
                      try {
                        await Supabase.instance.client.from('enquiries').delete().eq('id', e['id']);
                        if (!mounted) return;
                        ref.invalidate(instructorEnquiriesProvider);
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Enquiry deleted')),
                        );
                      } catch (error) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error: ${error.toString()}')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
