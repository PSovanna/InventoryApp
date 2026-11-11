import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:catalog_app/catalog_service.dart';

void main() {
  final service = CatalogService();
  test('Image refresh changes the URL while preserving the storage path', () {
    final first = Uri.parse(
      service.imageUrl('categories/photo.jpg', revision: 1),
    );
    final refreshed = Uri.parse(
      service.imageUrl('categories/photo.jpg', revision: 2),
    );
    expect(first.path, '/storage/categories/photo.jpg');
    expect(refreshed.path, first.path);
    expect(refreshed.queryParameters['v'], '2');
    expect(refreshed, isNot(first));
  });
  test('Uses Laravel resource routes for categories and products', () {
    expect(service.endpoint('category').path, '/api/categories');
    expect(service.endpoint('category', 3).path, '/api/categories/3');
    expect(service.endpoint('product').path, '/api/products');
    expect(service.endpoint('product', 7).path, '/api/products/7');
  });
  test('Accepts both product arrays and category envelopes', () {
    expect(
      service.decode(http.Response('[{"product_id":1}]', 200)),
      isA<List>(),
    );
    expect(
      service.decode(http.Response('{"success":true,"data":[]}', 200))['data'],
      isEmpty,
    );
  });
  test('Reports validation and category conflict errors', () {
    expect(
      () => service.decode(
        http.Response('{"errors":{"price":["Invalid price"]}}', 422),
      ),
      throwsA(predicate((e) => e.toString().contains('Invalid price'))),
    );
    expect(
      () => service.decode(
        http.Response(
          '{"success":false,"message":"Category linked to products"}',
          409,
        ),
      ),
      throwsA(
        predicate((e) => e.toString().contains('Category linked to products')),
      ),
    );
  });
  test('Reports non JSON failures', () {
    expect(
      () => service.decode(http.Response('<html>Error</html>', 500)),
      throwsException,
    );
  });
}
