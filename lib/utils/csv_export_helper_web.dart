import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Export CSV sur le web via Blob + téléchargement navigateur
class CsvExportHelper {
  /// Exporte un contenu CSV en déclenchant un téléchargement dans le navigateur
  static Future<void> exportCsv(String csvContent, String filename, String subject) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final bytes = utf8.encode(csvContent);
    final jsArray = bytes.toJS;
    final blob = web.Blob([jsArray].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8'));
    final url = web.URL.createObjectURL(blob);

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = '${filename}_$timestamp.csv'
      ..style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
    web.URL.revokeObjectURL(url);
  }
}
