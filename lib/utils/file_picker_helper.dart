import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/media_service_platform.dart';

/// Helper pour sélectionner des fichiers sur toutes les plateformes
class FilePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Sélectionner une image depuis la galerie (web et mobile)
  static Future<PlatformFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;

      // Lire les bytes du fichier (fonctionne sur web et mobile)
      final Uint8List bytes = await pickedFile.readAsBytes();

      return PlatformFile.fromBytes(
        name: pickedFile.name,
        bytes: bytes,
        mimeType: pickedFile.mimeType,
      );
    } catch (e) {
      print('❌ Erreur lors de la sélection d\'image: $e');
      rethrow;
    }
  }

  /// Sélectionner plusieurs images depuis la galerie (web et mobile)
  static Future<List<PlatformFile>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFiles.isEmpty) return [];

      // Convertir tous les fichiers en PlatformFile
      final List<PlatformFile> platformFiles = [];
      for (final file in pickedFiles) {
        final bytes = await file.readAsBytes();
        platformFiles.add(PlatformFile.fromBytes(
          name: file.name,
          bytes: bytes,
          mimeType: file.mimeType,
        ));
      }

      return platformFiles;
    } catch (e) {
      print('❌ Erreur lors de la sélection d\'images: $e');
      rethrow;
    }
  }

  /// Prendre une photo avec la caméra (mobile uniquement)
  static Future<PlatformFile?> takePhoto({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('La caméra n\'est pas disponible sur le web. Utilisez pickImage()');
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;

      final Uint8List bytes = await pickedFile.readAsBytes();

      return PlatformFile.fromBytes(
        name: pickedFile.name,
        bytes: bytes,
        mimeType: pickedFile.mimeType,
      );
    } catch (e) {
      print('❌ Erreur lors de la prise de photo: $e');
      rethrow;
    }
  }

  /// Sélectionner une vidéo (web et mobile)
  static Future<PlatformFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
      );

      if (pickedFile == null) return null;

      final Uint8List bytes = await pickedFile.readAsBytes();

      return PlatformFile.fromBytes(
        name: pickedFile.name,
        bytes: bytes,
        mimeType: pickedFile.mimeType,
      );
    } catch (e) {
      print('❌ Erreur lors de la sélection de vidéo: $e');
      rethrow;
    }
  }

  /// Afficher un dialog pour choisir entre galerie et caméra (mobile uniquement)
  static Future<PlatformFile?> showImageSourceDialog({
    required Function(ImageSource) onSourceSelected,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    if (kIsWeb) {
      // Sur web, on utilise directement la galerie
      return pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
    }

    // Sur mobile, on laisse l'appelant gérer le dialog et rappeler pickImage ou takePhoto
    throw UnsupportedError('Utilisez un dialog personnalisé pour mobile');
  }
}
