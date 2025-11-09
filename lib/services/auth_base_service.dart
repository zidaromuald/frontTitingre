import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de base pour l'authentification
/// Contient la logique commune entre User et Societe
abstract class AuthBaseService {
  /// Sauvegarder le token JWT
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
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
    // Sauvegarder le token
    final token = responseData['access_token'];
    await saveToken(token);

    // Sauvegarder le type d'utilisateur
    await saveUserType(userType);

    // Sauvegarder les données utilisateur
    final userData = responseData['user'] ?? responseData['societe'];
    if (userData != null) {
      await saveUserData(userData);
    }
  }

  /// Déconnexion (commune)
  static Future<void> logout() async {
    await clearAuthData();
  }
}
