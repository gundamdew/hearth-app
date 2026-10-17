// lib/widgets/hearth_pulse_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../providers/notifications_provider.dart';

class HearthPulseDrawer extends ConsumerWidget {
  final AppUser currentUser;

  const HearthPulseDrawer({
    super.key,
    required this.currentUser,
  });

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('d MMM').format(dateTime);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'budget':
        return Icons.account_balance_wallet_outlined;
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'meals':
        return Icons.soup_kitchen_outlined;
      case 'cleaning':
        return Icons.auto_awesome_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'budget':
        return AppTheme.indigo;
      case 'inventory':
        return AppTheme.terra;
      case 'meals':
        return AppTheme.amber;
      case 'cleaning':
        return AppTheme.teal;
      default:
        return AppTheme.moss;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final notifications = notificationsAsync.value ?? [];
    final unreadCount = notifications
        .where((n) => !n.readBy.contains(currentUser.name))
        .length;

    return Drawer(
      width: 400,
      backgroundColor: AppTheme.canvas,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drawer Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ACTIVITY FEED', style: AppTheme.microStyle),
                          const SizedBox(height: 2),
                          Text('Hearth Pulse', style: AppTheme.titleStyle(fontSize: 24)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: AppTheme.muted),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: unreadCount > 0
                              ? AppTheme.danger.withValues(alpha: 0.12)
                              : AppTheme.stone,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unreadCount > 0 ? '$unreadCount UNREAD' : 'ALL READ',
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: unreadCount > 0 ? AppTheme.danger : AppTheme.muted,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: unreadCount == 0
                            ? null
                            : () {
                                ref.read(notificationControllerProvider).markAllAsRead(
                                      currentUser.name,
                                      notifications,
                                    );
                              },
                        icon: const Icon(Icons.done_all, size: 16),
                        label: Text(
                          'Mark all as read',
                          style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.moss,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Notifications List Area
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.moss),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Błąd wczytywania powiadomień: $err',
                      style: GoogleFonts.instrumentSans(color: AppTheme.danger),
                    ),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: AppTheme.muted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'All quiet in Hearth',
                            style: AppTheme.titleStyle(fontSize: 20, color: AppTheme.muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No recent activity logged yet.',
                            style: GoogleFonts.instrumentSans(fontSize: 13, color: AppTheme.muted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final isUnread = !item.readBy.contains(currentUser.name);
                      final categoryColor = _getCategoryColor(item.category);
                      final categoryIcon = _getCategoryIcon(item.category);

                      return InkWell(
                        onTap: () {
                          if (isUnread) {
                            ref
                                .read(notificationControllerProvider)
                                .markAsRead(item.id, currentUser.name);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? AppTheme.surface
                                : AppTheme.surface.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUnread
                                  ? categoryColor.withValues(alpha: 0.45)
                                  : AppTheme.line,
                              width: isUnread ? 1.5 : 1,
                            ),
                            boxShadow: isUnread
                                ? [
                                    BoxShadow(
                                      color: const Color.fromRGBO(30, 32, 29, 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Icon Avatar
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  categoryIcon,
                                  size: 18,
                                  color: categoryColor,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Notification Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: GoogleFonts.instrumentSans(
                                              fontSize: 14,
                                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                              color: AppTheme.ink,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isUnread)
                                          Container(
                                            width: 7,
                                            height: 7,
                                            margin: const EdgeInsets.only(left: 6),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.danger,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.body,
                                      style: GoogleFonts.instrumentSans(
                                        fontSize: 13,
                                        color: isUnread ? AppTheme.ink : AppTheme.muted,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatRelativeTime(item.createdAt),
                                          style: GoogleFonts.dmMono(
                                            fontSize: 11,
                                            color: AppTheme.muted,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.stone,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.actorName,
                                            style: GoogleFonts.instrumentSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
