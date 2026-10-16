import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/dashboard/data/models/category_model.dart';
import '../utils/map_l10n_ext.dart';
import '../utils/map_palette.dart';

class MapTopBar extends StatelessWidget {
  final String locationLabel;
  final int onlineCount;
  final bool isLoading;
  final int activeFilters;
  final double radiusKm;
  final VoidCallback onFiltersTap;
  final VoidCallback? onLocationTap;
  final List<CategoryModel> categories;
  final Map<String, int> categoryCounts;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const MapTopBar({
    super.key,
    required this.locationLabel,
    required this.onlineCount,
    required this.isLoading,
    required this.activeFilters,
    required this.radiusKm,
    required this.onFiltersTap,
    this.onLocationTap,
    required this.categories,
    required this.categoryCounts,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories
        .where((c) =>
            (categoryCounts[c.id] ?? 0) > 0 || c.id == selectedCategoryId)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _LocationPill(
                  label: locationLabel,
                  onlineCount: onlineCount,
                  isLoading: isLoading,
                  radiusKm: radiusKm,
                  onTap: onLocationTap,
                ),
              ),
              const SizedBox(width: 10),
              _FilterButton(count: activeFilters, onTap: onFiltersTap),
            ],
          ),
        ),
        if (visibleCategories.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: visibleCategories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final l10n = AppLocalizations.of(context)!;
                if (index == 0) {
                  return _CategoryChip(
                    label: l10n.filterAll,
                    selected: selectedCategoryId == null,
                    onTap: () => onCategorySelected(null),
                  );
                }
                final category = visibleCategories[index - 1];
                final lang = Localizations.localeOf(context).languageCode;
                return _CategoryChip(
                  label: category.localizedName(lang),
                  count: categoryCounts[category.id],
                  selected: category.id == selectedCategoryId,
                  onTap: () => onCategorySelected(category.id),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationPill extends StatelessWidget {
  final String label;
  final int onlineCount;
  final bool isLoading;
  final double radiusKm;
  final VoidCallback? onTap;

  const _LocationPill({
    required this.label,
    required this.onlineCount,
    required this.isLoading,
    required this.radiusKm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MapPalette.of(context);
    final l10n = AppLocalizations.of(context)!;

    final String radiusSubtitle = radiusKm.isInfinite
        ? ''
        : ' (${l10n.mapRadiusKm(radiusKm.toInt())})';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 52,
          padding: const EdgeInsetsDirectional.only(start: 8, end: 14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.near_me_rounded,
              size: 19,
              color: palette.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: palette.muted,
                        ),
                      )
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: onlineCount > 0
                              ? MapPalette.online
                              : palette.muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          isLoading
                              ? l10n.mapSearching
                              : '${l10n.mapOnlineCount(onlineCount)}$radiusSubtitle',
                          key: ValueKey('$isLoading-$onlineCount-$radiusKm'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.muted,
                            height: 1.2,
                          ),
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
  ),
);
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = MapPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final active = count > 0;

    return Tooltip(
      message: l10n.mapFilters,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: active ? palette.accent : palette.surface,
            elevation: 4,
            shadowColor: palette.shadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: palette.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  Icons.tune_rounded,
                  color: active ? palette.onAccent : palette.accent,
                ),
              ),
            ),
          ),
          if (active)
            PositionedDirectional(
              top: -4,
              end: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: palette.highlight,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MapPalette.of(context);
    final fg = selected ? palette.onAccent : palette.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? palette.accent : palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? palette.accent : palette.border,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: selected ? 0.5 : 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                  ),
                ),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
