import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

export 'chat_screen.dart';
import 'chat_screen.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.sunsetBright,
            unselectedLabelColor: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            indicatorColor: AppColors.sunsetBright,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: const [
              Tab(text: 'MESSAGES'),
              Tab(text: 'UPDATES'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _MessagesTab(onNewThread: _startNewThread),
              const _UpdatesTab(),
            ],
          ),
        ),
      ],
    );
  }

  void _startNewThread() {
    final instructorPupils = ref.read(instructorPupilsProvider);

    final pupils = instructorPupils.value?.map((link) {
      final pupilData = link['pupils'];
      final profile = pupilData?['profiles'];
      return Pupil(
        id: pupilData['id'],
        firstName: profile?['full_name']?.split(' ').first ?? '',
        lastName: profile?['full_name']?.split(' ').last ?? '',
        phone: profile?['phone'] ?? '',
        email: profile?['email'] ?? '',
        postcode: pupilData['postcode'],
        pickupAddresses:
            pupilData['address'] != null ? [pupilData['address']] : [],
        outstandingBalance: 0.0,
      );
    }).toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('New Message',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: pupils.length,
                  itemBuilder: (_, i) {
                    final p = pupils[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.sunsetBright,
                            child: Text(
                              p.initials,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text(p.fullName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                    pupilId: p.id, pupilName: p.fullName),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesTab extends ConsumerWidget {
  const _MessagesTab({required this.onNewThread});
  final VoidCallback onNewThread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(instructorMessagesProvider);
    final user = Supabase.instance.client.auth.currentUser;

    if (messages.value == null || messages.value!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.lightMuted),
            const SizedBox(height: 16),
            Text('No conversations yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightMuted)),
            const SizedBox(height: 8),
            Text('Start a conversation with a pupil',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.lightMuted)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNewThread,
              icon: const Icon(Icons.add),
              label: const Text('New conversation'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sunsetBright,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      );
    }

    final Map<String, List<Map<String, dynamic>>> conversations = {};
    for (final msg in messages.value!) {
      final otherId = msg['sender_id'] == user?.id
          ? msg['receiver_id']
          : msg['sender_id'];
      if (!conversations.containsKey(otherId)) {
        conversations[otherId] = [];
      }
      conversations[otherId]!.add(msg);
    }

    final conversationIds = conversations.keys.toList();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async { ref.invalidate(instructorMessagesProvider); },
          child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: conversationIds.length,
          itemBuilder: (context, i) {
            final otherId = conversationIds[i];
            final msgs = conversations[otherId]!;
            msgs.sort((a, b) =>
                DateTime.parse(b['created_at'])
                    .compareTo(DateTime.parse(a['created_at'])));
            final last = msgs.first;
            final unread = msgs
                .where((m) => m['receiver_id'] == user?.id && !m['read'])
                .length;
            final otherName = last['sender_id'] == user?.id
                ? (last['receiver']?['full_name'] ?? 'Unknown')
                : (last['sender']?['full_name'] ?? 'Unknown');

            final initials =
                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';
            final time =
                DateFormat('HH:mm').format(DateTime.parse(last['created_at']));

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(pupilId: otherId, pupilName: otherName)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.sunsetBright,
                          radius: 26,
                          child: Text(
                            initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(otherName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16)),
                                  ),
                                  Text(time,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.lightMuted)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      last['content'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.lightMuted),
                                    ),
                                  ),
                                  if (unread > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.sunsetBright,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
          ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: onNewThread,
            backgroundColor: AppColors.sunsetBright,
            elevation: 4,
            mini: false,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}

class _UpdatesTab extends ConsumerWidget {
  const _UpdatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(instructorNotificationsProvider);
    final lastSync = DateTime.now().subtract(const Duration(minutes: 5));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.sunsetBright.withValues(alpha: 0.05),
            border: Border(
                bottom: BorderSide(
                    color: AppColors.sunsetBright.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              Icon(Icons.sync, size: 16, color: AppColors.sunsetBright),
              const SizedBox(width: 8),
              Text(
                  'Last sync: ${DateFormat('HH:mm').format(lastSync)}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.sunsetBright)),
              const Spacer(),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Syncing...')),
                  );
                },
                child: Text('Sync now',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sunsetBright)),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async { ref.invalidate(instructorNotificationsProvider); },
            child: notifications.value == null || notifications.value!.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
                            const SizedBox(height: 16),
                            Text('No updates yet',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkText : AppColors.lightText)),
                            const SizedBox(height: 8),
                            Text('Activity updates will appear here',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: notifications.value!.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text('RECENT ACTIVITY',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.lightMuted,
                                letterSpacing: 1.2)),
                      );
                    }
                    final a = notifications.value![i - 1];
                    final dateText = DateFormat('d MMM')
                        .format(DateTime.parse(a['created_at']));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.sunsetBright.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.notifications,
                                    size: 22, color: AppColors.sunsetBright),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a['title'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(
                                      a['body'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.lightMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBorder,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  dateText,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
        ),
      ],
    );
  }
}
