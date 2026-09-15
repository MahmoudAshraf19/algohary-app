import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../pages/all_categories_screen.dart';

class CategoriesRow extends StatefulWidget {
  const CategoriesRow({super.key});

  @override
  State<CategoriesRow> createState() => _CategoriesRowState();
}

class _CategoriesRowState extends State<CategoriesRow> {
  final CategoryRepository _repository = CategoryRepository();
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _repository.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.homePopularServices,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () async {
                final categories = await _categoriesFuture;
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllCategoriesScreen(categories: categories),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.homeViewAll,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Horizontal List
        SizedBox(
          height: 110,
          child: FutureBuilder<List<CategoryModel>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox();
              }

              var categories = snapshot.data!;
              
              // Add "All" category at the beginning
              final allCategory = CategoryModel(
                id: 'all',
                nameAr: l10n.categoryAll,
                nameEn: l10n.categoryAll,
                available: true,
                imageUrl: '',
                isAll: true,
              );
              
              // Only take top 5, so with "All" it becomes 6
              final displayCategories = [allCategory, ...categories.take(5)];

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: displayCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return CategoryItem(
                    category: displayCategories[index],
                    index: index,
                    onTap: (cat) {
                      if (cat.isAll) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllCategoriesScreen(categories: categories),
                          ),
                        );
                      } else {
                        // Show snackbar for now
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Clicked: ${cat.nameEn}')),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final int index;
  final Function(CategoryModel) onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.index,
    required this.onTap,
  });

  Color _getRingColor(ThemeData theme) {
    // A unified, light shade of the primary color in light mode (and dark shade in dark mode)
    return theme.colorScheme.primaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final name = isAr ? category.nameAr : category.nameEn;
    final theme = Theme.of(context);
    final ringColor = _getRingColor(theme);

    return InkWell(
      onTap: () => onTap(category),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ringColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _CategoryIcon(category: category),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final CategoryModel category;

  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The icon color will be a strong primary color (dark in light mode, light in dark mode)
    final iconColor = theme.colorScheme.onPrimaryContainer;

    if (category.isAll) {
      return SvgPicture.asset(
        'assets/icons/category.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }

    final iconUrl = category.imageUrl;

    if (iconUrl.isEmpty) {
      return Icon(Icons.category, color: iconColor, size: 24);
    }

    // Use contains instead of endsWith because Firebase Storage URLs have tokens at the end
    if (iconUrl.contains('.svg')) {
      return SvgPicture.network(
        iconUrl,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        placeholderBuilder: (_) => const SizedBox(
          width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      return Image.network(
        iconUrl,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.category, color: iconColor, size: 24),
      );
    }
  }
}
