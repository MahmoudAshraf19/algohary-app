import 'dart:async';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'map_palette.dart';

/// Everything that affects how a provider marker looks. [key] is the cache key.
class ProviderMarkerSpec {
  final String id;
  final String imageUrl;
  final String initials;
  final bool selected;
  final bool isDark;
  final double devicePixelRatio;

  const ProviderMarkerSpec({
    required this.id,
    required this.imageUrl,
    required this.initials,
    required this.selected,
    required this.isDark,
    required this.devicePixelRatio,
  });

  String get key =>
      '$id|$imageUrl|$selected|$isDark|${devicePixelRatio.toStringAsFixed(1)}';
}

/// Renders map markers to bitmaps and caches them.
///
/// * Provider markers: a circle with the provider's photo (or initials when
///   there is no photo / it failed to load), a ring and an "online" dot.
/// * User marker: rendered from an inline SVG.
class MapMarkerFactory {
  static const double baseSize = 50;
  static const double selectedSize = 64;
  static const double _padding = 10;
  static const int _maxCacheEntries = 240;

  final Map<String, BitmapDescriptor> _icons = {};
  final Map<String, Future<BitmapDescriptor?>> _inflight = {};

  String? _userIconKey;
  BitmapDescriptor? _userIcon;

  /// Synchronous lookup. `null` while the icon is still being rendered.
  BitmapDescriptor? peek(ProviderMarkerSpec spec) => _icons[spec.key];

  /// Renders (or returns the cached) icon. Never throws; returns `null` if the
  /// bitmap could not be produced.
  Future<BitmapDescriptor?> build(ProviderMarkerSpec spec) {
    final cached = _icons[spec.key];
    if (cached != null) return Future.value(cached);
    return _inflight[spec.key] ??=
        _render(spec).whenComplete(() => _inflight.remove(spec.key));
  }

  Future<BitmapDescriptor?> _render(ProviderMarkerSpec spec) async {
    ui.Image? avatar;
    try {
      avatar = await _loadAvatar(spec.imageUrl);
      final descriptor = await _paintProvider(spec, avatar);
      _icons[spec.key] = descriptor;
      _trimCache();
      return descriptor;
    } catch (e) {
      debugPrint('MapMarkerFactory: failed to render marker ${spec.id}: $e');
      return null;
    } finally {
      avatar?.dispose();
    }
  }

  void _trimCache() {
    while (_icons.length > _maxCacheEntries) {
      _icons.remove(_icons.keys.first);
    }
  }

