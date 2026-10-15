import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/dashboard/data/models/category_model.dart';
import 'package:algohary_project/features/dashboard/data/models/service_model.dart';

extension CategoryLocalizationExt on CategoryModel {
  String localizedName(String lang) {
    if (lang == 'ar' && nameAr.isNotEmpty) return nameAr;
    if (nameEn.isNotEmpty) return nameEn;
    return nameAr;
  }
}

extension ServiceLocalizationExt on ServiceModel {
  String localizedName(String lang) {
    if (lang == 'ar' && nameAr.isNotEmpty) return nameAr;
    if (nameEn.isNotEmpty) return nameEn;
    return nameAr;
  }
}

String formatMapDistance(AppLocalizations l10n, double? distanceMeters) {
  if (distanceMeters == null) return '';
  if (distanceMeters < 1000) {
    return l10n.mapDistanceMeters(distanceMeters.round());
  }
  final km = distanceMeters / 1000.0;
  final formatted = km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
  return l10n.mapDistanceKm(formatted);
}
