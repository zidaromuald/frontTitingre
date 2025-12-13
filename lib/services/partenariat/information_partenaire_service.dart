import 'dart:convert';
import 'package:gestauth_clean/services/api_service.dart';
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart';

/// Service pour gérer les informations partenaires
/// Basé sur le contrôleur backend: InformationPartenaireController
class InformationPartenaireService {
  static const String baseUrl = '/informations-partenaires';

  /// Créer une information partenaire
  /// POST /informations-partenaires
  static Future<InformationPartenaireModel> createInformation(
    CreateInformationPartenaireDto dto,
  ) async {
    final response = await ApiService.post(
      baseUrl,
      dto.toJson(),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return InformationPartenaireModel.fromJson(data['data']);
    } else {
      throw Exception('Erreur lors de la création de l\'information: ${response.body}');
    }
  }

  /// Récupérer toutes les informations d'une page
  /// GET /informations-partenaires/page/:pageId
  static Future<List<InformationPartenaireModel>> getInformationsForPage(
    int pageId,
  ) async {
    final response = await ApiService.get('$baseUrl/page/$pageId');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> informationsData = data['data'];
      return informationsData
          .map((json) => InformationPartenaireModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur lors du chargement des informations: ${response.body}');
    }
  }

  /// Récupérer une information par ID
  /// GET /informations-partenaires/:id
  static Future<InformationPartenaireModel> getInformationById(int id) async {
    final response = await ApiService.get('$baseUrl/$id');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return InformationPartenaireModel.fromJson(data['data']);
    } else {
      throw Exception('Erreur lors du chargement de l\'information: ${response.body}');
    }
  }

  /// Modifier une information (uniquement ses propres infos)
  /// PUT /informations-partenaires/:id
  static Future<InformationPartenaireModel> updateInformation(
    int id,
    UpdateInformationPartenaireDto dto,
  ) async {
    final response = await ApiService.put(
      '$baseUrl/$id',
      dto.toJson(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return InformationPartenaireModel.fromJson(data['data']);
    } else {
      throw Exception('Erreur lors de la modification de l\'information: ${response.body}');
    }
  }

  /// Supprimer une information (uniquement le créateur)
  /// DELETE /informations-partenaires/:id
  static Future<void> deleteInformation(int id) async {
    final response = await ApiService.delete('$baseUrl/$id');

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de l\'information: ${response.body}');
    }
  }
}

/// ========================================
/// Modèles de données
/// ========================================

/// Modèle pour une information partenaire
class InformationPartenaireModel {
  final int id;
  final int pageId;
  final int createdById;
  final String createdByType; // 'User' ou 'Societe'
  final String titre;
  final String? contenu;
  final String? typeInfo; // ex: 'localite', 'contact', 'superficie', etc.
  final int? ordre; // Ordre d'affichage
  final DateTime createdAt;
  final DateTime updatedAt;

  // Informations du créateur (incluses par le backend)
  final String? createdByNom;
  final String? createdByPrenom;
  final String? createdByEmail;

  InformationPartenaireModel({
    required this.id,
    required this.pageId,
    required this.createdById,
    required this.createdByType,
    required this.titre,
    this.contenu,
    this.typeInfo,
    this.ordre,
    required this.createdAt,
    required this.updatedAt,
    this.createdByNom,
    this.createdByPrenom,
    this.createdByEmail,
  });

