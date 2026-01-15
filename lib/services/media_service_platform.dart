import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_service.dart';

/// Types de médias supportés
enum MediaType {
  image,
  video,
  audio,
  document,
}

/// Classe représentant un fichier multiplateforme
class PlatformFile {
  final String name;
  final Uint8List bytes;
  final String? mimeType;

  PlatformFile({
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  /// Créer depuis un File (mobile/desktop)
  static Future<PlatformFile> fromFile(dynamic file) async {
    if (kIsWeb) {
      throw UnsupportedError('Utiliser fromBytes sur le web');
    }

    // Sur mobile/desktop, file est de type File (dart:io)
    final bytes = await file.readAsBytes();
    return PlatformFile(
      name: path.basename(file.path),
      bytes: bytes,
      mimeType: _getMimeType(file.path),
    );
  }

  /// Créer depuis des bytes (web et mobile)
  static PlatformFile fromBytes({
    required String name,
    required Uint8List bytes,
    String? mimeType,
  }) {
    return PlatformFile(
      name: name,
      bytes: bytes,
      mimeType: mimeType ?? _getMimeType(name),
    );
  }

  /// Obtenir le MIME type d'un fichier selon son extension
  static String _getMimeType(String filename) {
    final ext = path.extension(filename).toLowerCase().replaceAll('.', '');

    // Images
    if (['jpg', 'jpeg'].contains(ext)) return 'image/jpeg';
    if (ext == 'png') return 'image/png';
    if (ext == 'gif') return 'image/gif';
    if (ext == 'webp') return 'image/webp';
    if (ext == 'bmp') return 'image/bmp';

    // Vidéos
    if (ext == 'mp4') return 'video/mp4';
    if (ext == 'mov') return 'video/quicktime';
    if (ext == 'avi') return 'video/x-msvideo';
    if (ext == 'mkv') return 'video/x-matroska';
    if (ext == 'webm') return 'video/webm';

    // Audio
    if (ext == 'mp3') return 'audio/mpeg';
    if (ext == 'wav') return 'audio/wav';
    if (ext == 'ogg') return 'audio/ogg';
    if (ext == 'm4a') return 'audio/mp4';
    if (ext == 'aac') return 'audio/aac';

    // Documents
    if (ext == 'pdf') return 'application/pdf';
    if (ext == 'doc') return 'application/msword';
    if (ext == 'docx') return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (ext == 'xls') return 'application/vnd.ms-excel';
    if (ext == 'xlsx') return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (ext == 'ppt') return 'application/vnd.ms-powerpoint';
    if (ext == 'pptx') return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    if (ext == 'txt') return 'text/plain';

    return 'application/octet-stream';
  }
}

/// Modèle de réponse d'upload
class MediaUploadResponse {
  final String url;
  final String filename;
  final int size;
  final String mimetype;
  final String type;

  MediaUploadResponse({
    required this.url,
    required this.filename,
    required this.size,
    required this.mimetype,
    required this.type,
  });

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(
      url: json['url'],
      filename: json['filename'],
      size: json['size'],
      mimetype: json['mimetype'],
      type: json['type'],
    );
  }
}

/// Service de gestion des médias multiplateforme (web + mobile)
class MediaServicePlatform {
  // Taille maximale des fichiers en bytes (10 MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  // Extensions autorisées par type
  static const Map<MediaType, List<String>> allowedExtensions = {
    MediaType.image: ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'],
    MediaType.video: ['.mp4', '.mov', '.avi', '.mkv', '.webm'],
    MediaType.audio: ['.mp3', '.wav', '.aac', '.m4a', '.ogg'],
    MediaType.document: ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'],
  };

  /// Upload une image
  static Future<MediaUploadResponse> uploadImage(
    PlatformFile file, {
    Function(double progress)? onProgress,
  }) async {
    return _uploadFile(file, MediaType.image, onProgress: onProgress);
  }

  /// Upload une vidéo
  static Future<MediaUploadResponse> uploadVideo(
    PlatformFile file, {
    Function(double progress)? onProgress,
  }) async {
    return _uploadFile(file, MediaType.video, onProgress: onProgress);
  }

  /// Upload un fichier audio
  static Future<MediaUploadResponse> uploadAudio(
    PlatformFile file, {
    Function(double progress)? onProgress,
  }) async {
    return _uploadFile(file, MediaType.audio, onProgress: onProgress);
  }

  /// Upload un document
  static Future<MediaUploadResponse> uploadDocument(
    PlatformFile file, {
    Function(double progress)? onProgress,
  }) async {
    return _uploadFile(file, MediaType.document, onProgress: onProgress);
  }

  /// Upload automatique selon le type MIME du fichier
  static Future<MediaUploadResponse> uploadAuto(
    PlatformFile file, {
    Function(double progress)? onProgress,
  }) async {
    final mimeType = file.mimeType ?? PlatformFile._getMimeType(file.name);
    final mediaType = _detectMediaType(mimeType);
    return _uploadFile(file, mediaType, onProgress: onProgress);
  }

