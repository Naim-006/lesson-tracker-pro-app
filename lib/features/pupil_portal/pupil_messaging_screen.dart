import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../activity/chat_screen.dart';

class PupilMessagingScreen extends StatefulWidget {
  const PupilMessagingScreen({super.key});

  @override
  State<PupilMessagingScreen> createState() => _PupilMessagingScreenState();
}

class _PupilMessagingScreenState extends State<PupilMessagingScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? _instructor;
  String? _lastMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final link = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', user!.id)
          .eq('status', 'active')
          .maybeSingle();
      if (link == null) { if (mounted) setState(() => _isLoading = false); return; }

      final instructorId = link['instructor_id'] as String;
      final instructor = await Supabase.instance.client
          .from('profiles')
          .select('full_name, business_name')
          .eq('id', instructorId)
          .maybeSingle();

      String? lastMsg;
      try {
        final last = await Supabase.instance.client
            .from('messages')
            .select('content, created_at')
            .or('and(sender_id.eq.$instructorId,receiver_id.eq.${user!.id}),and(sender_id.eq.${user!.id},receiver_id.eq.$instructorId)')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        lastMsg = last?['content']?.toString();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _instructor = instructor ?? {'full_name': 'Instructor'};
          _instructor!['id'] = instructorId;
          _lastMessage = lastMsg;
          _isLoading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  void _openChat() {
    if (_instructor == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(pupilId: _instructor!['id'], pupilName: _instructor!['full_name'] ?? 'Instructor'),
    )).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF7F5F2),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.sunsetBright,
            foregroundColor: Colors.white,
            title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w800)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28))),
              ),
            ),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.sunsetBright)))
          else if (_instructor == null)
            SliverFillRemaining(child: _errorWidget())
          else ...[
            SliverToBoxAdapter(child: _chatCard(isDark)),
            SliverToBoxAdapter(child: _infoCard(isDark)),
          ],
        ],
      ),
    );
  }

  Widget _chatCard(bool isDark) {
    final name = _instructor!['full_name'] as String? ?? 'Instructor';
    final business = _instructor!['business_name'] as String?;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: InkWell(
        onTap: _openChat,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)),
                child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1),
                    if (business != null) Text(business, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)), maxLines: 1),
                    const SizedBox(height: 4),
                    Text(_lastMessage ?? 'Tap to start chatting', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.chat_rounded, color: Colors.white, size: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 20)),
              const SizedBox(width: 10),
              const Text('Chat with your instructor', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            Text('Send messages to your instructor about lessons, scheduling, or any questions.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('Open Chat'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('Could not load messages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey.shade500)), const SizedBox(height: 16), FilledButton.tonalIcon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Retry'))]));
  }
}