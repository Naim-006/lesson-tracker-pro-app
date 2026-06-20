import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

class AdminChatReplyScreen extends StatefulWidget {
  const AdminChatReplyScreen({
    super.key,
    required this.instructorId,
    required this.instructorName,
  });

  final String instructorId;
  final String instructorName;

  @override
  State<AdminChatReplyScreen> createState() => _AdminChatReplyScreenState();
}

class _AdminChatReplyScreenState extends State<AdminChatReplyScreen> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('id, sender_id, receiver_id, content, created_at')
          .or('and(sender_id.eq.${widget.instructorId},receiver_id.eq.${user.id}),and(sender_id.eq.${user.id},receiver_id.eq.${widget.instructorId})')
          .order('created_at', ascending: false)
          .limit(200);

      setState(() {
        _messages = (response)
            .toList()
            ..sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': widget.instructorId,
        'content': text,
      });
      _input.clear();
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.instructorName),
        backgroundColor: AppColors.navy,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkMuted : Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No messages yet. Reply to start the conversation.',
                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkMuted : Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isAdmin = msg['sender_id'] == user?.id;
                          return _buildBubble(msg, isAdmin);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightCard,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.navy,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isAdmin) {
    final content = msg['content'] as String? ?? '';
    final time = msg['created_at'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(msg['created_at']))
        : '';

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAdmin ? AppColors.navy : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardElevated : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAdmin ? 16 : 4),
            bottomRight: Radius.circular(isAdmin ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(content, style: TextStyle(color: isAdmin ? Colors.white : Colors.black87, fontSize: 15)),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: isAdmin ? Colors.white70 : Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