  /// Valider le type de fichier
  static bool _isValidFileType(PlatformFile file, MediaType type) {
    final extension = path.extension(file.name).toLowerCase();
    return allowedExtensions[type]?.contains(extension) ?? false;
  }

  /// Valider la taille du fichier
  static bool _isValidFileSize(PlatformFile file) {
    return file.bytes.length <= maxFileSize;
  }

  /// Méthode privée pour uploader un fichier avec validation et progression
  static Future<MediaUploadResponse> _uploadFile(
    PlatformFile file,
    MediaType type, {
    Function(double progress)? onProgress,
  }) async {
    // Validation du type de fichier
    if (!_isValidFileType(file, type)) {
      final extension = path.extension(file.name);
      throw Exception(
        'Extension de fichier non autorisée: $extension. '
        'Extensions autorisées pour ${type.name}: ${allowedExtensions[type]}'
      );
    }

    // Validation de la taille
    if (!_isValidFileSize(file)) {
      final fileSizeMB = (file.bytes.length / (1024 * 1024)).toStringAsFixed(2);
      throw Exception(
        'Fichier trop volumineux: ${fileSizeMB}MB. Taille maximale: ${maxFileSize ~/ (1024 * 1024)}MB'
      );
    }

    // Construire l'endpoint selon le type
    final endpoint = '/media/upload/${type.name}';

    // Récupérer le token d'authentification
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Non authentifié');
    }

    // Créer la requête multipart
    final uri = Uri.parse('${ApiService.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Ajouter le header d'authentification
    request.headers['Authorization'] = 'Bearer $token';

    // Déterminer le content-type
    final mimeType = file.mimeType ?? PlatformFile._getMimeType(file.name);
    final mimeTypeParts = mimeType.split('/');
    final contentType = mimeTypeParts.length == 2
        ? http_parser.MediaType(mimeTypeParts[0], mimeTypeParts[1])
        : http_parser.MediaType('application', 'octet-stream');

    // Ajouter le fichier à partir des bytes (fonctionne sur web ET mobile)
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes,
        filename: file.name,
        contentType: contentType,
      ),
    );

    print('📤 [MediaServicePlatform] Upload de ${file.name} (${file.bytes.length} bytes) vers $endpoint');

    // Envoyer la requête
    final streamedResponse = await request.send();

    // Gérer la progression si callback fourni
    http.Response response;
    if (onProgress != null) {
      int bytesReceived = 0;
      final contentLength = streamedResponse.contentLength ?? file.bytes.length;

      final responseStream = streamedResponse.stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (List<int> data, EventSink<List<int>> sink) {
            bytesReceived += data.length;
            final progress = bytesReceived / contentLength.toDouble();
            onProgress(progress);
            sink.add(data);
          },
        ),
      );

      response = await http.Response.fromStream(
        http.StreamedResponse(
          responseStream,
          streamedResponse.statusCode,
          contentLength: streamedResponse.contentLength,
          headers: streamedResponse.headers,
          isRedirect: streamedResponse.isRedirect,
          persistentConnection: streamedResponse.persistentConnection,
          reasonPhrase: streamedResponse.reasonPhrase,
          request: streamedResponse.request,
        ),
      );
    } else {
      response = await http.Response.fromStream(streamedResponse);
    }

    print('📥 [MediaServicePlatform] Response status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true) {
        return MediaUploadResponse.fromJson(jsonResponse['data']);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Erreur d\'upload');
      }
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur d\'upload du fichier');
      } catch (e) {
        throw Exception('Erreur d\'upload du fichier: ${response.body}');
      }
    }
  }

  /// Détecter le type de média selon le MIME type
  static MediaType _detectMediaType(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return MediaType.image;
    } else if (mimeType.startsWith('video/')) {
      return MediaType.video;
    } else if (mimeType.startsWith('audio/')) {
      return MediaType.audio;
    } else {
      return MediaType.document;
    }
  }

  /// Uploader plusieurs fichiers en parallèle
  static Future<List<MediaUploadResponse>> uploadMultiple(
    List<PlatformFile> files,
  ) async {
    final uploadTasks = files.map((file) => uploadAuto(file)).toList();
    return await Future.wait(uploadTasks);
  }

  /// Uploader plusieurs images (helper)
  static Future<List<String>> uploadImages(List<PlatformFile> images) async {
    final responses = await Future.wait(
      images.map((file) => uploadImage(file)),
    );
    return responses.map((response) => response.url).toList();
  }

  /// Uploader plusieurs vidéos (helper)
  static Future<List<String>> uploadVideos(List<PlatformFile> videos) async {
    final responses = await Future.wait(
      videos.map((file) => uploadVideo(file)),
    );
    return responses.map((response) => response.url).toList();
  }

  /// Uploader plusieurs audios (helper)
  static Future<List<String>> uploadAudios(List<PlatformFile> audios) async {
    final responses = await Future.wait(
      audios.map((file) => uploadAudio(file)),
    );
    return responses.map((response) => response.url).toList();
  }
}
