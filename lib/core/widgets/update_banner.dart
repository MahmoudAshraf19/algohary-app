import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';

/// A floating "new version available" card.
///
/// * Checks the store version once when it is first built; renders nothing
///   when the app is up to date (or the check fails).
/// * Slides in from the *start* edge of the screen: left → right in LTR
///   (English) and right → left in RTL (Arabic).
/// * Stays visible for [visibleFor], showing a thin countdown bar, then slides
///   away on its own.
/// * The user can swipe it away at any time (either direction). Touching /
///   dragging it pauses the countdown.
/// * The button opens Google Play / the App Store.
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({
    super.key,
    this.visibleFor = const Duration(seconds: 8),
    this.service,
  });

  final Duration visibleFor;
  final AppUpdateService? service;

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> with TickerProviderStateMixin {
  late final AppUpdateService _service = widget.service ?? AppUpdateService();

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    reverseDuration: const Duration(milliseconds: 450),
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: widget.visibleFor,
  );

  AppUpdateInfo? _info;
  bool _gone = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _countdown.addStatusListener((status) {
      if (status == AnimationStatus.completed) _autoHide();
    });
    _load();
  }

  Future<void> _load() async {
    final info = await _service.checkForUpdate();
    if (!mounted || info == null) return;
    setState(() => _info = info);
    HapticFeedback.selectionClick();
    _ambient.repeat();
    await _enter.forward();
    if (mounted && !_gone) _countdown.forward();
  }

  Future<void> _autoHide() async {
    if (!mounted || _gone) return;
    await _enter.reverse();
    if (mounted) setState(() => _gone = true);
  }

  Future<void> _openStore(AppLocalizations l10n) async {
    if (_info == null || _opening) return;
    _opening = true;
    _countdown.stop();
    HapticFeedback.mediumImpact();
    final ok = await _service.openStore(_info!);
    _opening = false;
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      if (!_gone) _countdown.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _ambient.dispose();
    _countdown.dispose();
    super.dispose();
  }

  void _onDrag(DismissUpdateDetails details) {
    // Pause the auto-hide timer while the user is holding / dragging the card.
    if (details.progress > 0.0) {
      if (_countdown.isAnimating) _countdown.stop();
    } else if (!_countdown.isAnimating && !_countdown.isCompleted && _enter.isCompleted) {
      _countdown.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_info == null || _gone) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Enter from the start edge: left in LTR, right in RTL.
    final slide = Tween<Offset>(
      begin: Offset(isRtl ? 1.3 : -1.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enter,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));
    final fade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: Dismissible(
          key: const ValueKey('app-update-banner'),
          direction: DismissDirection.horizontal,
          onUpdate: _onDrag,
          onDismissed: (_) {
            HapticFeedback.selectionClick();
            if (mounted) setState(() => _gone = true);
          },
          child: _buildCard(context, l10n),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppLocalizations l10n) {
    final radius = BorderRadius.circular(24);

    return Semantics(
      container: true,
      label: l10n.updateAvailableMessage,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Stack(
              children: [
                // Base gradient (positioned so only the content sizes the card)
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [Color(0xFF335C67), Color(0xFF1F3C45), Color(0xFF2B4B55)],
                      ),
                    ),
                  ),
                ),
                // Soft warm glow in the corner
                PositionedDirectional(
                  top: -40,
                  end: -30,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.orange.withValues(alpha: 0.55), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                // Light sweep ("magic" shimmer)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _ambient,
                      builder: (context, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(-1, -0.4),
                            end: const Alignment(1, 0.4),
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.16),
                              Colors.transparent,
                            ],
                            stops: const [0.35, 0.5, 0.65],
                            transform: _SweepTransform(_ambient.value),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Glass border
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 20),
                  child: Row(
                    children: [
                      _buildIcon(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.updateAvailableMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  'v${_info!.latestVersion}',
                                  style: TextStyle(
                                    color: AppColors.lightYellow.withValues(alpha: 0.95),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildButton(l10n),
                    ],
                  ),
                ),
                // Countdown bar (how long until the card hides itself)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _countdown,
                    builder: (context, _) => LinearProgressIndicator(
                      value: 1 - _countdown.value,
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, child) {
        final t = math.sin(_ambient.value * 2 * math.pi);
        return Stack(
          alignment: Alignment.center,
          children: [
            // Breathing halo
            Container(
              width: 52 + 6 * t.abs(),
              height: 52 + 6 * t.abs(),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withValues(alpha: 0.10 + 0.10 * t.abs()),
              ),
            ),
            Transform.translate(offset: Offset(0, -2.5 * t), child: child),
          ],
        );
      },
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2B866), AppColors.orange],
          ),
        ),
        child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 25),
      ),
    );
  }

  Widget _buildButton(AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => _openStore(l10n),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.updateNow,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_outward_rounded, size: 16, color: AppColors.primaryBlue),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slides a gradient horizontally so a highlight band sweeps across the card.
class _SweepTransform extends GradientTransform {
  const _SweepTransform(this.progress);

  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * 2 * (progress - 0.5);
    return Matrix4.translationValues(dx, 0, 0);
  }
}