  Future<ui.Image?> _loadAvatar(String url) async {
    if (url.trim().isEmpty) return null;

    final provider = ResizeImage(CachedNetworkImageProvider(url), width: 160);
    final stream = provider.resolve(ImageConfiguration.empty);
    final completer = Completer<ui.Image?>();
    var timedOut = false;

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (timedOut || completer.isCompleted) return;
        completer.complete(info.image.clone());
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    stream.addListener(listener);
    try {
      return await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          timedOut = true;
          return null;
        },
      );
    } finally {
      stream.removeListener(listener);
    }
  }

  Future<BitmapDescriptor> _paintProvider(
    ProviderMarkerSpec spec,
    ui.Image? avatar,
  ) async {
    final dpr = spec.devicePixelRatio;
    final diameter = spec.selected ? selectedSize : baseSize;
    final total = diameter + _padding * 2;
    final radius = diameter / 2;
    final center = Offset(total / 2, total / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);

    // Halo for the selected marker.
    if (spec.selected) {
      canvas.drawCircle(
        center,
        radius + 7,
        Paint()..color = AppColors.orange.withOpacity(0.28),
      );
    }

    // Soft shadow.
    canvas.drawCircle(
      center.translate(0, 2),
      radius,
      Paint()
        ..color = Colors.black.withOpacity(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Ring.
    final ringColor = spec.selected
        ? AppColors.orange
        : (spec.isDark ? const Color(0xFF1B2733) : Colors.white);
    canvas.drawCircle(center, radius, Paint()..color = ringColor);

    // Avatar / fallback.
    final border = spec.selected ? 3.5 : 3.0;
    final avatarRect = Rect.fromCircle(center: center, radius: radius - border);

    canvas.save();
    canvas.clipPath(Path()..addOval(avatarRect));
    if (avatar != null) {
      final w = avatar.width.toDouble();
      final h = avatar.height.toDouble();
      final side = w < h ? w : h;
      final src = Rect.fromLTWH((w - side) / 2, (h - side) / 2, side, side);
      canvas.drawImageRect(
        avatar,
        src,
        avatarRect,
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium,
      );
    } else {
      canvas.drawRect(
        avatarRect,
        Paint()
          ..shader = ui.Gradient.linear(
            avatarRect.topLeft,
            avatarRect.bottomRight,
            const [Color(0xFF4F8696), AppColors.primaryBlue],
          ),
      );
      final painter = TextPainter(
        text: TextSpan(
          text: spec.initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.72,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            fontFamilyFallback: const ['IBMPlexSansArabic'],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        center - Offset(painter.width / 2, painter.height / 2),
      );
      painter.dispose();
    }
    canvas.restore();

    // Online dot.
    final dotRadius = spec.selected ? 8.0 : 7.0;
    final dotCenter = center + Offset(radius * 0.72, radius * 0.72);
    canvas.drawCircle(dotCenter, dotRadius + 2, Paint()..color = ringColor);
    canvas.drawCircle(dotCenter, dotRadius, Paint()..color = MapPalette.online);

    return _toDescriptor(recorder, total, dpr);
  }

  /// The user's location marker, rendered from an inline SVG.
  Future<BitmapDescriptor?> userLocationIcon({
    required Color primary,
    required Color accent,
    required double devicePixelRatio,
  }) async {
    final key = '$primary|$accent|${devicePixelRatio.toStringAsFixed(1)}';
    if (_userIcon != null && _userIconKey == key) return _userIcon;

    PictureInfo? info;
    try {
      info = await vg.loadPicture(
        SvgStringLoader(_userLocationSvg(_hex(primary), _hex(accent))),
        null,
      );

      const logicalSize = 64.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(
        logicalSize * devicePixelRatio / info.size.width,
        logicalSize * devicePixelRatio / info.size.height,
      );
      canvas.drawPicture(info.picture);

      final descriptor =
          await _toDescriptor(recorder, logicalSize, devicePixelRatio);
      _userIcon = descriptor;
      _userIconKey = key;
      return descriptor;
    } catch (e) {
      debugPrint('MapMarkerFactory: failed to render user marker: $e');
      return null;
    } finally {
      info?.picture.dispose();
    }
  }

  Future<BitmapDescriptor> _toDescriptor(
    ui.PictureRecorder recorder,
    double logicalSize,
    double dpr,
  ) async {
    final picture = recorder.endRecording();
    final pixels = (logicalSize * dpr).ceil();
    final image = await picture.toImage(pixels, pixels);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (data == null) {
      throw StateError('Could not encode marker bitmap');
    }
    return BitmapDescriptor.bytes(
      data.buffer.asUint8List(),
      width: logicalSize,
      height: logicalSize,
    );
  }

  static String _hex(Color c) =>
      '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static String _userLocationSvg(String primary, String accent) => '''
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
  <circle cx="48" cy="48" r="46" fill="$primary" fill-opacity="0.16"/>
  <circle cx="48" cy="48" r="32" fill="$primary" fill-opacity="0.26"/>
  <circle cx="48" cy="48" r="21" fill="#FFFFFF"/>
  <circle cx="48" cy="48" r="16" fill="$accent"/>
  <path d="M48 37.5 L57 58 L48 52.8 L39 58 Z" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="1.5" stroke-linejoin="round"/>
</svg>
''';
}
