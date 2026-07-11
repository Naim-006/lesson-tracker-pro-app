import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../activity/chat_screen.dart';

class PupilMessagingScreen extends StatefulWidget {
  const PupilMessagingScreen({super.key});

  @override
  State<PupilMessagingScreen> createState() => _PupilMessagingScreenState();
}

class _PupilMessagingScreenState extends State<PupilMessagingScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (user == null) return;

    try {
      // Get unique conversation partners (people the pupil has messaged or received from)
      final sentMessages = await Supabase.instance.client
          .from('messages')
          .select('receiver_id, receiver:profiles!inner(full_name, avatar_url)')
          .eq('sender_id', user!.id);

      final receivedMessages = await Supabase.instance.client
          .from('messages')
          .select('sender_id, sender:profiles!inner(full_name, avatar_url)')
          .eq('receiver_id', user!.id);

      // Combine and deduplicate conversations
      final Map<String, Map<String, dynamic>> conversations = {};

      for (var msg in sentMessages) {
        final partnerId = msg['receiver_id'];
        if (!conversations.containsKey(partnerId)) {
          conversations[partnerId] = {
            'id': partnerId,
            'profile': msg['receiver'],
            'last_message': msg['content'],
            'last_message_time': msg['created_at'],
            'unread_count': 0,
          };
        }
      }

      for (var msg in receivedMessages) {
        final partnerId = msg['sender_id'];
        if (!conversations.containsKey(partnerId)) {
          conversations[partnerId] = {
            'id': partnerId,
            'profile': msg['sender'],
            'last_message': msg['content'],
            'last_message_time': msg['created_at'],
            'unread_count': msg['read'] ? 0 : 1,
          };
        } else {
          // Update with latest message
          if (DateTime.parse(msg['created_at']).isAfter(
              DateTime.parse(conversations[partnerId]!['last_message_time']))) {
            conversations[partnerId]!['last_message'] = msg['content'];
            conversations[partnerId]!['last_message_time'] = msg['created_at'];
          }
          if (!msg['read']) {
            conversations[partnerId]!['unread_count'] =
                (conversations[partnerId]!['unread_count'] as int) + 1;
          }
        }
      }

      // Convert to list and sort by last message time
      final conversationList = conversations.values.toList()
        ..sort((a, b) => DateTime.parse(b['last_message_time'])
            .compareTo(DateTime.parse(a['last_message_time'])));

      setState(() {
        _conversations = conversationList;
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
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.purple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyView()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final convo = _conversations[index];
                      return _ConversationCard(
                        conversation: convo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                pupilId: convo['id'],
                                pupilName: convo['profile']?['full_name'] ?? 'User',
                              ),
                            ),
                          ).then((_) => _loadConversations());
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Messages Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with your instructor',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.onTap,
  });

  final Map<String, dynamic> conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = conversation['profile'];
    final lastMessageTime = DateTime.parse(conversation['last_message_time']);
    final unreadCount = conversation['unread_count'] as int;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  backgroundImage: profile['avatar_url'] != null
                      ? NetworkImage(profile['avatar_url'])
                      : null,
                  child: profile['avatar_url'] == null
                      ? Icon(
                          Icons.person,
                          color: Colors.purple,
                          size: 28,
                        )
                      : null,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          profile['full_name'] ?? 'User',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(lastMessageTime),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation['last_message'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
