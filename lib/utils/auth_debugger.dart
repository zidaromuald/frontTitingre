import 'package:shared_preferences/shared_preferences.dart';
import '../services/AuthUS/auth_base_service.dart';
import '../services/api_service.dart';

/// Utilitaire de debug pour diagnostiquer les problèmes d'authentification
class AuthDebugger {
  /// Afficher toutes les informations d'authentification
  static Future<Map<String, dynamic>> getAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('auth_token');
    final userType = prefs.getString('user_type');
    final userDataStr = prefs.getString('user_data');

    return {
      'hasToken': token != null,
      'tokenLength': token?.length ?? 0,
      'tokenPreview': token != null && token.length > 30
          ? '${token.substring(0, 30)}...'
          : token,
      'userType': userType,
      'hasUserData': userDataStr != null,
      'isAuthenticated': await AuthBaseService.isAuthenticated(),
      'apiBaseUrl': ApiService.baseUrl,
    };
  }

  /// Tester la connexion API avec le token actuel
  static Future<Map<String, dynamic>> testApiConnection() async {
    try {
      print('🔍 [AuthDebugger] Test de connexion API...');

      final authStatus = await getAuthStatus();
      print('📊 [AuthDebugger] Status auth: $authStatus');

      if (!authStatus['hasToken']) {
        return {
          'success': false,
          'error': 'Aucun token trouvé',
          'details': 'L\'utilisateur n\'est pas connecté',
        };
      }

      // Tester l'endpoint /auth/me
      print('🌐 [AuthDebugger] Test GET /auth/me...');
      final response = await ApiService.get('/auth/me');

      print('📥 [AuthDebugger] Status code: ${response.statusCode}');
      print('📥 [AuthDebugger] Response: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'endpoint': '/auth/me',
          'statusCode': response.statusCode,
          'body': response.body,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Unauthorized (401)',
          'details': 'Le token est invalide ou expiré',
          'endpoint': '/auth/me',
          'statusCode': response.statusCode,
          'body': response.body,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur HTTP ${response.statusCode}',
          'endpoint': '/auth/me',
          'statusCode': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      print('❌ [AuthDebugger] Erreur: $e');
      return {
        'success': false,
        'error': 'Exception',
        'details': e.toString(),
      };
    }
  }

  /// Tester le chargement du profil complet
  static Future<Map<String, dynamic>> testProfileLoad() async {
    try {
      print('🔍 [AuthDebugger] Test de chargement du profil...');

      // Tester /users/me
      print('🌐 [AuthDebugger] Test GET /users/me...');
      final response = await ApiService.get('/users/me');

      print('📥 [AuthDebugger] Status code: ${response.statusCode}');
      print('📥 [AuthDebugger] Response: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'endpoint': '/users/me',
          'statusCode': response.statusCode,
          'body': response.body,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Unauthorized (401)',
          'details': 'Le token est invalide ou expiré',
          'endpoint': '/users/me',
          'statusCode': response.statusCode,
          'body': response.body,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur HTTP ${response.statusCode}',
          'endpoint': '/users/me',
          'statusCode': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      print('❌ [AuthDebugger] Erreur: $e');
      return {
        'success': false,
        'error': 'Exception',
        'details': e.toString(),
      };
    }
  }

  /// Tester la recherche
  static Future<Map<String, dynamic>> testSearch(String query) async {
    try {
      print('🔍 [AuthDebugger] Test de recherche: "$query"...');

      // Tester /users/autocomplete
      final endpoint = '/users/autocomplete?term=$query';
      print('🌐 [AuthDebugger] Test GET $endpoint...');
      final response = await ApiService.get(endpoint);

      print('📥 [AuthDebugger] Status code: ${response.statusCode}');
      print('📥 [AuthDebugger] Response: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'endpoint': endpoint,
          'statusCode': response.statusCode,
          'body': response.body,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Unauthorized (401)',
          'details': 'Le token est invalide ou expiré',
          'endpoint': endpoint,
          'statusCode': response.statusCode,
          'body': response.body,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur HTTP ${response.statusCode}',
          'endpoint': endpoint,
          'statusCode': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      print('❌ [AuthDebugger] Erreur: $e');
      return {
        'success': false,
        'error': 'Exception',
        'details': e.toString(),
      };
    }
  }

  /// Effectuer un diagnostic complet
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    print('\n🔬 ========== DIAGNOSTIC COMPLET ==========\n');

    final results = <String, dynamic>{};

    // 1. Vérifier le statut d'authentification
    print('1️⃣ Vérification du statut d\'authentification...');
    results['authStatus'] = await getAuthStatus();
    print('✅ Status auth: ${results['authStatus']}\n');

    // 2. Tester la connexion API
    print('2️⃣ Test de la connexion API...');
    results['apiConnection'] = await testApiConnection();
    print('✅ Connexion API: ${results['apiConnection']['success']}\n');

    // 3. Tester le chargement du profil
    print('3️⃣ Test du chargement du profil...');
    results['profileLoad'] = await testProfileLoad();
    print('✅ Profil: ${results['profileLoad']['success']}\n');

    // 4. Tester la recherche
    print('4️⃣ Test de la recherche...');
    results['search'] = await testSearch('test');
    print('✅ Recherche: ${results['search']['success']}\n');

    // Résumé
    print('🔬 ========== RÉSUMÉ ==========');
    print('✅ Authentifié: ${results['authStatus']['isAuthenticated']}');
    print('✅ API /auth/me: ${results['apiConnection']['success']}');
    print('✅ API /users/me: ${results['profileLoad']['success']}');
    print('✅ Recherche: ${results['search']['success']}');
    print('========================================\n');

    return results;
  }

  /// Afficher les recommandations basées sur les résultats
  static void printRecommendations(Map<String, dynamic> diagnosticResults) {
    print('\n💡 ========== RECOMMANDATIONS ==========\n');

    final authStatus = diagnosticResults['authStatus'] as Map<String, dynamic>;
    final apiConnection = diagnosticResults['apiConnection'] as Map<String, dynamic>;
    final profileLoad = diagnosticResults['profileLoad'] as Map<String, dynamic>;
    final search = diagnosticResults['search'] as Map<String, dynamic>;

    if (!authStatus['hasToken']) {
      print('❌ PROBLÈME: Aucun token trouvé');
      print('   → L\'utilisateur doit se reconnecter');
      print('   → Vérifier que le login sauvegarde bien le token\n');
      return;
    }

    if (!apiConnection['success']) {
      print('❌ PROBLÈME: La connexion API échoue');
      final statusCode = apiConnection['statusCode'];
      if (statusCode == 401) {
        print('   → Le token est invalide ou expiré');
        print('   → Vérifier le format du token JWT');
        print('   → Vérifier que le backend accepte le token');
        print('   → Reconnecter l\'utilisateur\n');
      } else {
        print('   → Erreur HTTP $statusCode');
        print('   → Vérifier que le backend est accessible');
        print('   → Vérifier les CORS sur le backend\n');
      }
      return;
    }

    if (!profileLoad['success']) {
      print('⚠️ ATTENTION: Le profil ne peut pas être chargé');
      print('   → Vérifier que l\'endpoint /users/me existe');
      print('   → Vérifier les permissions de l\'utilisateur\n');
    }

    if (!search['success']) {
      print('⚠️ ATTENTION: La recherche ne fonctionne pas');
      print('   → Vérifier que l\'endpoint /users/autocomplete existe');
      print('   → Vérifier les permissions de recherche\n');
    }

    if (apiConnection['success'] && profileLoad['success'] && search['success']) {
      print('✅ TOUT FONCTIONNE CORRECTEMENT !');
      print('   → L\'authentification est OK');
      print('   → Le profil peut être chargé');
      print('   → La recherche fonctionne\n');
    }

    print('========================================\n');
  }
}
