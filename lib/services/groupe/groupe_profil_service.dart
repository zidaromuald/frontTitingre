import 'dart:convert';
import '../api_service.dart';
import 'groupe_service.dart'; // Import pour accéder aux modèles

// ============================================================================
// SERVICE PROFIL GROUPE
// ============================================================================

/// Service pour gérer le profil enrichi des groupes
/// Correspond au GroupeProfilController backend
class GroupeProfilService {
  // ==========================================================================
  // CONSULTER LE PROFIL
  // ==========================================================================

  /// Récupérer le profil enrichi d'un groupe
  /// GET /groupes/:groupeId/profil
  /// Nécessite authentification
  static Future<GroupeProfilModel> getProfil(int groupeId) async {
    final response = await ApiService.get('/groupes/$groupeId/profil');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeProfilModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Erreur de récupération du profil');
    }
  }

  // ==========================================================================
  // METTRE À JOUR LE PROFIL
  // ==========================================================================

  /// Mettre à jour le profil d'un groupe (admin uniquement)
  /// PUT /groupes/:groupeId/profil
  /// Nécessite authentification + être admin
  static Future<GroupeProfilModel> updateProfil(
    int groupeId, {
    String? photoCouverture,
    String? logo,
    String? description,
    String? regles,
    List<String>? tags,
    String? localisation,
    String? languePrincipale,
    String? secteurActivite,
  }) async {
    final data = <String, dynamic>{};

    if (photoCouverture != null) data['photo_couverture'] = photoCouverture;
    if (logo != null) data['logo'] = logo;
    if (description != null) data['description'] = description;
    if (regles != null) data['regles'] = regles;
    if (tags != null) data['tags'] = tags;
    if (localisation != null) data['localisation'] = localisation;
    if (languePrincipale != null) data['langue_principale'] = languePrincipale;
    if (secteurActivite != null) data['secteur_activite'] = secteurActivite;

    final response = await ApiService.put(
      '/groupes/$groupeId/profil',
      data,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeProfilModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de mise à jour du profil');
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES POUR MISE À JOUR PARTIELLE
  // ==========================================================================

  /// Mettre à jour uniquement la photo de couverture
  static Future<GroupeProfilModel> updatePhotoCouverture(
    int groupeId,
    String photoCouverture,
  ) async {
    return updateProfil(groupeId, photoCouverture: photoCouverture);
  }

  /// Mettre à jour uniquement le logo
  static Future<GroupeProfilModel> updateLogo(
    int groupeId,
    String logo,
  ) async {
    return updateProfil(groupeId, logo: logo);
  }

  /// Mettre à jour uniquement la description
  static Future<GroupeProfilModel> updateDescription(
    int groupeId,
    String description,
  ) async {
    return updateProfil(groupeId, description: description);
  }

  /// Mettre à jour uniquement les règles
  static Future<GroupeProfilModel> updateRegles(
    int groupeId,
    String regles,
  ) async {
    return updateProfil(groupeId, regles: regles);
  }

  /// Mettre à jour uniquement les tags
  static Future<GroupeProfilModel> updateTags(
    int groupeId,
    List<String> tags,
  ) async {
    return updateProfil(groupeId, tags: tags);
  }

  /// Ajouter un tag
  static Future<GroupeProfilModel> addTag(int groupeId, String tag) async {
    final profil = await getProfil(groupeId);
    final tags = profil.tags ?? [];
    if (!tags.contains(tag)) {
      tags.add(tag);
      return updateTags(groupeId, tags);
    }
    return profil;
  }

  /// Retirer un tag
  static Future<GroupeProfilModel> removeTag(int groupeId, String tag) async {
    final profil = await getProfil(groupeId);
    final tags = profil.tags ?? [];
    tags.remove(tag);
    return updateTags(groupeId, tags);
  }

  /// Mettre à jour uniquement la localisation
  static Future<GroupeProfilModel> updateLocalisation(
    int groupeId,
    String localisation,
  ) async {
    return updateProfil(groupeId, localisation: localisation);
  }

  /// Mettre à jour uniquement la langue principale
  static Future<GroupeProfilModel> updateLanguePrincipale(
    int groupeId,
    String languePrincipale,
  ) async {
    return updateProfil(groupeId, languePrincipale: languePrincipale);
  }

  /// Mettre à jour uniquement le secteur d'activité
  static Future<GroupeProfilModel> updateSecteurActivite(
    int groupeId,
    String secteurActivite,
  ) async {
    return updateProfil(groupeId, secteurActivite: secteurActivite);
  }

  // ==========================================================================
  // MÉTHODES DE VALIDATION
  // ==========================================================================

  /// Vérifier si le profil est complet (champs essentiels)
  static bool isProfilComplete(GroupeProfilModel profil) {
    return profil.description != null &&
        profil.description!.isNotEmpty &&
        profil.tags != null &&
        profil.tags!.isNotEmpty &&
        profil.photoCouverture != null &&
        profil.photoCouverture!.isNotEmpty;
  }

  /// Calculer le score de complétude du profil (0-100)
  static int calculateCompletenessScore(GroupeProfilModel profil) {
    int score = 0;

    // Photo de couverture (15 points)
    if (profil.photoCouverture != null && profil.photoCouverture!.isNotEmpty) {
      score += 15;
    }

    // Logo (15 points)
    if (profil.logo != null && profil.logo!.isNotEmpty) {
      score += 15;
    }

    // Description (20 points)
    if (profil.description != null && profil.description!.isNotEmpty) {
      score += 20;
    }

    // Règles (10 points)
    if (profil.regles != null && profil.regles!.isNotEmpty) {
      score += 10;
    }

    // Tags (15 points)
    if (profil.tags != null && profil.tags!.isNotEmpty) {
      score += 15;
    }

    // Localisation (10 points)
    if (profil.localisation != null && profil.localisation!.isNotEmpty) {
      score += 10;
    }

    // Langue principale (5 points)
    if (profil.languePrincipale != null && profil.languePrincipale!.isNotEmpty) {
      score += 5;
    }

    // Secteur d'activité (10 points)
    if (profil.secteurActivite != null && profil.secteurActivite!.isNotEmpty) {
      score += 10;
    }

    return score;
  }

  /// Obtenir les champs manquants du profil
  static List<String> getMissingFields(GroupeProfilModel profil) {
    final missing = <String>[];

    if (profil.photoCouverture == null || profil.photoCouverture!.isEmpty) {
      missing.add('photo_couverture');
    }
    if (profil.logo == null || profil.logo!.isEmpty) {
      missing.add('logo');
    }
    if (profil.description == null || profil.description!.isEmpty) {
      missing.add('description');
    }
    if (profil.regles == null || profil.regles!.isEmpty) {
      missing.add('regles');
    }
    if (profil.tags == null || profil.tags!.isEmpty) {
      missing.add('tags');
    }
    if (profil.localisation == null || profil.localisation!.isEmpty) {
      missing.add('localisation');
    }
    if (profil.languePrincipale == null || profil.languePrincipale!.isEmpty) {
      missing.add('langue_principale');
    }
    if (profil.secteurActivite == null || profil.secteurActivite!.isEmpty) {
      missing.add('secteur_activite');
    }

    return missing;
  }
}
