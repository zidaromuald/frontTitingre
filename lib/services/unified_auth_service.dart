import 'auth_base_service.dart';
import 'user_auth_service.dart';
import 'societe_auth_service.dart';

/// Service unifié d'authentification
/// Gère automatiquement User et Societe
class UnifiedAuthService {
  /// Récupérer le type d'utilisateur connecté
  static Future<String?> getCurrentType() async {
    return await AuthBaseService.getUserType();
  }

  /// Vérifier si quelqu'un est connecté (User ou Societe)
  static Future<bool> isAuthenticated() async {
    return await AuthBaseService.isAuthenticated();
  }

  /// Récupérer les données de l'utilisateur/société connecté(e)
  static Future<dynamic> getCurrentEntity() async {
    final userType = await AuthBaseService.getUserType();

    if (userType == 'user') {
      try {
        return await UserAuthService.getMe();
      } catch (e) {
        // Si l'appel API échoue, essayer le cache
        return await UserAuthService.getCachedUser();
      }
    } else if (userType == 'societe') {
      try {
        return await SocieteAuthService.getMe();
      } catch (e) {
        // Si l'appel API échoue, essayer le cache
        return await SocieteAuthService.getCachedSociete();
      }
    }

    return null;
  }

  /// Déconnexion (User ou Societe)
  static Future<void> logout() async {
    final userType = await AuthBaseService.getUserType();

    if (userType == 'user') {
      await UserAuthService.logout();
    } else if (userType == 'societe') {
      await SocieteAuthService.logout();
    } else {
      // Déconnexion locale de toute façon
      await AuthBaseService.logout();
    }
  }

  /// Déconnexion de tous les appareils
  static Future<void> logoutAll() async {
    final userType = await AuthBaseService.getUserType();

    if (userType == 'user') {
      await UserAuthService.logoutAll();
    } else if (userType == 'societe') {
      await SocieteAuthService.logoutAll();
    } else {
      await AuthBaseService.logout();
    }
  }

  /// Récupérer l'ID de l'utilisateur/société connecté(e)
  static Future<int?> getCurrentId() async {
    final entity = await getCurrentEntity();
    if (entity != null) {
      return entity.id;
    }
    return null;
  }

  /// Récupérer le nom de l'utilisateur/société connecté(e)
  static Future<String?> getCurrentName() async {
    final entity = await getCurrentEntity();
    if (entity != null) {
      if (entity is UserModel) {
        return entity.fullName;
      } else if (entity is SocieteModel) {
        return entity.nom;
      }
    }
    return null;
  }

  /// Vérifier si c'est un User
  static Future<bool> isUser() async {
    final userType = await AuthBaseService.getUserType();
    return userType == 'user';
  }

  /// Vérifier si c'est une Société
  static Future<bool> isSociete() async {
    final userType = await AuthBaseService.getUserType();
    return userType == 'societe';
  }
}
