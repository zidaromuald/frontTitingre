import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'api_service.dart';

/// Types de médias supportés
enum MediaType {
  image,
  video,
  audio,
  document,
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

/// Service de gestion des médias (upload)
class MediaService {
  // Taille maximale des fichiers en bytes (10 MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  // Extensions d'images autorisées
  static const List<String> allowedImageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'
  ];

  // Extensions de vidéos autorisées
  static const List<String> allowedVideoExtensions = [
    '.mp4', '.mov', '.avi', '.mkv', '.webm'
  ];

  // Extensions d'audio autorisées
  static const List<String> allowedAudioExtensions = [
    '.mp3', '.wav', '.aac', '.m4a', '.ogg'
  ];

  // Extensions de documents autorisées
  static const List<String> allowedDocumentExtensions = [
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'
  ];
  /// Upload une image
  /// POST /media/upload/image
  static Future<MediaUploadResponse> uploadImage(
    File file, {
    Function(double progress)? onProgress,
  }) async {
    return _uploadFile(file, MediaType.image, onProgress: onProgress);
  }

  /// Upload une vidéo
  /// POST /media/upload/video
  static Future<MediaUploadResponse> uploadVideo(
    File file, {
    Function(double progress)? onProgress,
  }) async {
    return _uploadFile(file, MediaType.video, onProgress: onProgress);
  }

  /// Upload un fichier audio
  /// POST /media/upload/audio
  static Future<MediaUploadResponse> uploadAudio(
    File file, {
    Function(double progress)? onProgress,
  }) async {
    return _uploadFile(file, MediaType.audio, onProgress: onProgress);
  }

  /// Upload un document
  /// POST /media/upload/document
  static Future<MediaUploadResponse> uploadDocument(
    File file, {
    Function(double progress)? onProgress,
  }) async {
    return _uploadFile(file, MediaType.document, onProgress: onProgress);
  }

  /// Upload automatique selon le type MIME du fichier
  static Future<MediaUploadResponse> uploadAuto(
    File file, {
    Function(double progress)? onProgress,
  }) async {
    final mimeType = _getMimeType(file.path);
    final mediaType = _detectMediaType(mimeType);
    return _uploadFile(file, mediaType, onProgress: onProgress);
  }

  /// Valider le type de fichier
  static bool _isValidFileType(File file, MediaType type) {
    final extension = path.extension(file.path).toLowerCase();

    switch (type) {
      case MediaType.image:
        return allowedImageExtensions.contains(extension);
      case MediaType.video:
        return allowedVideoExtensions.contains(extension);
      case MediaType.audio:
        return allowedAudioExtensions.contains(extension);
      case MediaType.document:
        return allowedDocumentExtensions.contains(extension);
    }
  }

  /// Valider la taille du fichier
  static Future<bool> _isValidFileSize(File file) async {
    final fileSize = await file.length();
    return fileSize <= maxFileSize;
  }

  /// Obtenir les extensions autorisées pour un type
  static List<String> _getAllowedExtensions(MediaType type) {
    switch (type) {
      case MediaType.image:
        return allowedImageExtensions;
      case MediaType.video:
        return allowedVideoExtensions;
      case MediaType.audio:
        return allowedAudioExtensions;
      case MediaType.document:
        return allowedDocumentExtensions;
    }
  }

  /// Méthode privée pour uploader un fichier avec validation et progression
  static Future<MediaUploadResponse> _uploadFile(
    File file,
    MediaType type, {
    Function(double progress)? onProgress,
  }) async {
    // Vérifier que le fichier existe
    if (!await file.exists()) {
      throw Exception('Le fichier n\'existe pas');
    }

    // Validation du type de fichier
    if (!_isValidFileType(file, type)) {
      final extension = path.extension(file.path);
      throw Exception(
        'Extension de fichier non autorisée: $extension. '
        'Extensions autorisées pour ${type.name}: ${_getAllowedExtensions(type)}'
      );
    }

    // Validation de la taille
    if (!await _isValidFileSize(file)) {
      final fileSize = await file.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
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

    // Ajouter le fichier avec progression
    final fileLength = await file.length();
    final stream = http.ByteStream(file.openRead());

    request.files.add(
      http.MultipartFile(
        'file',
        stream,
        fileLength,
        filename: path.basename(file.path),
      ),
    );

    // Envoyer la requête
    final streamedResponse = await request.send();

    // Gérer la progression si callback fourni
    http.Response response;
    if (onProgress != null) {
      int bytesReceived = 0;
      final contentLength = streamedResponse.contentLength ?? fileLength;

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

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true) {
        return MediaUploadResponse.fromJson(jsonResponse['data']);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Erreur d\'upload');
      }
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur d\'upload du fichier');
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

  /// Obtenir le MIME type d'un fichier (simplifié)
  static String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();

    // Images
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return 'image/$ext';
    }
    // Vidéos
    else if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return 'video/$ext';
    }
    // Audio
    else if (['mp3', 'wav', 'ogg', 'm4a'].contains(ext)) {
      return 'audio/$ext';
    }
    // Documents
    else {
      return 'application/$ext';
    }
  }

  /// Uploader plusieurs fichiers en parallèle
  static Future<List<MediaUploadResponse>> uploadMultiple(
    List<File> files,
  ) async {
    final uploadTasks = files.map((file) => uploadAuto(file)).toList();
    return await Future.wait(uploadTasks);
  }

  /// Uploader plusieurs images (helper)
  static Future<List<String>> uploadImages(List<File> images) async {
    final responses = await Future.wait(
      images.map((file) => uploadImage(file)),
    );
    return responses.map((response) => response.url).toList();
  }

  /// Uploader plusieurs vidéos (helper)
  static Future<List<String>> uploadVideos(List<File> videos) async {
    final responses = await Future.wait(
      videos.map((file) => uploadVideo(file)),
    );
    return responses.map((response) => response.url).toList();
  }

  /// Uploader plusieurs audios (helper)
  static Future<List<String>> uploadAudios(List<File> audios) async {
    final responses = await Future.wait(
      audios.map((file) => uploadAudio(file)),
    );
    return responses.map((response) => response.url).toList();
  }
}
