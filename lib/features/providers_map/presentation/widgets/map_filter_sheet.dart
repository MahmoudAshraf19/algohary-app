import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/dashboard/data/models/service_model.dart';
import '../cubit/providers_map_cubit.dart';
import '../cubit/providers_map_state.dart';
import '../utils/map_l10n_ext.dart';
import '../utils/map_palette.dart';

/// Opens the filter sheet. The sheet lives in its own route, so the cubit is
/// re-provided explicitly.
Future<void> showMapFilterSheet(
  BuildContext context,
  ProvidersMapCubit cubit,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _MapFilterSheet(),
    ),
  );
}

class _MapFilterSheet extends StatefulWidget {
  const _MapFilterSheet();

  @override
  State<_MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<_MapFilterSheet> {
  late MapFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = context.read<ProvidersMapCubit>().state.filters;
  }

  void _selectCategory(String? id) {
    HapticFeedback.selectionClick();
    setState(() {
      _draft = (id == null || id == _draft.categoryId)
          ? _draft.copyWith(clearCategory: true, serviceIds: const <String>{})
          : _draft.copyWith(categoryId: id, serviceIds: const <String>{});
    });
  }

  void _toggleService(String id) {
    HapticFeedback.selectionClick();
    final next = Set<String>.of(_draft.serviceIds);
    if (!next.remove(id)) next.add(id);
    setState(() => _draft = _draft.copyWith(serviceIds: next));
  }

  void _apply() {
    context.read<ProvidersMapCubit>().applyFilters(_draft);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MapPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final cubit = context.read<ProvidersMapCubit>();
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<ProvidersMapCubit, ProvidersMapState>(
      buildWhen: (a, b) =>
          a.categories != b.categories ||
          a.services != b.services ||
          a.categoryCounts != b.categoryCounts,
      builder: (context, state) {
        final List<ServiceModel> servicesOfCategory = _draft.categoryId == null
            ? const <ServiceModel>[]
            : state.services
                .where((s) => s.categoryId == _draft.categoryId)
                .toList();
        final resultCount = cubit.countFor(_draft);

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.muted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.mapFiltersTitle,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: palette.onSurface,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _draft.isDefault
                          ? null
                          : () => setState(() => _draft = const MapFilters()),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.accent,
                      ),
                      child: Text(
                        l10n.mapFilterReset,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(l10n.mapFilterRadius),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final km in MapFilters.radiusOptionsKm)
                            _OptionChip(
                              label: km.isInfinite
                                  ? l10n.mapRadiusAny
                                  : l10n.mapRadiusKm(km.toInt()),
                              selected: _draft.radiusKm == km,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(
                                  () => _draft = _draft.copyWith(radiusKm: km),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _SectionTitle(l10n.mapFilterCategories),
                      if (state.categories.isEmpty)
                        _HintText(l10n.mapFilterNoCategories)
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _OptionChip(
                              label: l10n.filterAll,
                              selected: _draft.categoryId == null,
                              onTap: () => _selectCategory(null),
                            ),
                            for (final c in state.categories)
                              _OptionChip(
                                label: c.localizedName(lang),
                                count: state.categoryCounts[c.id],
                                selected: _draft.categoryId == c.id,
                                onTap: () => _selectCategory(c.id),
                              ),
                          ],
                        ),
                      const SizedBox(height: 22),
                      _SectionTitle(l10n.mapFilterServices),
                      if (_draft.categoryId == null)
                        _HintText(l10n.mapFilterServicesHint)
                      else if (servicesOfCategory.isEmpty)
                        _HintText(l10n.mapFilterNoServices)
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in servicesOfCategory)
                              _OptionChip(
                                label: s.localizedName(lang),
                                selected: _draft.serviceIds.contains(s.id),
                                onTap: () => _toggleService(s.id),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + bottomInset),
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border(top: BorderSide(color: palette.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      resultCount == 0
                          ? l10n.mapFilterNoMatch
                          : l10n.mapFilterShowResults(resultCount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = MapPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: palette.onSurface,
        ),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  final String text;

  const _HintText(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = MapPalette.of(context);
    return Text(
      text,
      style: TextStyle(fontSize: 13, color: palette.muted, height: 1.4),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
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
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? palette.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? palette.accent : palette.muted.withOpacity(0.35),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                  ),
                ),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fg.withOpacity(0.7),
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
