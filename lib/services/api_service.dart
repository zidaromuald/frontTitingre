import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service de base pour les appels API
class ApiService {
  // URL de base de votre API NestJS
  static const String baseUrl = 'http://localhost:3000'; // À modifier selon votre config

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
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET Request
  static Future<http.Response> get(String endpoint) async {
    final headers = await _authHeaders;
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.get(uri, headers: headers);
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// POST Request
  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _authHeaders;
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// PUT Request
  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
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
  static Future<http.Response> delete(String endpoint) async {
    final headers = await _authHeaders;
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.delete(uri, headers: headers);
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Upload de fichier vers un endpoint spécifique (générique)
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
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, filePath),
      );

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
