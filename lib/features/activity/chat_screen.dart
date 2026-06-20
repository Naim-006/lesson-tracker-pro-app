import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.pupilId,
    required this.pupilName,
  });

  final String pupilId;
  final String pupilName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();
  bool _sessionLocked = false;
  Map<String, dynamic>? _editingMessage;

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sessionLocked) return;
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (_editingMessage != null) {
        await Supabase.instance.client
            .from('messages')
            .update({'content': text})
            .eq('id', _editingMessage!['id']);
        setState(() => _editingMessage = null);
      } else {
        await Supabase.instance.client.from('messages').insert({
          'sender_id': user.id,
          'receiver_id': widget.pupilId,
          'content': text,
        });
      }
      if (mounted) {
        _input.clear();
        ref.invalidate(instructorMessagesProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    try {
      await Supabase.instance.client
          .from('messages')
          .delete()
          .eq('id', message['id']);
      if (mounted) {
        ref.invalidate(instructorMessagesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _editMessage(Map<String, dynamic> message) {
    setState(() {
      _editingMessage = message;
      _input.text = message['content'];
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(instructorMessagesProvider);
    final user = Supabase.instance.client.auth.currentUser;
    
    final msgs = messages.value?.where((m) {
      final isRelevant = (m['sender_id'] == user?.id && m['receiver_id'] == widget.pupilId) ||
                        (m['sender_id'] == widget.pupilId && m['receiver_id'] == user?.id);
      return isRelevant;
    }).toList() ?? [];
    
    msgs.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pupilName),
          ],
        ),
        actions: [
          // Lock/Unlock toggle
          IconButton(
            icon: Icon(
              _sessionLocked ? Icons.lock : Icons.lock_open,
              color: _sessionLocked ? AppColors.error : null,
            ),
            onPressed: () => setState(() => _sessionLocked = !_sessionLocked),
            tooltip: _sessionLocked ? 'Unlock chat' : 'Lock chat',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'archive') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat archived')));
              } else if (value == 'delete') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Chat'),
                    content: const Text('Are you sure you want to delete this chat?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Lock banner
          if (_sessionLocked)
            Container(
              width: double.infinity,
              color: AppColors.error.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  const Text('Chat is locked — input disabled', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: msgs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text('No messages yet — say hello!', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) {
                      final m = msgs[i];
                      final mine = m['sender_id'] == user?.id;

                      // Date separator
                      final showDate = i == 0 ||
                          !_sameDay(DateTime.parse(msgs[i - 1]['created_at']), DateTime.parse(m['created_at']));

                      return Column(
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                DateFormat('EEEE, d MMM').format(DateTime.parse(m['created_at'])),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ),
                          GestureDetector(
                            onLongPress: () => _showMessageOptions(context, m),
                            child: Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? const Color(0xFF22C55E)
                                      : (isDark ? const Color(0xFF2C2C3E) : Colors.white),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(mine ? 18 : 4),
                                    bottomRight: Radius.circular(mine ? 4 : 18),
                                  ),
                                  border: mine
                                      ? null
                                      : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m['content'], style: TextStyle(color: mine ? Colors.white : null)),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          DateFormat('HH:mm').format(DateTime.parse(m['created_at'])),
                                          style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.grey),
                                        ),
                                        if (mine) ...[
                                          const SizedBox(width: 4),
                                          Text('✓✓', style: TextStyle(fontSize: 11, color: m['read'] == true ? Colors.white : Colors.white60)),
                                        ],

                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Edit indicator
          if (_editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.sunsetBright.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16, color: AppColors.sunsetBright),
                  const SizedBox(width: 8),
                  const Text('Editing message', style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  TextButton(onPressed: _cancelEdit, child: const Text('Cancel', style: TextStyle(fontSize: 12))),
                ],
              ),
            ),

          // Input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !_sessionLocked,
                    decoration: InputDecoration(
                      hintText: _sessionLocked ? 'Chat locked' : 'Type message',
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sessionLocked ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showMessageOptions(BuildContext context, Map<String, dynamic> message) {
    final user = Supabase.instance.client.auth.currentUser;
    if (message['sender_id'] != user?.id) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () { Navigator.pop(ctx); _editMessage(message); },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(ctx); _deleteMessage(message); },
            ),
          ],
        ),
        ),
      ),
    );
  }
}
