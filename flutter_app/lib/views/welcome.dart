import 'package:flutter/material.dart';
import '../catalog_service.dart';
import '../category_service.dart';
import 'add_category.dart';
import 'catalog_form.dart';
import 'catalog_actions.dart';
import 'catalog_row_actions.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final service = CatalogService();
  late Future<List<List<Map<String, dynamic>>>> data;
  String kind = 'product', query = '';
  String? category;
  int imageRevision = DateTime.now().microsecondsSinceEpoch;
  @override
  void initState() {
    super.initState();
    data = load();
  }

  Future<List<List<Map<String, dynamic>>>> load() =>
      Future.wait([service.list('product'), service.list('category')]);
  void reload() => setState(() {
    imageRevision = DateTime.now().microsecondsSinceEpoch;
    data = load();
  });
  Future<void> edit(
    List<Map<String, dynamic>> categories, [
    Map<String, dynamic>? record,
  ]) async {
    final addingCategory = kind == 'category' && record == null;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => addingCategory
            ? AddCategoryPage(service: CategoryService())
            : CatalogForm(
                kind: kind,
                service: service,
                categories: categories,
                record: record,
              ),
      ),
    );
    if (mounted && saved == true) {
      reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            addingCategory
                ? 'Category added successfully!'
                : 'Item saved successfully!',
          ),
        ),
      );
    }
  }

  Future<void> remove(Map<String, dynamic> record) async {
    final selectedKind = kind;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${record['${selectedKind}_name']}?'),
        content: Text(
          selectedKind == 'product'
              ? 'The product will be hidden from the menu.'
              : 'This permanently removes the category. Categories linked to products cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await service.delete(selectedKind, record['${selectedKind}_id']);
      if (mounted) reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Menu overview'),
      actions: [
        TextButton.icon(
          onPressed: reload,
          label: const Text('Refresh'),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: kind == 'product' ? 0 : 1,
      onDestinationSelected: (i) => setState(() {
        kind = i == 0 ? 'product' : 'category';
        category = null;
      }),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu),
          label: 'Products',
        ),
        NavigationDestination(icon: Icon(Icons.category), label: 'Categories'),
      ],
    ),
    body: FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Unable to load catalog.\n${snapshot.error}'),
                TextButton(onPressed: reload, child: const Text('Retry')),
              ],
            ),
          );
        }
        final products = snapshot.data![0], categories = snapshot.data![1];
        final average = products.isEmpty
            ? 0.0
            : products.fold<double>(
                    0,
                    (sum, p) =>
                        sum + (double.tryParse(p['price'].toString()) ?? 0),
                  ) /
                  products.length;
        final records = (kind == 'product' ? products : categories)
            .where(
              (r) =>
                  '${r['${kind}_name']} ${r['description'] ?? ''}'
                      .toLowerCase()
                      .contains(query.toLowerCase()) &&
                  (kind != 'product' ||
                      category == null ||
                      r['category_id'].toString() == category),
            )
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${products.length} products • ${categories.length} categories\nAverage price: ${average.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: const InputDecoration(
                      labelText: 'Search catalog',
                    ),
                  ),
                  if (kind == 'product')
                    DropdownButton<String>(
                      isExpanded: true,
                      value:
                          categories.any(
                            (c) => c['category_id'].toString() == category,
                          )
                          ? category
                          : null,
                      hint: const Text('All categories'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All categories'),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem(
                            value: c['category_id'].toString(),
                            child: Text(c['category_name'].toString()),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => category = v),
                    ),
                  CatalogActions(kind: kind, onAdd: () => edit(categories)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  reload();
                  await data;
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: records.isEmpty ? 1 : records.length,
                  itemBuilder: (_, index) {
                    if (records.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No matching items.'),
                      );
                    }
                    final r = records[index];
                    return ListTile(
                      leading: r['image'] == null
                          ? const Icon(Icons.image_outlined)
                          : Image.network(
                              service.imageUrl(
                                r['image'].toString(),
                                revision: imageRevision,
                              ),
                              key: ValueKey(
                                '${kind}_${r['${kind}_id']}_${r['image']}_$imageRevision',
                              ),
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) =>
                                  const Icon(Icons.broken_image),
                            ),
                      title: Text(r['${kind}_name'].toString()),
                      subtitle: Text(
                        [
                          if (kind == 'product')
                            '${r['category']?['category_name'] ?? ''} • ${r['price']}',
                          r['description']?.toString() ?? '',
                        ].join('\n'),
                      ),
                      trailing: CatalogRowActions(
                        onEdit: () => edit(categories, r),
                        onDelete: () => remove(r),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
