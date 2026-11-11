import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../catalog_service.dart';

class CatalogForm extends StatefulWidget {
  const CatalogForm({
    super.key,
    required this.kind,
    required this.service,
    required this.categories,
    this.record,
  });
  final String kind;
  final CatalogService service;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? record;
  @override
  State<CatalogForm> createState() => _CatalogFormState();
}

class _CatalogFormState extends State<CatalogForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.record?['${widget.kind}_name']?.toString(),
  );
  late final _description = TextEditingController(
    text: widget.record?['description']?.toString(),
  );
  late final _price = TextEditingController(
    text: widget.record?['price']?.toString(),
  );
  late String? _category = widget.record?['category_id']?.toString();
  Uint8List? _image;
  String? _filename;
  String? _error;
  bool _busy = false;
  int _imageRevision = DateTime.now().microsecondsSinceEpoch;
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      if (![
            'jpg',
            'jpeg',
            'png',
            'webp',
          ].contains(file.name.split('.').last.toLowerCase()) ||
          await file.length() > 2048 * 1024) {
        throw Exception('Choose a JPG, PNG or WebP image up to 2 MB.');
      }
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _image = bytes;
          _filename = file.name;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.save(
        widget.kind,
        {
          '${widget.kind}_name': _name.text.trim(),
          'description': _description.text.trim(),
          if (widget.kind == 'product') ...{
            'category_id': _category!,
            'price': _price.text.trim(),
          },
        },
        id: widget.record?['${widget.kind}_id'],
        image: _image,
        filename: _filename,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text('${widget.record == null ? 'Add' : 'Edit'} ${widget.kind}'),
        actions: [
          if (_image == null && widget.record?['image'] != null)
            IconButton(
              tooltip: 'Refresh image',
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _imageRevision = DateTime.now().microsecondsSinceEpoch;
                    }),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextFormField(
                controller: _name,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a name'
                    : v.trim().runes.length >
                          (widget.kind == 'product' ? 100 : 50)
                    ? 'Name is too long'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                enabled: !_busy,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              if (widget.kind == 'product') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue:
                      widget.categories.any(
                        (c) => c['category_id'].toString() == _category,
                      )
                      ? _category
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: widget.categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['category_id'].toString(),
                          child: Text(c['category_name'].toString()),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _category = v),
                  validator: (v) => v == null ? 'Select a category' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _price,
                  enabled: !_busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (v) {
                    final price = double.tryParse(v?.trim() ?? '');
                    return price == null ||
                            !price.isFinite ||
                            price < 0 ||
                            price > 99999999.99
                        ? 'Enter a price from 0 to 99999999.99'
                        : null;
                  },
                ),
              ],
              const SizedBox(height: 20),
              if (_image != null)
                Image.memory(_image!, height: 140, fit: BoxFit.contain)
              else if (widget.record?['image'] != null)
                Image.network(
                  widget.service.imageUrl(
                    widget.record!['image'].toString(),
                    revision: _imageRevision,
                  ),
                  key: ValueKey(_imageRevision),
                  height: 140,
                  errorBuilder: (_, e, s) => const Icon(Icons.broken_image),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.image),
                label: const Text('Choose Image'),
              ),
              const Text(
                'JPG, PNG or WebP, up to 2 MB. Leave unchanged to keep the current image.',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Please wait…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
