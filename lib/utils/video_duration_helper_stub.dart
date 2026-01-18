import 'dart:typed_data';

/// Stub pour les plateformes non-web
/// Sur mobile, la validation de durée est faite par image_picker avec maxDuration
class VideoDurationHelper {
  /// Sur mobile, retourne null car la validation est faite par image_picker
  static Future<double?> getVideoDuration(Uint8List bytes, String mimeType) async {
    // Sur mobile, on ne peut pas facilement lire la durée sans package externe
    // La validation est faite par image_picker avec maxDuration
    return null;
  }
}
