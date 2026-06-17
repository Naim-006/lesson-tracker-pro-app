import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import 'admin_chat_reply_screen.dart';

class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({super.key});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get distinct conversation partners from messages table
      final sentTo = await Supabase.instance.client
          .from('messages')
          .select('receiver_id')
          .eq('sender_id', user.id);

      final receivedFrom = await Supabase.instance.client
          .from('messages')
          .select('sender_id')
          .eq('receiver_id', user.id);

      final partnerIds = <String>{};
      for (final m in sentTo as List) {
        if (m['receiver_id'] != null) partnerIds.add(m['receiver_id'] as String);
      }
      for (final m in receivedFrom as List) {
        if (m['sender_id'] != null) partnerIds.add(m['sender_id'] as String);
      }

      if (partnerIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final profilesResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email')
          .inFilter('id', partnerIds.toList());

      final profiles = profilesResponse as List<Map<String, dynamic>>;

      // Get last message time for each conversation
      final conversations = <Map<String, dynamic>>[];
      for (final profile in profiles) {
        final lastMsg = await Supabase.instance.client
            .from('messages')
            .select('created_at')
            .or('and(sender_id.eq.${profile['id']},receiver_id.eq.${user.id}),and(sender_id.eq.${user.id},receiver_id.eq.${profile['id']})')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        conversations.add({
          'id': profile['id'],
          'created_at': lastMsg?['created_at'] ?? DateTime.now().toIso8601String(),
          'status': 'open',
          'profiles': profile,
        });
      }

      conversations.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: const Text(
                    'Support Chat',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Conversations list
                Expanded(
                  child: _conversations.isEmpty
                      ? const Center(
                          child: Text('No conversations found'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            final profile = conversation['profiles'] as Map?;
                            return _buildConversationCard(conversation, profile);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation, Map? profile) {
    final createdAt = conversation['created_at'] as String?;
    final profileId = profile?['id'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.sunset.withValues(alpha: 0.1),
                child: Text(
                  profile?['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'I',
                  style: TextStyle(
                    color: AppColors.sunset,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?['full_name'] ?? 'Unknown Instructor',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?['email'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                createdAt != null ? _formatDate(createdAt) : 'N/A',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (profileId != null) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AdminChatReplyScreen(
                          instructorId: profileId,
                          instructorName: profile?['full_name'] ?? 'Unknown',
                        ),
                      ));
                    }
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Open Chat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
