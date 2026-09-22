import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../pages/notifications_screen.dart';

class NotificationDropdownWidget extends StatefulWidget {
  final VoidCallback onClose;
  const NotificationDropdownWidget({super.key, required this.onClose});

  @override
  State<NotificationDropdownWidget> createState() => _NotificationDropdownWidgetState();
}

class _NotificationDropdownWidgetState extends State<NotificationDropdownWidget> {
  final NotificationService _notificationService = NotificationService();

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}m';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.notificationsTitle ?? 'Notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _notificationService.markAllAsRead();
                      widget.onClose();
                    },
                    child: Text(
                      l10n.markAllAsRead ?? 'Mark all read',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: StreamBuilder<List<AppNotification>>(
                stream: _notificationService.streamNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final notifications = snapshot.data ?? [];
                  if (notifications.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          l10n.noNotifications ?? 'No notifications yet',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  }

                  // Take up to 5 for dropdown
                  final displayList = notifications.take(5).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final notif = displayList[index];
                      return ListTile(
                        onTap: () {
                          _notificationService.markAsRead(notif.id);
                          widget.onClose();
                          // Navigate to chat if CHAT_MESSAGE
                          if (notif.type == 'CHAT_MESSAGE' && notif.referenceId != null) {
                            // TODO: Add route to chat
                          }
                        },
                        tileColor: notif.isRead ? null : colorScheme.primaryContainer.withOpacity(0.3),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          backgroundImage: notif.senderAvatar != null && notif.senderAvatar!.startsWith('http')
                              ? CachedNetworkImageProvider(notif.senderAvatar!)
                              : null,
                          child: notif.senderAvatar == null ? const Icon(Icons.person, size: 20) : null,
                        ),
                        title: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          notif.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          _timeAgo(notif.createdAt),
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: () {
                widget.onClose();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: Center(
                  child: Text(
                    l10n.seeAll ?? 'See All',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
