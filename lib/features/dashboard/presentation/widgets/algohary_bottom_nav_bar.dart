import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final bgColor = theme.colorScheme.surface;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.5);
    final activeBg = theme.colorScheme.primary.withOpacity(0.1);

    final items = <_NavItem>[
      _NavItem(
        label: l10n.navHome,
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
      ),
      _NavItem(
        label: l10n.navExplore,
        activeIcon: Icons.explore_rounded,
        inactiveIcon: Icons.explore_outlined,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -5), // Upward shadow
          ),
        ],
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
                              child: Icon(
                                selected ? item.activeIcon : item.inactiveIcon,
                                key: ValueKey<bool>(selected),
                                size: 23,
                                color: selected ? activeColor : inactiveColor,
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

  _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}
