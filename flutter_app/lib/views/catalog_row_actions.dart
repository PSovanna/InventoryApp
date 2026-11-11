import 'package:flutter/material.dart';

class CatalogRowActions extends StatelessWidget {
  const CatalogRowActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Item actions',
    onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'edit', child: Text('Edit')),
      PopupMenuItem(value: 'delete', child: Text('Delete')),
    ],
  );
}
