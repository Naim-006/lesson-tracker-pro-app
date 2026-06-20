import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(instructorNotificationsProvider);
    final unreadCount = notifications.value?.where((n) => !n['read']).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: unreadCount == 0
                ? null
                : () => _markAllRead(ref),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.value == null || notifications.value!.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.value!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = notifications.value![i];
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Card(
                  child: ListTile(
                    onTap: () => _markAsRead(ref, n['id']),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.sunsetBright.withValues(alpha: 0.15),
                      child: Icon(
                        n['read'] ? Icons.notifications_none : Icons.notifications,
                        color: AppColors.sunsetBright,
                      ),
                    ),
                    title: Text(
                      n['title'],
                      style: TextStyle(
                        fontWeight: n['read'] ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(n['body']),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('d MMM • HH:mm').format(DateTime.parse(n['created_at'])),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: n['read']
                        ? null
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.sunsetBright,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _markAsRead(WidgetRef ref, String id) async {
    try {
      await Supabase.instance.client
          .from('app_notifications')
          .update({'read': true})
          .eq('id', id);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _markAllRead(WidgetRef ref) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('app_notifications')
          .update({'read': true})
          .eq('user_id', user.id)
          .eq('read', false);
    } catch (e) {
      // Handle error
    }
  }
}

