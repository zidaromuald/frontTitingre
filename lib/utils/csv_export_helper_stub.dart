import 'dart:io';
import 'package:share_plus/share_plus.dart';

/// Export CSV sur mobile via dart:io + Share
class CsvExportHelper {
  /// Exporte un contenu CSV en créant un fichier temporaire et en le partageant
  static Future<void> exportCsv(String csvContent, String filename, String subject) async {
    final dir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${filename}_$timestamp.csv');
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
    );
  }
}
