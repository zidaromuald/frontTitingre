import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  /// Upload une image
  /// POST /media/upload/image
  static Future<MediaUploadResponse> uploadImage(File file) async {
    return _uploadFile(file, MediaType.image);
  }

  /// Upload une vidéo
  /// POST /media/upload/video
  static Future<MediaUploadResponse> uploadVideo(File file) async {
    return _uploadFile(file, MediaType.video);
  }

  /// Upload un fichier audio
  /// POST /media/upload/audio
  static Future<MediaUploadResponse> uploadAudio(File file) async {
    return _uploadFile(file, MediaType.audio);
  }

  /// Upload un document
  /// POST /media/upload/document
  static Future<MediaUploadResponse> uploadDocument(File file) async {
    return _uploadFile(file, MediaType.document);
  }

  /// Upload automatique selon le type MIME du fichier
  static Future<MediaUploadResponse> uploadAuto(File file) async {
    final mimeType = _getMimeType(file.path);
    final mediaType = _detectMediaType(mimeType);
    return _uploadFile(file, mediaType);
  }

  /// Méthode privée pour uploader un fichier
  static Future<MediaUploadResponse> _uploadFile(
    File file,
    MediaType type,
  ) async {
    // Vérifier que le fichier existe
    if (!await file.exists()) {
      throw Exception('Le fichier n\'existe pas');
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

    // Ajouter le fichier
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Nom du champ (doit correspondre au backend)
        file.path,
      ),
    );

    // Envoyer la requête
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

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
