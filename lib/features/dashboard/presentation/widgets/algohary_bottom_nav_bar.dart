import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:algohary_project/features/chat/data/services/chat_service.dart';
import 'package:algohary_project/features/chat/data/models/chat_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_state.dart';

class AlgoharyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AlgoharyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = (authState is AuthSuccess) ? authState.user.id : null;

    return StreamBuilder<List<ConversationModel>>(
      stream: ChatService(injectedUserId: userId).streamConversations(),
      builder: (context, snapshot) {
        int unreadChats = 0;
        if (snapshot.hasData) {
          for (var conv in snapshot.data!) {
            if (conv.unreadCount > 0) {
              unreadChats += 1;
            }
          }
        }
        return _buildNavBar(context, unreadChats);
      },
    );
  }

  Widget _buildNavBar(BuildContext context, int totalUnread) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final bgColor = theme.colorScheme.surface;
    final activeColor = theme.brightness == Brightness.dark ? AppColors.lightYellow : theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.5);
    final activeBg = (theme.brightness == Brightness.dark ? AppColors.lightYellow : theme.colorScheme.primary).withOpacity(0.1);

    final items = <_NavItem>[
      _NavItem(
        label: l10n.navHome,
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
      ),
      _NavItem(
        label: l10n.navBookings,
        activeIcon: Icons.calendar_month_rounded,
        inactiveIcon: Icons.calendar_month_outlined,
      ),
      _NavItem(
        label: l10n.navMessages,
        activeIcon: Icons.chat_bubble_rounded,
        inactiveIcon: Icons.chat_bubble_outline_rounded,
        hasBadge: totalUnread > 0,
        badgeCount: totalUnread,
      ),
      _NavItem(
        label: l10n.navProfile,
        activeIcon: Icons.person_rounded,
        inactiveIcon: Icons.person_outline_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 6,
              bottom: bottomInset > 0 ? bottomInset + 6 : 8,
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(index),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      scale: selected ? 1.0 : 0.98,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: selected ? 12 : 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? activeBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Stack(
                                key: ValueKey<String>('${selected}_${item.hasBadge}_${item.badgeCount}'),
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    selected ? item.activeIcon : item.inactiveIcon,
                                    size: 23,
                                    color: selected ? activeColor : inactiveColor,
                                  ),
                                  if (item.hasBadge)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: bgColor, width: 1.5),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            item.badgeCount > 9 ? '+9' : item.badgeCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                style: TextStyle(
                                  fontSize: 11.0, // slightly smaller to fit 5 items comfortably
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? activeColor : inactiveColor,
                                ),
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool hasBadge;
  final int badgeCount;

  _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.hasBadge = false,
    this.badgeCount = 0,
  });
}
