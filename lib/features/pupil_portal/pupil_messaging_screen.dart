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
    try {
      final linkRes = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', user!.id)
          .eq('status', 'active')
          .maybeSingle();

      if (linkRes == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final instructorId = linkRes['instructor_id'] as String;
      final instructor = await Supabase.instance.client
          .from('profiles')
          .select('full_name, avatar_url, business_name')
          .eq('id', instructorId)
          .maybeSingle();

      // Fetch last message with this instructor
      final lastMsg = await Supabase.instance.client
          .from('messages')
          .select('content, created_at')
          .or('and(sender_id.eq.$instructorId,receiver_id.eq.${user!.id}),and(sender_id.eq.${user!.id},receiver_id.eq.$instructorId)')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _instructor = instructor;
          _instructor!['id'] = instructorId;
          _lastMessage = lastMsg?['content']?.toString();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChat() {
    if (_instructor == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          pupilId: _instructor!['id'],
          pupilName: _instructor!['full_name'] ?? 'Instructor',
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.sunsetBright,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright))
          : _instructor == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Could not load messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: InkWell(
                        onTap: _openChat,
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                              child: Center(
                                child: Text(
                                  (_instructor!['full_name'] as String? ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_instructor!['full_name'] ?? 'Your Instructor',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _lastMessage ?? 'Tap to start chatting',
                                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white.withValues(alpha: 0.7)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.sunsetBright.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.info_outline, color: AppColors.sunsetBright, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text('Chat with your instructor', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Send messages to your instructor about lessons, scheduling, or any questions.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _openChat,
                              icon: const Icon(Icons.chat_rounded, size: 18),
                              label: const Text('Open Chat'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.sunsetBright,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
