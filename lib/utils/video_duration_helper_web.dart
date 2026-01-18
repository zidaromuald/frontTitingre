import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Helper pour obtenir la durée d'une vidéo sur le web
/// Utilise l'API HTML5 <video> pour lire les métadonnées
class VideoDurationHelper {
  /// Obtenir la durée d'une vidéo en secondes à partir de ses bytes
  /// Retourne la durée en secondes, ou null si impossible de lire
  static Future<double?> getVideoDuration(Uint8List bytes, String mimeType) async {
    final completer = Completer<double?>();

    // Créer un Blob à partir des bytes
    final jsArray = bytes.toJS;
    final blob = web.Blob([jsArray].toJS, web.BlobPropertyBag(type: mimeType));
    final url = web.URL.createObjectURL(blob);

    // Créer un élément video pour lire les métadonnées
    final video = web.HTMLVideoElement()
      ..src = url
      ..preload = 'metadata';

    // Timer pour timeout (5 secondes max)
    final timeout = Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        web.URL.revokeObjectURL(url);
        completer.complete(null);
      }
    });

    // Écouter l'événement loadedmetadata
    video.onloadedmetadata = (web.Event event) {
      timeout.cancel();
      final duration = video.duration;
      web.URL.revokeObjectURL(url);

      if (duration.isFinite && duration > 0) {
        completer.complete(duration.toDouble());
      } else {
        completer.complete(null);
      }
    }.toJS;

    // Écouter les erreurs
    video.onerror = (web.Event event) {
      timeout.cancel();
      web.URL.revokeObjectURL(url);
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }.toJS;

    // Charger la vidéo
    video.load();

    return completer.future;
  }
}
