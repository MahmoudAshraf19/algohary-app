class EmergencyServiceItem {
  final String id;
  final String nameAr;
  final String nameEn;
  final String contactNumber;
  final String iconUrl;
  final bool isAvailable;

  const EmergencyServiceItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.contactNumber,
    required this.iconUrl,
    required this.isAvailable,
  });

  factory EmergencyServiceItem.fromFirestore(Map<String, dynamic> data, String id) {
    return EmergencyServiceItem(
      id: id,
      nameAr: data['name_ar'] as String? ?? '',
      nameEn: data['name_en'] as String? ?? '',
      contactNumber: data['contact_number'] as String? ?? '',
      iconUrl: data['icon_url'] as String? ?? '',
      isAvailable: data['is_available'] as bool? ?? true,
    );
  }

  String localizedName(String languageCode) {
    if (languageCode == 'ar') {
      return nameAr.isNotEmpty ? nameAr : nameEn;
    }
    return nameEn.isNotEmpty ? nameEn : nameAr;
  }
}
