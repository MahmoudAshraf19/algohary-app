import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/firebase_config.dart';

/// Result of a successful "a newer version exists" check.
class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String packageName;

  /// Direct store link coming from Firestore (optional).
  final String? storeUrl;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.packageName,
    this.storeUrl,
  });
}

/// A version such as `1.0.0+2` split into comparable numbers.
class AppVersion implements Comparable<AppVersion> {
  final List<int> parts; // major.minor.patch...
  final int build;

  const AppVersion(this.parts, this.build);

  /// Accepts `1.0.0+2`, `1.0.0`, `1.1`, `v1.2.3+10`. Returns null if unparsable.
  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('v') || value.startsWith('V')) value = value.substring(1);

    final plus = value.indexOf('+');
    final core = plus >= 0 ? value.substring(0, plus) : value;
    final buildText = plus >= 0 ? value.substring(plus + 1) : '0';

    final parts = <int>[];
    for (final p in core.split('.')) {
      final n = int.tryParse(p.trim());
      if (n == null) return null;
      parts.add(n);
    }
    if (parts.isEmpty) return null;
    return AppVersion(parts, int.tryParse(buildText.trim()) ?? 0);
  }

  @override
  int compareTo(AppVersion other) {
    final length = parts.length > other.parts.length ? parts.length : other.parts.length;
    for (var i = 0; i < length; i++) {
      final a = i < parts.length ? parts[i] : 0;
      final b = i < other.parts.length ? other.parts[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    return build.compareTo(other.build);
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
}

/// Checks whether a newer build than the installed one has been published.
///
/// Source of truth is the Firestore document `settings/Version` (the same one
/// the settings screen already reads). Fields:
///  - `app_version`        : latest published version, e.g. `1.0.0+2` (required)
///  - `android_store_url`  : optional explicit Google Play link
///  - `ios_store_url`      : optional explicit App Store link
///
/// When the store links are missing they are derived automatically:
/// Play Store from the application id, App Store via the iTunes lookup API
/// using the bundle id.
class AppUpdateService {
  AppUpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Returns the update info, or `null` when the app is up to date, the check
  /// is not applicable (web / desktop) or anything fails. Never throws.
  Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final current = AppVersion.tryParse('${info.version}+${info.buildNumber}');

      final doc = await FirebaseConfig.firestore
          .collection('settings')
          .doc('Version')
          .get()
          .timeout(const Duration(seconds: 8));
      final data = doc.data();
      if (data == null) return null;

      final latestRaw = data['app_version']?.toString();
      final latest = AppVersion.tryParse(latestRaw);
      if (current == null || latest == null) return null;
      if (!(latest > current)) return null;

      final isIos = defaultTargetPlatform == TargetPlatform.iOS;
      final explicitUrl =
          (isIos ? data['ios_store_url'] : data['android_store_url'])?.toString();

      return AppUpdateInfo(
        currentVersion: '${info.version}+${info.buildNumber}',
        latestVersion: latestRaw!.trim(),
        packageName: info.packageName,
        storeUrl: (explicitUrl != null && explicitUrl.trim().isNotEmpty)
            ? explicitUrl.trim()
            : null,
      );
    } catch (e) {
      debugPrint('AppUpdateService.checkForUpdate failed: $e');
      return null;
    }
  }

  /// Opens the store page of the app. Returns `false` if it could not be opened.
  Future<bool> openStore(AppUpdateInfo info) async {
    try {
      final url = info.storeUrl ?? await _resolveStoreUrl(info.packageName);
      if (url == null) return false;
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('AppUpdateService.openStore failed: $e');
      return false;
    }
  }

  Future<String?> _resolveStoreUrl(String packageName) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://play.google.com/store/apps/details?id=$packageName';
    }
    // iOS: look the app up by bundle id.
    final response = await _dio.get<dynamic>(
      'https://itunes.apple.com/lookup',
      queryParameters: {'bundleId': packageName},
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    );
    final body = response.data;
    final json = body is String ? jsonDecode(body) : body;
    if (json is Map && json['resultCount'] is int && (json['resultCount'] as int) > 0) {
      final first = (json['results'] as List).first as Map;
      final url = first['trackViewUrl']?.toString();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }
}
