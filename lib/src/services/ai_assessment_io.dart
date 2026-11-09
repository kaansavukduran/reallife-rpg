import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _endpoint = String.fromEnvironment('AI_API_URL');
const aiConfigured = _endpoint != '';

Future<Map<String, Object?>> assessPractice(
  String skill,
  String evidence,
) async {
  final uri = Uri.tryParse(_endpoint);
  if (uri == null ||
      !(uri.scheme == 'https' ||
          (uri.scheme == 'http' &&
              ['127.0.0.1', 'localhost', '10.0.2.2'].contains(uri.host)))) {
    throw const FormatException(
      'AI_API_URL güvenilir bir HTTPS değerlendirme adresi olmalı.',
    );
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    return await (() async {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'skill': skill, 'evidence': evidence}));
      final response = await req.close();
      if (response.statusCode != 200) {
        throw FormatException(
          'Değerlendirme servisi yanıtı: ${response.statusCode}',
        );
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > 65536) {
          throw const FormatException('Değerlendirme yanıtı çok büyük');
        }
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Geçersiz değerlendirme yanıtı');
      }
      return decoded;
    })().timeout(const Duration(seconds: 75));
  } on TimeoutException {
    throw const FormatException(
      'Değerlendirme zaman aşımına uğradı. Yanıtın kaybolmadı; yeniden deneyebilirsin.',
    );
  } finally {
    client.close(force: true);
  }
}