  factory InformationPartenaireModel.fromJson(Map<String, dynamic> json) {
    return InformationPartenaireModel(
      id: json['id'],
      pageId: json['pageId'] ?? json['page_id'],
      createdById: json['createdById'] ?? json['created_by_id'],
      createdByType: json['createdByType'] ?? json['created_by_type'],
      titre: json['titre'],
      contenu: json['contenu'],
      typeInfo: json['typeInfo'] ?? json['type_info'],
      ordre: json['ordre'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
      createdByNom: json['createdBy']?['nom'] ?? json['created_by_nom'],
      createdByPrenom: json['createdBy']?['prenom'] ?? json['created_by_prenom'],
      createdByEmail: json['createdBy']?['email'] ?? json['created_by_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageId': pageId,
      'createdById': createdById,
      'createdByType': createdByType,
      'titre': titre,
      'contenu': contenu,
      'typeInfo': typeInfo,
      'ordre': ordre,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdByNom': createdByNom,
      'createdByPrenom': createdByPrenom,
      'createdByEmail': createdByEmail,
    };
  }

  /// Obtenir le nom complet du créateur
  String getCreatorName() {
    if (createdByType == 'User' && createdByNom != null && createdByPrenom != null) {
      return '$createdByPrenom $createdByNom';
    } else if (createdByType == 'Societe' && createdByNom != null) {
      return createdByNom!;
    }
    return 'Inconnu';
  }

  /// Vérifier si l'utilisateur actuel est le créateur
  bool isCreatedByMe(int myId, String myType) {
    return createdById == myId && createdByType == myType;
  }
}

/// ========================================
/// DTOs (Data Transfer Objects)
/// ========================================

/// DTO pour créer une information partenaire
/// Conforme au backend NestJS: CreateInformationPartenaireDto
class CreateInformationPartenaireDto {
  final int pagePartenaritId;        // page_partenariat_id
  final int partenaireId;            // partenaire_id (ID du User ou Societe)
  final String partenaireType;       // partenaire_type: 'User' ou 'Societe'
  final String nomAffichage;         // nom_affichage
  final String? description;         // Description du partenaire
  final String? logoUrl;             // logo_url
  final String? localite;            // Localité
  final String? adresseComplete;     // adresse_complete
  final String? numeroTelephone;     // numero_telephone
  final String? emailContact;        // email_contact
  final String secteurActivite;      // secteur_activite (obligatoire)

  // Champs spécifiques Agriculture
  final String? superficie;          // Superficie cultivée
  final String? typeCulture;         // type_culture
  final String? maisonEtablissement; // maison_etablissement
  final String? contactControleur;   // contact_controleur

  // Champs spécifiques Entreprise
  final String? siegeSocial;         // siege_social
  final String? dateCreation;        // date_creation (ISO string)
  final List<String>? certificats;   // Liste des certificats
  final String? numeroRegistration;  // numero_registration
  final double? capitalSocial;       // capital_social
  final double? chiffreAffaires;     // chiffre_affaires

  // Champs communs
  final int? nombreEmployes;         // nombre_employes
  final String? typeOrganisation;    // type_organisation
  final String? modifiablePar;       // modifiable_par: 'USER' | 'SOCIETE' | 'LES_DEUX'
  final bool? visibleSurPage;        // visible_sur_page
  final Map<String, dynamic>? metadata; // Métadonnées additionnelles

  CreateInformationPartenaireDto({
    required this.pagePartenaritId,
    required this.partenaireId,
    required this.partenaireType,
    required this.nomAffichage,
    this.description,
    this.logoUrl,
    this.localite,
    this.adresseComplete,
    this.numeroTelephone,
    this.emailContact,
    required this.secteurActivite,
    this.superficie,
    this.typeCulture,
    this.maisonEtablissement,
    this.contactControleur,
    this.siegeSocial,
    this.dateCreation,
    this.certificats,
    this.numeroRegistration,
    this.capitalSocial,
    this.chiffreAffaires,
    this.nombreEmployes,
    this.typeOrganisation,
    this.modifiablePar,
    this.visibleSurPage,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'page_partenariat_id': pagePartenaritId,
      'partenaire_id': partenaireId,
      'partenaire_type': partenaireType,
      'nom_affichage': nomAffichage,
      'secteur_activite': secteurActivite,
    };

    // Champs optionnels de base
    if (description != null) map['description'] = description;
    if (logoUrl != null) map['logo_url'] = logoUrl;
    if (localite != null) map['localite'] = localite;
    if (adresseComplete != null) map['adresse_complete'] = adresseComplete;
    if (numeroTelephone != null) map['numero_telephone'] = numeroTelephone;
    if (emailContact != null) map['email_contact'] = emailContact;

    // Champs Agriculture
    if (superficie != null) map['superficie'] = superficie;
    if (typeCulture != null) map['type_culture'] = typeCulture;
    if (maisonEtablissement != null) map['maison_etablissement'] = maisonEtablissement;
    if (contactControleur != null) map['contact_controleur'] = contactControleur;

    // Champs Entreprise
    if (siegeSocial != null) map['siege_social'] = siegeSocial;
    if (dateCreation != null) map['date_creation'] = dateCreation;
    if (certificats != null) map['certificats'] = certificats;
    if (numeroRegistration != null) map['numero_registration'] = numeroRegistration;
    if (capitalSocial != null) map['capital_social'] = capitalSocial;
    if (chiffreAffaires != null) map['chiffre_affaires'] = chiffreAffaires;

    // Champs communs
    if (nombreEmployes != null) map['nombre_employes'] = nombreEmployes;
    if (typeOrganisation != null) map['type_organisation'] = typeOrganisation;
    if (modifiablePar != null) map['modifiable_par'] = modifiablePar;
    if (visibleSurPage != null) map['visible_sur_page'] = visibleSurPage;
    if (metadata != null) map['metadata'] = metadata;

    return map;
  }
}

/// DTO pour modifier une information partenaire
/// Conforme au backend NestJS: UpdateInformationPartenaireDto
class UpdateInformationPartenaireDto {
  final String? nomAffichage;        // nom_affichage
  final String? description;         // Description du partenaire
  final String? logoUrl;             // logo_url
  final String? localite;            // Localité
  final String? adresseComplete;     // adresse_complete
  final String? numeroTelephone;     // numero_telephone
  final String? emailContact;        // email_contact
  final String? secteurActivite;     // secteur_activite

  // Champs spécifiques Agriculture
  final String? superficie;          // Superficie cultivée
  final String? typeCulture;         // type_culture
  final String? maisonEtablissement; // maison_etablissement
  final String? contactControleur;   // contact_controleur

  // Champs spécifiques Entreprise
  final String? siegeSocial;         // siege_social
  final String? dateCreation;        // date_creation (ISO string)
  final List<String>? certificats;   // Liste des certificats
  final String? numeroRegistration;  // numero_registration
  final double? capitalSocial;       // capital_social
  final double? chiffreAffaires;     // chiffre_affaires

  // Champs communs
  final int? nombreEmployes;         // nombre_employes
  final String? typeOrganisation;    // type_organisation
  final String? modifiablePar;       // modifiable_par: 'USER' | 'SOCIETE' | 'LES_DEUX'
  final bool? visibleSurPage;        // visible_sur_page
  final Map<String, dynamic>? metadata; // Métadonnées additionnelles

  UpdateInformationPartenaireDto({
    this.nomAffichage,
    this.description,
    this.logoUrl,
    this.localite,
    this.adresseComplete,
    this.numeroTelephone,
    this.emailContact,
    this.secteurActivite,
    this.superficie,
    this.typeCulture,
    this.maisonEtablissement,
    this.contactControleur,
    this.siegeSocial,
    this.dateCreation,
    this.certificats,
    this.numeroRegistration,
    this.capitalSocial,
    this.chiffreAffaires,
    this.nombreEmployes,
    this.typeOrganisation,
    this.modifiablePar,
    this.visibleSurPage,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    // Champs de base
    if (nomAffichage != null) map['nom_affichage'] = nomAffichage;
    if (description != null) map['description'] = description;
    if (logoUrl != null) map['logo_url'] = logoUrl;
    if (localite != null) map['localite'] = localite;
    if (adresseComplete != null) map['adresse_complete'] = adresseComplete;
    if (numeroTelephone != null) map['numero_telephone'] = numeroTelephone;
    if (emailContact != null) map['email_contact'] = emailContact;
    if (secteurActivite != null) map['secteur_activite'] = secteurActivite;

    // Champs Agriculture
    if (superficie != null) map['superficie'] = superficie;
    if (typeCulture != null) map['type_culture'] = typeCulture;
    if (maisonEtablissement != null) map['maison_etablissement'] = maisonEtablissement;
    if (contactControleur != null) map['contact_controleur'] = contactControleur;

    // Champs Entreprise
    if (siegeSocial != null) map['siege_social'] = siegeSocial;
    if (dateCreation != null) map['date_creation'] = dateCreation;
    if (certificats != null) map['certificats'] = certificats;
    if (numeroRegistration != null) map['numero_registration'] = numeroRegistration;
    if (capitalSocial != null) map['capital_social'] = capitalSocial;
    if (chiffreAffaires != null) map['chiffre_affaires'] = chiffreAffaires;

    // Champs communs
    if (nombreEmployes != null) map['nombre_employes'] = nombreEmployes;
    if (typeOrganisation != null) map['type_organisation'] = typeOrganisation;
    if (modifiablePar != null) map['modifiable_par'] = modifiablePar;
    if (visibleSurPage != null) map['visible_sur_page'] = visibleSurPage;
    if (metadata != null) map['metadata'] = metadata;

    return map;
  }
}
