import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../activity/chat_screen.dart';

class PupilMessagesScreen extends StatefulWidget {
  const PupilMessagesScreen({super.key});

  @override
  State<PupilMessagesScreen> createState() => _PupilMessagesScreenState();
}

class _PupilMessagesScreenState extends State<PupilMessagesScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (_user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('messages')
          .select('*, sender:profiles!sender_id(full_name), receiver:profiles!receiver_id(full_name)')
          .or('sender_id.eq.${_user!.id},receiver_id.eq.${_user!.id}')
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> convos = {};
      for (final msg in res) {
        final otherId = msg['sender_id'] == _user!.id ? msg['receiver_id'] : msg['sender_id'];
        final otherName = msg['sender_id'] == _user!.id
            ? (msg['receiver']?['full_name'] ?? 'Unknown')
            : (msg['sender']?['full_name'] ?? 'Unknown');

        if (!convos.containsKey(otherId)) {
          convos[otherId] = {
            'other_id': otherId,
            'other_name': otherName,
            'last_message': msg['content'] ?? '',
            'created_at': msg['created_at'] ?? '',
            'unread': msg['receiver_id'] == _user!.id && msg['read'] == false ? 1 : 0,
          };
        } else {
          if (msg['receiver_id'] == _user!.id && msg['read'] == false) {
            convos[otherId]!['unread'] = (convos[otherId]!['unread'] as int) + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          _conversations = convos.values.toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright))
        : Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 20, color: isDark ? AppColors.darkMuted : Colors.grey.shade400),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search conversations...',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkMuted : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Conversations list
              Expanded(
                child: _conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 14),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start a conversation with your instructor',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        color: AppColors.sunsetBright,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final convo = _conversations[index];
                            return _ConversationTile(
                              name: convo['other_name'] ?? 'Unknown',
                              lastMessage: convo['last_message'] ?? '',
                              time: convo['created_at'] ?? '',
                              unread: convo['unread'] ?? 0,
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      pupilId: convo['other_id'],
                                      pupilName: convo['other_name'] ?? 'Unknown',
                                    ),
                                  ),
                                ).then((_) => _loadConversations());
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.isDark,
    required this.onTap,
  });

  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isDark;
  final VoidCallback onTap;

  String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: unread > 0
                  ? AppColors.sunsetBright.withValues(alpha: isDark ? 0.08 : 0.04)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.sunsetBright.withValues(alpha: 0.8), AppColors.sunset.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      initials.isNotEmpty ? initials : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
                          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lastMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white.withValues(alpha: 0.35) : Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(time),
                      style: TextStyle(
                        fontSize: 11,
                        color: unread > 0
                            ? AppColors.sunsetBright
                            : (isDark ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade400),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.sunsetBright,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
        ),
      ),
    );
  }
}
