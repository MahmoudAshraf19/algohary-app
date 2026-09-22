import 'package:flutter/material.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/service_repository.dart';
import 'service_card.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../pages/service_details_screen.dart';

class PopularServicesSection extends StatefulWidget {
  const PopularServicesSection({super.key});

  @override
  State<PopularServicesSection> createState() => _PopularServicesSectionState();
}

class _PopularServicesSectionState extends State<PopularServicesSection> {
  final ServiceRepository _repository = ServiceRepository();
  late Future<List<ServiceModel>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _repository.getPopularServices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<ServiceModel>>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final mockService = ServiceModel(
            id: 'mock',
            categoryId: 'mock',
            nameAr: 'جاري التحميل جاري التحميل',
            nameEn: 'Loading Loading',
            descriptionAr: 'وصف الخدمة يكتب هنا',
            descriptionEn: 'Service description goes here',
            available: true,
            imageUrl: '',
            showInHome: true,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homePopularServicesTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return ServiceCard(
                      service: mockService,
                      onTap: () {},
                    );
                  },
                ),
              ),
            ],
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final services = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homePopularServicesTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              itemBuilder: (context, index) {
                return ServiceCard(
                  service: services[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailsScreen(service: services[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
