import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/service_repository.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../widgets/service_card.dart';
import 'service_details_screen.dart';

class CategoryServicesScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryServicesScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  final ServiceRepository _repository = ServiceRepository();
  late Future<List<ServiceModel>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _repository.getServicesByCategory(widget.category.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? widget.category.nameAr : widget.category.nameEn;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: FutureBuilder<List<ServiceModel>>(
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
            return Skeletonizer(
              enabled: true,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return ServiceCard(
                    service: mockService,
                    onTap: () {},
                  );
                },
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading services'));
          }
          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return const Center(child: Text('No services found in this category'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ServiceCard(
                service: service,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsScreen(service: service),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
