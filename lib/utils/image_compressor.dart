import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Utilitaire pour compresser les images avant upload vers Cloudflare R2
class ImageCompressor {
  /// Qualité de compression par défaut (0-100)
  static const int defaultQuality = 85;

  /// Largeur maximale par défaut (pixels)
  static const int defaultMaxWidth = 1920;

  /// Hauteur maximale par défaut (pixels)
  static const int defaultMaxHeight = 1920;

  /// Compresser une image et retourner le chemin du fichier compressé
  ///
  /// [imagePath] - Chemin de l'image source
  /// [quality] - Qualité de compression (0-100, défaut: 85)
  /// [maxWidth] - Largeur maximale (défaut: 1920px)
  /// [maxHeight] - Hauteur maximale (défaut: 1920px)
  ///
  /// Retourne le chemin du fichier compressé ou null en cas d'erreur
  static Future<String?> compressImage(
    String imagePath, {
    int quality = defaultQuality,
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
  }) async {
    try {
      // Vérifier si le fichier existe
      final sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        throw Exception('Le fichier source n\'existe pas: $imagePath');
      }

      // Obtenir le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(imagePath);
      final fileNameWithoutExt = path.basenameWithoutExtension(fileName);
      final ext = path.extension(fileName).toLowerCase();

      // Créer le nom du fichier compressé
      final targetPath = path.join(
        tempDir.path,
        '${fileNameWithoutExt}_compressed$ext',
      );

      // Déterminer le format de compression basé sur l'extension
      CompressFormat format;
      switch (ext) {
        case '.png':
          format = CompressFormat.png;
          break;
        case '.webp':
          format = CompressFormat.webp;
          break;
        case '.heic':
          format = CompressFormat.heic;
          break;
        default:
          format = CompressFormat.jpeg;
      }

      // Compresser l'image
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: format,
      );

      return result?.path;
    } catch (e) {
      throw Exception('Erreur de compression: $e');
    }
  }

  /// Compresser une image avec compression légère (haute qualité)
  static Future<String?> compressImageLight(String imagePath) async {
    return await compressImage(
      imagePath,
      quality: 95,
      maxWidth: 2560,
      maxHeight: 2560,
    );
  }

  /// Compresser une image avec compression moyenne (qualité équilibrée)
  static Future<String?> compressImageMedium(String imagePath) async {
    return await compressImage(
      imagePath,
      quality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
  }

  /// Compresser une image avec compression forte (petite taille)
  static Future<String?> compressImageHeavy(String imagePath) async {
    return await compressImage(
      imagePath,
      quality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );
  }

  /// Compresser pour miniature (thumbnail)
  static Future<String?> compressImageThumbnail(String imagePath) async {
    return await compressImage(
      imagePath,
      quality: 80,
      maxWidth: 400,
      maxHeight: 400,
    );
  }

  /// Obtenir la taille d'un fichier en bytes
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }

  /// Obtenir la taille d'un fichier en MB (formaté)
  static Future<String> getFileSizeMB(String filePath) async {
    final bytes = await getFileSize(filePath);
    final mb = bytes / (1024 * 1024);
    return mb.toStringAsFixed(2);
  }

  /// Comparer les tailles avant/après compression
  static Future<Map<String, dynamic>> getCompressionStats(
    String originalPath,
    String compressedPath,
  ) async {
    final originalSize = await getFileSize(originalPath);
    final compressedSize = await getFileSize(compressedPath);
    final reduction = ((originalSize - compressedSize) / originalSize * 100);

    return {
      'original_bytes': originalSize,
      'compressed_bytes': compressedSize,
      'original_mb': (originalSize / (1024 * 1024)).toStringAsFixed(2),
      'compressed_mb': (compressedSize / (1024 * 1024)).toStringAsFixed(2),
      'reduction_percent': reduction.toStringAsFixed(1),
      'size_ratio': (compressedSize / originalSize * 100).toStringAsFixed(1),
    };
  }

  /// Compresser automatiquement en fonction de la taille du fichier
  ///
  /// - < 1MB: compression légère
  /// - 1-3MB: compression moyenne
  /// - 3-5MB: compression forte
  /// - > 5MB: erreur (fichier trop volumineux)
  static Future<String?> compressImageAuto(String imagePath) async {
    final fileSize = await getFileSize(imagePath);
    final fileSizeMB = fileSize / (1024 * 1024);

    if (fileSizeMB > 10) {
      throw Exception(
        'Fichier trop volumineux: ${fileSizeMB.toStringAsFixed(2)}MB. '
        'Taille maximale: 10MB'
      );
    } else if (fileSizeMB > 5) {
      // > 5MB: compression forte
      return await compressImageHeavy(imagePath);
    } else if (fileSizeMB > 3) {
      // 3-5MB: compression forte
      return await compressImageHeavy(imagePath);
    } else if (fileSizeMB > 1) {
      // 1-3MB: compression moyenne
      return await compressImageMedium(imagePath);
    } else {
      // < 1MB: compression légère
      return await compressImageLight(imagePath);
    }
  }
}
