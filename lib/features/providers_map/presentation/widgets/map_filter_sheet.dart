import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/dashboard/data/models/service_model.dart';
import '../cubit/providers_map_cubit.dart';
import '../cubit/providers_map_state.dart';
import '../utils/map_l10n_ext.dart';
import '../utils/map_palette.dart';

/// Raw SVG string for the infinity icon so it never fails asset bundling or HTTP fetches.
const String _infinitySvgRaw = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="100%" height="100%"><path fill="currentColor" d="M501.98,206.15c-9.769-23.023-25.998-42.56-46.458-56.389c-10.181-6.873-21.446-12.34-33.536-16.068c-12.009-3.809-24.842-5.798-38.088-5.798c-16.982,0-33.294,3.316-48.197,9.365c-1.246,0.492-2.402,0.986-3.558,1.568c-13.416,5.879-25.675,14.16-36.188,24.017c-3.396,3.227-6.623,6.623-9.858,10.432c-5.709,6.542-11.588,14.079-17.305,21.696c-1.157,1.568-2.402,3.226-3.558,4.804c-3.146,4.302-33.212,48.358-38.509,56.226c-2.652,3.97-5.798,8.442-9.195,13.327c-0.744,1.076-1.568,2.24-2.393,3.396c-5.636,8.031-11.928,16.481-17.726,23.937c-2.895,3.72-5.798,7.197-8.281,10.1c-2.563,2.976-4.884,5.378-6.542,6.954c-7.116,6.704-15.486,12.171-24.672,15.899c-9.194,3.728-19.214,5.798-29.816,5.798c-7.286,0-14.322-0.996-20.944-2.815c-3.396-0.913-6.712-2.07-9.939-3.477c-14.248-5.968-26.419-16.068-34.95-28.74c-4.302-6.372-7.699-13.327-10.019-20.783c-2.233-7.456-3.558-15.316-3.558-23.597c0-11.014,2.24-21.365,6.21-30.892c6.049-14.24,16.149-26.329,28.821-34.942c6.372-4.31,13.326-7.618,20.782-9.939c7.448-2.321,15.316-3.638,23.597-3.638c10.602,0.08,20.622,2.07,29.816,5.79c9.187,3.808,17.556,9.194,24.672,15.898c1.658,1.577,3.979,4.059,6.542,6.962c4.472,5.216,9.769,11.92,15.074,18.964c2.07,2.814,4.14,5.628,6.21,8.523c7.949-11.588,21.858-31.959,29.144-42.48c-1.237-1.658-2.482-3.307-3.72-4.965c-3.316-4.23-6.631-8.281-9.938-12.009c-3.316-3.809-6.462-7.205-9.858-10.432c-11.426-10.772-24.922-19.545-39.746-25.586c-14.904-6.049-31.222-9.365-48.196-9.365c-17.637,0-34.53,3.566-49.927,10.108c-23.022,9.688-42.487,25.918-56.316,46.369c-6.873,10.19-12.332,21.527-16.141,33.536C1.989,229.997,0,242.75,0,256.004c0,17.637,3.558,34.53,10.02,49.846c9.768,23.104,25.998,42.569,46.369,56.397c10.27,6.874,21.535,12.332,33.624,16.141c12.008,3.728,24.842,5.717,38.088,5.717c16.974,0,33.293-3.316,48.196-9.356c14.824-6.049,28.239-14.824,39.666-25.506l0.08-0.081c3.397-3.146,6.543-6.631,9.858-10.44c5.709-6.542,11.588-14.071,17.305-21.689c1.157-1.577,2.402-3.154,3.558-4.723c3.146-4.391,44.307-64.758,47.696-69.642c0.752-1.076,1.577-2.232,2.401-3.396c5.637-7.95,11.928-16.48,17.726-23.928c2.895-3.728,5.798-7.206,8.281-10.101c2.564-2.984,4.885-5.386,6.542-6.962c7.116-6.704,15.486-12.09,24.673-15.898c2.24-0.906,4.472-1.649,6.792-2.402c7.286-2.15,14.984-3.307,23.023-3.388c11.013,0.08,21.446,2.232,30.882,6.291c14.241,5.96,26.42,16.06,34.943,28.732c4.31,6.38,7.706,13.335,10.019,20.782c2.321,7.456,3.566,15.324,3.566,23.605c0,11.014-2.24,21.446-6.21,30.883c-6.049,14.24-16.149,26.419-28.821,34.942c-6.372,4.31-13.326,7.707-20.782,9.939c-7.367,2.321-15.316,3.648-23.597,3.648c-10.602,0-20.622-2.07-29.816-5.798c-9.187-3.728-17.557-9.195-24.673-15.899c-1.658-1.577-3.979-4.059-6.542-6.954c-4.472-5.135-9.776-11.928-15.074-18.963c-2.15-2.815-4.221-5.718-6.291-8.613c-0.663,0.994-1.326,1.99-2.07,3.065c-13.666,20.039-22.279,32.71-26.994,39.576c1.237,1.658,2.483,3.235,3.72,4.893c3.316,4.221,6.631,8.281,9.938,12c3.234,3.808,6.462,7.294,9.858,10.44c11.426,10.763,24.923,19.538,39.746,25.587c14.904,6.04,31.215,9.356,48.197,9.356c17.636,0,34.53-3.558,49.846-10.019c23.103-9.769,42.56-25.999,56.396-46.458c6.866-10.181,12.421-21.446,16.141-33.536C510.01,282.083,512,269.25,512,256.004C512,238.367,508.442,221.474,501.98,206.15z"/></svg>''';

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

        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
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
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(l10n.mapFilterRadius),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final km in MapFilters.radiusOptionsKm)
                              _OptionChip(
                                label: km.isInfinite
                                    ? null
                                    : l10n.mapRadiusKm(km.toInt()),
                                selected: _draft.radiusKm == km,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(
                                    () => _draft = _draft.copyWith(radiusKm: km),
                                  );
                                },
                                child: km.isInfinite
                                    ? Builder(
                                        builder: (context) {
                                          final isSelected =
                                              _draft.radiusKm == km;
                                          final color = isSelected
                                              ? palette.onAccent
                                              : palette.onSurface;
                                          return SizedBox(
                                            width: 22,
                                            height: 16,
                                            child: SvgPicture.string(
                                              _infinitySvgRaw,
                                              fit: BoxFit.contain,
                                              colorFilter: ColorFilter.mode(
                                                color,
                                                BlendMode.srcIn,
                                              ),
                                              placeholderBuilder: (_) => Icon(
                                                Icons.all_inclusive_rounded,
                                                size: 20,
                                                color: color,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : null,
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border(top: BorderSide(color: palette.border)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
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
  final String? label;
  final Widget? child;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    this.label,
    this.child,
    required this.selected,
    required this.onTap,
    this.count,
  }) : assert(label != null || child != null);

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
                if (child != null)
                  child!
                else
                  Text(
                    label!,
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
