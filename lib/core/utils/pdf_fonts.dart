import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;

/// Loads Unicode-capable fonts for PDF generation (web + mobile).
class PdfFonts {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<pw.Font> regular() async {
    _regular ??= await _loadTtf(
      'https://fonts.gstatic.com/s/roboto/v32/KFOmCnqEu92Fr1Me5WZLCzYlKw.ttf',
    );
    return _regular!;
  }

  static Future<pw.Font> bold() async {
    _bold ??= await _loadTtf(
      'https://fonts.gstatic.com/s/roboto/v32/KFOlCnqEu92Fr1MmWUlvAx05IsDqlA.ttf',
    );
    return _bold!;
  }

  static Future<pw.Font> _loadTtf(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load PDF font ($url)');
    }
    return pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(response.bodyBytes)));
  }
}
