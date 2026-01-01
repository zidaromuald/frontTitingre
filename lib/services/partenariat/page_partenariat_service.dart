import 'dart:convert';
import '../api_service.dart';

/// ============================================================================
/// SERVICE PAGE PARTENARIAT
/// ============================================================================

/// Service pour gérer les pages de partenariat entre User et Société
/// Une page partenariat est créée automatiquement lors de l'upgrade premium
class PagePartenaritService {
  /// Récupérer une page partenariat par userId et societeId
  /// GET /pages-partenariat?userId=X&societeId=Y
  ///
  /// Cette méthode permet de récupérer le pagePartenaritId nécessaire
  /// pour créer des transactions et informations partenaires
  static Future<PagePartenaritModel> getPageByUserAndSociete({
    required int userId,
    required int societeId,
  }) async {
    final response = await ApiService.get(
      '/pages-partenariat?userId=$userId&societeId=$societeId',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return PagePartenaritModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Page partenariat introuvable');
    }
  }

  /// Récupérer une page partenariat par ID
  /// GET /pages-partenariat/:id
  static Future<PagePartenaritModel> getPageById(int pageId) async {
    final response = await ApiService.get('/pages-partenariat/$pageId');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return PagePartenaritModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Page partenariat introuvable');
    }
  }

  /// Récupérer toutes les pages partenariat d'une société
  /// GET /pages-partenariat/societe/:societeId
  ///
  /// Utile pour la société qui veut voir tous ses partenariats actifs
  static Future<List<PagePartenaritModel>> getPagesBySociete(
    int societeId,
  ) async {
    final response = await ApiService.get(
      '/pages-partenariat/societe/$societeId',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> pagesData = jsonResponse['data'];
      return pagesData
          .map((json) => PagePartenaritModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des pages partenariat');
    }
  }

  /// Récupérer toutes les pages partenariat d'un user
  /// GET /pages-partenariat/user/:userId
  ///
  /// Utile pour l'utilisateur qui veut voir tous ses partenariats actifs
  static Future<List<PagePartenaritModel>> getPagesByUser(int userId) async {
    final response = await ApiService.get(
      '/pages-partenariat/user/$userId',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> pagesData = jsonResponse['data'];
      return pagesData
          .map((json) => PagePartenaritModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des pages partenariat');
    }
  }
}

/// ============================================================================
/// MODÈLE PAGE PARTENARIAT
/// ============================================================================

/// Modèle pour une page de partenariat entre User et Société
class PagePartenaritModel {
  final int id;
  final int userId;
  final int societeId;
  final String titre;
  final String visibilite; // 'prive' | 'public'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations optionnelles (peuvent être incluses)
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? societe;

  PagePartenaritModel({
    required this.id,
    required this.userId,
    required this.societeId,
    required this.titre,
    required this.visibilite,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.societe,
  });

  factory PagePartenaritModel.fromJson(Map<String, dynamic> json) {
    return PagePartenaritModel(
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      societeId: json['societeId'] ?? json['societe_id'],
      titre: json['titre'],
      visibilite: json['visibilite'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
      user: json['user'],
      societe: json['societe'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'societeId': societeId,
      'titre': titre,
      'visibilite': visibilite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Vérifier si la page est publique
  bool isPublic() => visibilite == 'public';

  /// Vérifier si la page est privée
  bool isPrive() => visibilite == 'prive';
}
