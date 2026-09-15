import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import '../../data/models/category_model.dart';
import '../widgets/categories_row.dart'; // To reuse CategoryItem if possible, but Grid is slightly different

class AllCategoriesScreen extends StatelessWidget {
  final List<CategoryModel> categories;

  const AllCategoriesScreen({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.allCategoriesTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: categories.isEmpty
          ? Center(
              child: Text(
                l10n.noCategoriesFound,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return CategoryItem(
                  category: category,
                  index: index,
                  onTap: (cat) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: ${cat.nameEn}')),
                    );
                  },
                );
              },
            ),
    );
  }
}
