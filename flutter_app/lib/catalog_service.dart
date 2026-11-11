import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'category_service.dart';

class CatalogService {
  Uri endpoint(String kind, [Object? id]) => Uri.parse(
    '${CategoryService.baseUrl.replaceFirst(RegExp(r"/+$"), "")}/${kind == 'category' ? 'categories' : 'products'}${id == null ? "" : "/$id"}',
  );

  dynamic decode(http.Response response) {
    final dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid API response (${response.statusCode}).');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        (body is Map && body['success'] == false)) {
      final errors = body is Map ? body['errors'] : null;
      throw Exception(
        errors is Map
            ? errors.values.expand((v) => v is List ? v : [v]).join('\n')
            : body is Map
            ? body['message'] ?? 'Request failed.'
            : 'Request failed.',
      );
    }
    return body;
  }

  Future<List<Map<String, dynamic>>> list(String kind) async {
    final body = decode(
      await http
          .get(
            endpoint(kind).replace(
              queryParameters: {
                '_refresh': '${DateTime.now().microsecondsSinceEpoch}',
              },
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20)),
    );
    return ((body is List ? body : body['data']) as List)
        .cast<Map<String, dynamic>>();
  }

  Future<void> save(
    String kind,
    Map<String, String> fields, {
    Object? id,
    Uint8List? image,
    String? filename,
  }) async {
    final request = http.MultipartRequest('POST', endpoint(kind, id))
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields);
    if (id != null) request.fields['_method'] = 'PUT';
    if (image != null) {
      request.files.add(
        http.MultipartFile.fromBytes('image', image, filename: filename),
      );
    }
    final client = http.Client();
    try {
      decode(
        await (() async => http.Response.fromStream(
          await client.send(request),
        ))().timeout(const Duration(seconds: 30)),
      );
    } finally {
      client.close();
    }
  }

  Future<void> delete(String kind, Object id) async {
    decode(
      await http
          .delete(endpoint(kind, id), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20)),
    );
  }

  String imageUrl(String path, {int? revision}) {
    final url = Uri.parse(
      '${CategoryService.baseUrl.replaceFirst(RegExp(r"/api/?$"), "")}/storage/$path',
    );
    return revision == null
        ? url.toString()
        : url.replace(queryParameters: {'v': '$revision'}).toString();
  }
}
