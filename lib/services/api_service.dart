import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../config/app_config.dart';

/// Service de base pour les appels API
class ApiService {
  // URL de base de votre API NestJS - s'adapte automatiquement selon la plateforme
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Headers par défaut
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Récupérer le token JWT stocké
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Headers avec authentification
  static Future<Map<String, String>> get _authHeaders async {
    final token = await _getToken();
    return {..._headers, if (token != null) 'Authorization': 'Bearer $token'};
  }

  /// GET Request
  static Future<http.Response> get(String endpoint) async {
    final headers = await _authHeaders;
    final uri = Uri.parse('$baseUrl$endpoint');

    // DEBUG: Afficher les détails de la requête
    print('🌐 [API] GET $uri');
    print('🔑 [API] Token présent: ${headers.containsKey('Authorization')}');
    if (headers.containsKey('Authorization')) {
      final token = headers['Authorization']!;
      print('🔑 [API] Token (premiers 30 chars): ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
    }

    try {
      final response = await http.get(uri, headers: headers);
      print('📥 [API] Response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ [API] Erreur: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// POST Request
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final headers = await _authHeaders;
    final uri = Uri.parse('$baseUrl$endpoint');

    // DEBUG: Afficher les détails de la requête
    print('🌐 [API] POST $uri');
    print('📤 [API] Body: ${jsonEncode(data)}');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      );
      print('📥 [API] Response status: ${response.statusCode}');
      print('📥 [API] Response body: ${response.body}');
      return response;
    } catch (e) {
      print('❌ [API] Erreur POST: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// PUT Request
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final headers = await _authHeaders;
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// DELETE Request
  /// Note: On n'envoie pas Content-Type pour éviter l'erreur "body cannot be empty"
  static Future<http.Response> delete(String endpoint) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl$endpoint');

    // Headers sans Content-Type pour DELETE sans body
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.delete(uri, headers: headers);
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Upload de fichier vers un endpoint spécifique (générique)
  /// ATTENTION: Cette méthode utilise dart:io et ne fonctionne PAS sur le web
  /// Pour le web, utiliser uploadBytesToEndpoint()
  static Future<http.Response> uploadFileToEndpoint(
    String filePath,
    String endpoint, {
    String fieldName = 'file',
    Map<String, String>? additionalFields,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      var request = http.MultipartRequest('POST', uri);

      // Ajouter le token si disponible
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Ajouter le fichier
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      // Ajouter des champs supplémentaires si fournis
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('Erreur d\'upload: $e');
    }
  }

  /// Upload de fichier via bytes (compatible WEB et mobile)
  /// Utilise Uint8List au lieu d'un chemin de fichier
  static Future<http.Response> uploadBytesToEndpoint(
    Uint8List bytes,
    String filename,
    String endpoint, {
    String fieldName = 'file',
    Map<String, String>? additionalFields,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl$endpoint');

    print('📤 [API] Upload bytes vers $uri (${bytes.length} bytes)');

    try {
      var request = http.MultipartRequest('POST', uri);

      // Ajouter le token si disponible
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Déterminer le Content-Type à partir de l'extension du fichier
      final ext = path.extension(filename).toLowerCase().replaceAll('.', '');
      http_parser.MediaType? contentType;

      // Images
      if (['jpg', 'jpeg'].contains(ext)) {
        contentType = http_parser.MediaType('image', 'jpeg');
      } else if (ext == 'png') {
        contentType = http_parser.MediaType('image', 'png');
      } else if (ext == 'gif') {
        contentType = http_parser.MediaType('image', 'gif');
      } else if (ext == 'webp') {
        contentType = http_parser.MediaType('image', 'webp');
      }
      // Vidéos
      else if (ext == 'mp4') {
        contentType = http_parser.MediaType('video', 'mp4');
      } else if (ext == 'mov') {
        contentType = http_parser.MediaType('video', 'quicktime');
      }
      // Audio
      else if (ext == 'mp3') {
        contentType = http_parser.MediaType('audio', 'mpeg');
      } else if (ext == 'aac') {
        contentType = http_parser.MediaType('audio', 'aac');
      } else if (ext == 'm4a') {
        contentType = http_parser.MediaType('audio', 'mp4');
      }

      print('📤 [API] Content-Type détecté: $contentType pour $filename');

      // Ajouter le fichier à partir des bytes (compatible web)
      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: contentType,
      ));

      // Ajouter des champs supplémentaires si fournis
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 [API] Upload response: ${response.statusCode}');
      print('📥 [API] Upload body: ${response.body}');

      return response;
    } catch (e) {
      print('❌ [API] Erreur upload: $e');
      throw Exception('Erreur d\'upload: $e');
    }
  }

  /// Upload de fichier (image, vidéo, audio) pour les posts
  /// @deprecated Utiliser uploadFileToEndpoint() pour plus de flexibilité
  static Future<String?> uploadFile(String filePath, String fileType) async {
    try {
      final response = await uploadFileToEndpoint(
        filePath,
        '/posts/upload',
        fieldName: 'file',
        additionalFields: {'type': fileType},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      } else {
        throw Exception('Échec de l\'upload: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur d\'upload: $e');
    }
  }

  /// Sauvegarder le token d'authentification
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Supprimer le token (déconnexion)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
