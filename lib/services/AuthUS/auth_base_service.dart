import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de base pour l'authentification
/// Contient la logique commune entre User et Societe
abstract class AuthBaseService {
  /// Sauvegarder le token JWT
  static Future<void> saveToken(String token) async {
    print('💾 [AuthBaseService] saveToken appelée');
    print('🎫 [AuthBaseService] Token à sauvegarder: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
    print('📏 [AuthBaseService] Longueur du token: ${token.length} caractères');

    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString('auth_token', token);

    print('✅ [AuthBaseService] Token sauvegardé: $success');

    // Vérification immédiate
    final savedToken = prefs.getString('auth_token');
    if (savedToken == token) {
      print('✅ [AuthBaseService] Vérification: Token bien enregistré dans SharedPreferences');
    } else {
      print('❌ [AuthBaseService] ERREUR: Le token sauvegardé ne correspond pas!');
    }
  }

  /// Sauvegarder le type d'utilisateur ('user' ou 'societe')
  static Future<void> saveUserType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type', type);
  }

  /// Récupérer le type d'utilisateur
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }

  /// Sauvegarder les données utilisateur complètes
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  /// Récupérer les données utilisateur
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  /// Supprimer toutes les données d'authentification
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_type');
    await prefs.remove('user_data');
  }

  /// Vérifier si l'utilisateur est connecté
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  /// Récupérer le token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Traiter la réponse de connexion (commune à User et Societe)
  static Future<void> handleLoginResponse(
    Map<String, dynamic> responseData,
    String userType,
  ) async {
    print('🔐 [AuthBaseService] handleLoginResponse appelée');
    print('📦 [AuthBaseService] responseData keys: ${responseData.keys.toList()}');
    print('📦 [AuthBaseService] responseData: $responseData');
    print('👤 [AuthBaseService] userType: $userType');

    // Sauvegarder le token - essayer plusieurs noms de clés
    String? token = responseData['access_token'];

    // Si access_token n'existe pas, essayer d'autres clés
    if (token == null) {
      final possibleTokenKeys = ['token', 'accessToken', 'jwt'];
      for (final key in possibleTokenKeys) {
        if (responseData.containsKey(key)) {
          token = responseData[key];
          print('✅ [AuthBaseService] Token trouvé sous la clé "$key"');
          break;
        }
      }
    }

    print('🎫 [AuthBaseService] Token extrait: ${token != null ? "OUI (${token.toString().length} chars)" : "NULL"}');

    if (token == null) {
      print('❌ [AuthBaseService] ERREUR: Aucun token trouvé dans la réponse!');
      print('📋 [AuthBaseService] Clés disponibles: ${responseData.keys.toList()}');
      throw Exception('Token non trouvé dans la réponse. Clés disponibles: ${responseData.keys.toList()}');
    }

    await saveToken(token);
    print('✅ [AuthBaseService] Token sauvegardé');

    // Sauvegarder le type d'utilisateur
    await saveUserType(userType);
    print('✅ [AuthBaseService] Type utilisateur sauvegardé: $userType');

    // Sauvegarder les données utilisateur
    final userData = responseData['user'] ?? responseData['societe'];
    print('👤 [AuthBaseService] userData: ${userData != null ? "OUI" : "NULL"}');

    if (userData != null) {
      await saveUserData(userData);
      print('✅ [AuthBaseService] Données utilisateur sauvegardées');
    } else {
      print('⚠️ [AuthBaseService] Aucune donnée utilisateur à sauvegarder');
    }

    print('🎉 [AuthBaseService] handleLoginResponse terminée avec succès');
  }

  /// Déconnexion (commune)
  static Future<void> logout() async {
    await clearAuthData();
  }
}
