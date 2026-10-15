import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/dashboard/data/models/category_model.dart';
import '../../data/models/map_provider.dart';
import '../utils/map_l10n_ext.dart';
import '../utils/map_palette.dart';

/// Height reserved for the carousel (also used for the map's bottom padding).
const double kMapCarouselHeight = 140;

class MapProviderAvatar extends StatelessWidget {
  final String imageUrl;
  final String initials;
  final double size;
  final bool showOnlineDot;

  const MapProviderAvatar({
    super.key,
    required this.imageUrl,
    required this.initials,
    required this.size,
    this.showOnlineDot = true,
  });

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F8696), AppColors.primaryBlue],
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MapPalette.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: imageUrl.trim().isEmpty
                ? _fallback()
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    memCacheWidth: (size * 3).round(),
                    placeholder: (_, __) => _fallback(),
                    errorWidget: (_, __, ___) => _fallback(),
                  ),
          ),
          if (showOnlineDot)
            PositionedDirectional(
              end: 1,
              bottom: 1,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(
                  color: MapPalette.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.surface, width: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MapProviderCard extends StatelessWidget {
  final MapProvider provider;
  final String? categoryName;
  final bool selected;
  final VoidCallback onTap;

  const MapProviderCard({
    super.key,
    required this.provider,
    required this.categoryName,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MapPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final servicesCount = provider.user.services?.length ?? 0;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final name =
        provider.fullName.isEmpty ? l10n.mapProviderFallbackName : provider.fullName;

    return Semantics(
      button: true,
      label: '$name, ${l10n.mapViewDetails}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? palette.accent : palette.border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  MapProviderAvatar(
                    imageUrl: provider.user.imageUrl,
                    initials: provider.initials,
                    size: 64,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: palette.onSurface,
                            height: 1.2,
                          ),
                        ),
                        if (categoryName != null && categoryName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            categoryName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: palette.muted,
                              height: 1.2,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _InfoChip(
                                icon: Icons.near_me_rounded,
                                label: formatMapDistance(
                                  l10n,
                                  provider.distanceMeters,
                                ),
                                color: palette.accent,
                              ),
                              const SizedBox(width: 6),
                              _InfoChip(
                                icon: Icons.circle,
                                iconSize: 7,
                                label: l10n.mapOnlineBadge,
                                color: MapPalette.online,
                              ),
                              if (servicesCount > 0) ...[
                                const SizedBox(width: 6),
                                _InfoChip(
                                  icon: Icons.handyman_rounded,
                                  label: l10n.mapServicesCount(servicesCount),
                                  color: palette.muted,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRtl
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20,
                      color: palette.onAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Swipeable list of the visible providers, kept in sync with the map.
class MapProviderCarousel extends StatefulWidget {
  final List<MapProvider> providers;
  final String? selectedId;
  final List<CategoryModel> categories;

  /// The user swiped to a provider.
  final ValueChanged<MapProvider> onSwiped;

  /// The user tapped a provider card.
  final ValueChanged<MapProvider> onOpen;

  const MapProviderCarousel({
    super.key,
    required this.providers,
    required this.selectedId,
    required this.categories,
    required this.onSwiped,
    required this.onOpen,
  });

  @override
  State<MapProviderCarousel> createState() => _MapProviderCarouselState();
}

class _MapProviderCarouselState extends State<MapProviderCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  bool _dragging = false;
  bool _programmatic = false;

  @override
  void didUpdateWidget(covariant MapProviderCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragging) return;

    final target =
        widget.providers.indexWhere((p) => p.id == widget.selectedId);
    if (target < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients || _dragging) return;
      final current = _controller.page?.round() ?? 0;
      if (current == target) return;
      _programmatic = true;
      _controller.jumpToPage(target);
      WidgetsBinding.instance.addPostFrameCallback((_) => _programmatic = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _dragging = true;
    } else if (n is ScrollEndNotification) {
      _dragging = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final categoriesById = {for (final c in widget.categories) c.id: c};

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.providers.length,
        onPageChanged: (index) {
          if (_programmatic || index >= widget.providers.length) return;
          HapticFeedback.selectionClick();
          widget.onSwiped(widget.providers[index]);
        },
        itemBuilder: (context, index) {
          final provider = widget.providers[index];
          final category = categoriesById[provider.user.categoryId];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            child: MapProviderCard(
              provider: provider,
              categoryName: category?.localizedName(lang),
              selected: provider.id == widget.selectedId,
              onTap: () => widget.onOpen(provider),
            ),
          );
        },
      ),
    );
  }
}

/// Placeholder shown while the first batch of providers loads.
class MapProviderCarouselSkeleton extends StatelessWidget {
  const MapProviderCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MapPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Skeletonizer(
        enabled: true,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Provider name here', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Category name', style: TextStyle(fontSize: 13)),
                    SizedBox(height: 10),
                    Text('1.2 km  •  Online', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
