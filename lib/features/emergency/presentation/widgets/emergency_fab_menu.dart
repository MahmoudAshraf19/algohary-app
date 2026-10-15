import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/emergency_service_item.dart';
import '../../data/repositories/emergency_repository.dart';

class EmergencyFabMenu extends StatefulWidget {
  const EmergencyFabMenu({super.key});

  @override
  State<EmergencyFabMenu> createState() => _EmergencyFabMenuState();
}

class _EmergencyFabMenuState extends State<EmergencyFabMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;
  final EmergencyRepository _repository = EmergencyRepository();
  bool _isOpen = false;

  static const String _emergencyCallIconUrl =
      'https://firebasestorage.googleapis.com/v0/b/naslookapp-ecf15.firebasestorage.app/o/Emergency_icons%2Femergency-call.svg?alt=media&token=70ae0553-2601-4c46-a8de-c43e579a8d90';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  Future<void> _callNumber(String number) async {
    _close();
    final Uri telUri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch tel:$number: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;

    // Harmonious theme-tailored styling
    final fabBgColor = isDark ? const Color(0xFFC93B3B) : const Color(0xFFD63031);
    final itemBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final itemTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final badgeBgColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      clipBehavior: Clip.none,
      children: [
        // Modal barrier to close menu when tapping outside
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),

        // Stream emergency items and build vertical list
        StreamBuilder<List<EmergencyServiceItem>>(
          stream: _repository.streamEmergencyServices(),
          initialData: EmergencyRepository.defaultItems,
          builder: (context, snapshot) {
            final items = snapshot.data ?? EmergencyRepository.defaultItems;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // List of Emergency items with staggered animations
                ...List.generate(items.length, (index) {
                  // Invert index so the bottom item animates first
                  final reversedIndex = items.length - 1 - index;
                  final item = items[reversedIndex];

                  final start = (index * 0.15).clamp(0.0, 0.7);
                  final end = (start + 0.35).clamp(0.0, 1.0);

                  final itemAnimation = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(start, end, curve: Curves.easeOutBack),
                    reverseCurve: Interval(0.0, 0.8, curve: Curves.easeIn),
                  );

                  final textDirection = Directionality.of(context);
                  final isRtl = textDirection == TextDirection.rtl;

                  return ScaleTransition(
                    scale: itemAnimation,
                    alignment: isRtl ? Alignment.bottomLeft : Alignment.bottomRight,
                    child: FadeTransition(
                      opacity: itemAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildEmergencyItemRow(
                          item: item,
                          locale: locale,
                          itemBgColor: itemBgColor,
                          itemTextColor: itemTextColor,
                          badgeBgColor: badgeBgColor,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  );
                }),

                // Main Floating Action Button
                GestureDetector(
                  onTap: _toggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: _isOpen ? (isDark ? const Color(0xFF9E2A2B) : const Color(0xFFB71C1C)) : fabBgColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isOpen ? Colors.black45 : fabBgColor).withValues(alpha: isDark ? 0.4 : 0.35),
                          blurRadius: 14,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: RotationTransition(
                        turns: _rotationAnimation,
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 220),
                          crossFadeState: _isOpen
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: SvgPicture.network(
                            _emergencyCallIconUrl,
                            width: 28,
                            height: 28,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            placeholderBuilder: (_) => const Icon(
                              Icons.emergency,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          secondChild: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyItemRow({
    required EmergencyServiceItem item,
    required String locale,
    required Color itemBgColor,
    required Color itemTextColor,
    required Color badgeBgColor,
    required bool isDark,
  }) {
    final title = item.localizedName(locale);

    return InkWell(
      onTap: () => _callNumber(item.contactNumber),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: itemBgColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: item.iconUrl.isNotEmpty
                  ? SvgPicture.network(
                      item.iconUrl,
                      placeholderBuilder: (_) => const Icon(
                        Icons.call,
                        size: 20,
                        color: Color(0xFFD63031),
                      ),
                    )
                  : const Icon(
                      Icons.call,
                      size: 20,
                      color: Color(0xFFD63031),
                    ),
            ),
            const SizedBox(width: 10),

            // Name
            Text(
              title,
              style: TextStyle(
                color: itemTextColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),

            // Number Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.phone_in_talk,
                    size: 13,
                    color: Color(0xFFD63031),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.contactNumber,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Color(0xFFD63031),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
