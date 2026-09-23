import 'package:flutter/material.dart';
import 'package:algohary_project/core/widgets/custom_search_bar.dart';
import 'package:algohary_project/l10n/app_localizations.dart';

class SelectionItem {
  final String id;
  final String name;

  SelectionItem({required this.id, required this.name});
}

class SelectionBottomSheet extends StatefulWidget {
  final String title;
  final List<SelectionItem> items;

  const SelectionBottomSheet({
    Key? key,
    required this.title,
    required this.items,
  }) : super(key: key);

  static Future<SelectionItem?> show(BuildContext context, {required String title, required List<SelectionItem> items}) {
    return showModalBottomSheet<SelectionItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectionBottomSheet(title: title, items: items),
    );
  }

  @override
  State<SelectionBottomSheet> createState() => _SelectionBottomSheetState();
}

class _SelectionBottomSheetState extends State<SelectionBottomSheet> {
  String _searchQuery = '';
  late List<SelectionItem> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomSearchBar(
              hintText: l10n?.searchPlace ?? 'Search...',
              onChanged: _onSearch,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // List
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      l10n?.placeNotFound ?? 'No results found',
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary, size: 22),
                              ),
                              title: Text(
                                item.name, 
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onTap: () {
                                Navigator.pop(context, item);
                              },
                            ),
                          ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
