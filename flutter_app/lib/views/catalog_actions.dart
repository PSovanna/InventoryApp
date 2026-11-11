import 'package:flutter/material.dart';

class CatalogActions extends StatelessWidget {
  const CatalogActions({super.key, required this.kind, required this.onAdd});
  final String kind;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onAdd,
    icon: const Icon(Icons.add),
    label: Text('Add $kind'),
  );
}
