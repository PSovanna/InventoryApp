import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CategoryService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  Uri get _categories =>
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/categories');

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'The API returned an invalid response (${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      final errors = body['errors'];
      final message = errors is Map
          ? errors.values
                .expand((value) => value is List ? value : [value])
                .join('\n')
          : body['message'] ?? 'Request failed (${response.statusCode}).';
      throw Exception(message);
    }
    return body;
  }

  Future<List<Map<String, dynamic>>> list() async {
    final response = await http
        .get(_categories, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    return (_decode(response)['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> add({
    required String name,
    required String description,
    Uint8List? image,
    String? filename,
  }) async {
    final request = http.MultipartRequest('POST', _categories)
      ..headers['Accept'] = 'application/json'
      ..fields['category_name'] = name
      ..fields['description'] = description;
    if (image != null) {
      request.files.add(
        http.MultipartFile.fromBytes('image', image, filename: filename),
      );
    }
    final client = http.Client();
    try {
      final response = await (() async {
        return http.Response.fromStream(await client.send(request));
      })().timeout(const Duration(seconds: 30));
      _decode(response);
    } finally {
      client.close();
    }
  }
}
