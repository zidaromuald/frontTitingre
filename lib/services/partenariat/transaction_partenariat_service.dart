import 'dart:convert';
import 'package:gestauth_clean/services/api_service.dart';

/// Règles de gestion:
/// - SOCIÉTÉ: Peut créer, modifier, supprimer des transactions (si pas validées)
/// - USER: Peut valider les transactions, consulter les transactions en attente
class TransactionPartenaritService {
  static const String baseUrl = '/transactions-partenariat';

  /// Créer une transaction (Société uniquement)
  /// POST /transactions-partenariat
  ///
  /// ⚠️ Restriction: Seule la Société peut créer des transactions
  static Future<TransactionPartenaritModel> createTransaction(
    CreateTransactionPartenaritDto dto,
  ) async {
    final response = await ApiService.post(baseUrl, dto.toJson());

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return TransactionPartenaritModel.fromJson(data['data']);
    } else {
      throw Exception(
        'Erreur lors de la création de la transaction: ${response.body}',
      );
    }
  }

  /// Récupérer les transactions d'une page (Société uniquement)
  /// GET /transactions-partenariat/page/:pageId
  ///
  /// ⚠️ Restriction: Seule la Société peut accéder à cette route
  /// Les Users doivent utiliser getPendingTransactions()
  static Future<List<TransactionPartenaritModel>> getTransactionsForPage(
    int pageId,
  ) async {
    final response = await ApiService.get('$baseUrl/page/$pageId');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> transactionsData = data['data'];
      return transactionsData
          .map((json) => TransactionPartenaritModel.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Erreur lors du chargement des transactions: ${response.body}',
      );
    }
  }

  /// Récupérer les transactions en attente de validation (User uniquement)
  /// GET /transactions-partenariat/pending
  ///
  /// ⚠️ Restriction: Seul un User peut accéder aux transactions en attente
  static Future<List<TransactionPartenaritModel>>
  getPendingTransactions() async {
    final response = await ApiService.get('$baseUrl/pending');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> transactionsData = data['data'];
      return transactionsData
          .map((json) => TransactionPartenaritModel.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Erreur lors du chargement des transactions en attente: ${response.body}',
      );
    }
  }

  /// Compter les transactions en attente (User uniquement)
  /// GET /transactions-partenariat/pending/count
  ///
  /// ⚠️ Restriction: Seul un User peut compter les transactions en attente
  /// Utile pour afficher un badge de notification
  static Future<int> countPendingTransactions() async {
    final response = await ApiService.get('$baseUrl/pending/count');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['count'] as int;
    } else {
      throw Exception(
        'Erreur lors du comptage des transactions: ${response.body}',
      );
    }
  }

  /// Récupérer une transaction par ID
  /// GET /transactions-partenariat/:id
  static Future<TransactionPartenaritModel> getTransactionById(int id) async {
    final response = await ApiService.get('$baseUrl/$id');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return TransactionPartenaritModel.fromJson(data['data']);
    } else {
      throw Exception(
        'Erreur lors du chargement de la transaction: ${response.body}',
      );
    }
  }

  /// Modifier une transaction (Société uniquement, si pas validée)
  /// PUT /transactions-partenariat/:id
  ///
  /// ⚠️ Restrictions:
  /// - Seule la Société peut modifier
  /// - Transaction ne doit pas être validée
  static Future<TransactionPartenaritModel> updateTransaction(
    int id,
    UpdateTransactionPartenaritDto dto,
  ) async {
    final response = await ApiService.put('$baseUrl/$id', dto.toJson());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return TransactionPartenaritModel.fromJson(data['data']);
    } else {
      throw Exception(
        'Erreur lors de la modification de la transaction: ${response.body}',
      );
    }
  }

  /// Valider une transaction (User uniquement)
  /// PUT /transactions-partenariat/:id/validate
  ///
  /// ⚠️ Restriction: Seul un User peut valider des transactions
  static Future<TransactionPartenaritModel> validateTransaction(
    int id,
    ValidateTransactionDto dto,
  ) async {
    final response = await ApiService.put(
      '$baseUrl/$id/validate',
      dto.toJson(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return TransactionPartenaritModel.fromJson(data['data']);
    } else {
      throw Exception(
        'Erreur lors de la validation de la transaction: ${response.body}',
      );
    }
  }

  /// Supprimer une transaction (Société uniquement, si pas validée)
  /// DELETE /transactions-partenariat/:id
  ///
  /// ⚠️ Restrictions:
  /// - Seule la Société peut supprimer
  /// - Transaction ne doit pas être validée
  static Future<void> deleteTransaction(int id) async {
    final response = await ApiService.delete('$baseUrl/$id');

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur lors de la suppression de la transaction: ${response.body}',
      );
    }
  }
}

/// ========================================
/// Modèles de données
/// ========================================

/// Modèle pour une transaction partenariat
/// Stocke les données BRUTES du backend et fournit des getters pour le formatage
class TransactionPartenaritModel {
  final int id;
  final int pageId;
  final int societeId;
  final int userId;

  // Données BRUTES du backend
  final String produit; // Ex: "Café arabica"
  final int quantite; // Ex: 2038
  final double prixUnitaire; // Ex: 1000.0
  final DateTime dateDebut; // Date de début
  final DateTime dateFin; // Date de fin
  final String? periodeLabel; // Label optionnel: "Janvier à Mars 2023"
  final String? unite; // Ex: "Kg", "Litres"
  final String? categorie; // Ex: "Agriculture"

  final String statut; // 'en_attente' | 'validee' | 'rejetee'
  final DateTime? dateValidation;
  final String? commentaire;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Informations de la société (incluses par le backend)
  final String? societeNom;
  final String? societeSecteur;

  // Informations du user (incluses par le backend)
  final String? userNom;
  final String? userPrenom;
  final String? userEmail;

  TransactionPartenaritModel({
    required this.id,
    required this.pageId,
    required this.societeId,
    required this.userId,
    required this.produit,
    required this.quantite,
    required this.prixUnitaire,
    required this.dateDebut,
    required this.dateFin,
    this.periodeLabel,
    this.unite,
    this.categorie,
    required this.statut,
    this.dateValidation,
    this.commentaire,
    required this.createdAt,
    required this.updatedAt,
    this.societeNom,
    this.societeSecteur,
    this.userNom,
    this.userPrenom,
    this.userEmail,
  });

  factory TransactionPartenaritModel.fromJson(Map<String, dynamic> json) {
    return TransactionPartenaritModel(
      id: json['id'],
      pageId: json['pageId'] ?? json['page_id'],
      societeId: json['societeId'] ?? json['societe_id'],
      userId: json['userId'] ?? json['user_id'],
      produit: json['produit'],
      quantite: json['quantite'] is int
          ? json['quantite']
          : int.parse(json['quantite'].toString()),
      prixUnitaire: json['prixUnitaire'] is double
          ? json['prixUnitaire']
          : json['prix_unitaire'] is double
          ? json['prix_unitaire']
          : double.parse(
              (json['prixUnitaire'] ?? json['prix_unitaire']).toString(),
            ),
      dateDebut: DateTime.parse(json['dateDebut'] ?? json['date_debut']),
      dateFin: DateTime.parse(json['dateFin'] ?? json['date_fin']),
      periodeLabel: json['periodeLabel'] ?? json['periode_label'],
      unite: json['unite'],
      categorie: json['categorie'],
      statut: json['statut'],
      dateValidation: json['dateValidation'] != null
          ? DateTime.parse(json['dateValidation'])
          : null,
      commentaire: json['commentaire'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
      societeNom: json['societe']?['nom'] ?? json['societe_nom'],
      societeSecteur:
          json['societe']?['secteurActivite'] ?? json['societe_secteur'],
      userNom: json['user']?['nom'] ?? json['user_nom'],
      userPrenom: json['user']?['prenom'] ?? json['user_prenom'],
      userEmail: json['user']?['email'] ?? json['user_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageId': pageId,
      'societeId': societeId,
      'userId': userId,
      'produit': produit,
      'quantite': quantite,
      'prixUnitaire': prixUnitaire,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'periodeLabel': periodeLabel,
      'unite': unite,
      'categorie': categorie,
      'statut': statut,
      'dateValidation': dateValidation?.toIso8601String(),
      'commentaire': commentaire,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ========================================
  // Getters pour le formatage d'affichage
  // ========================================

  /// Obtenir la période formatée (ex: "Janvier à Mars 2023")
  /// Utilise periodeLabel si disponible, sinon formate les dates
  String get periodeFormatee {
    if (periodeLabel != null && periodeLabel!.isNotEmpty) {
      return periodeLabel!;
    }

    // Formater les dates manuellement
    final mois = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    final debutMois = mois[dateDebut.month - 1];
    final finMois = mois[dateFin.month - 1];

    if (dateDebut.year == dateFin.year) {
      if (dateDebut.month == dateFin.month) {
        return '$debutMois ${dateDebut.year}';
      }
      return '$debutMois à $finMois ${dateDebut.year}';
    }
    return '$debutMois ${dateDebut.year} à $finMois ${dateFin.year}';
  }

  /// Obtenir la quantité formatée (ex: "2038 Kg")
  String get quantiteFormatee {
    if (unite != null && unite!.isNotEmpty) {
      return '$quantite $unite';
    }
    return quantite.toString();
  }

  /// Obtenir le prix unitaire formaté (ex: "1000 CFA")
  String get prixUnitaireFormate {
    // Formater le nombre avec séparateurs de milliers
    final formatter = _formatNumber(prixUnitaire);
    return '$formatter CFA';
  }

  /// Obtenir le prix total formaté (ex: "2,038,000 CFA")
  String get prixTotalFormate {
    final total = quantite * prixUnitaire;
    final formatter = _formatNumber(total);
    return '$formatter CFA';
  }

  /// Obtenir le prix total (valeur numérique)
  double get prixTotal => quantite * prixUnitaire;

  /// Formater un nombre avec séparateurs de milliers
  String _formatNumber(double number) {
    final parts = number.toStringAsFixed(0).split('.');
    final integerPart = parts[0];

    // Ajouter des séparateurs de milliers
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    return buffer.toString();
  }

  // ========================================
  // Méthodes d'aide
  // ========================================

  /// Vérifier si la transaction est en attente de validation
  bool isEnAttente() => statut == 'en_attente';

  /// Vérifier si la transaction est validée
  bool isValidee() => statut == 'validee';

  /// Vérifier si la transaction est rejetée
  bool isRejetee() => statut == 'rejetee';

  /// Obtenir le nom complet de l'utilisateur
  String getUserName() {
    if (userNom != null && userPrenom != null) {
      return '$userPrenom $userNom';
    }
    return 'Utilisateur inconnu';
  }

  /// Obtenir une couleur selon le statut
  int getStatusColor() {
    switch (statut) {
      case 'en_attente':
        return 0xFFFFA500; // Orange
      case 'validee':
        return 0xFF28A745; // Vert
      case 'rejetee':
        return 0xFFDC3545; // Rouge
      default:
        return 0xFF8D8D8D; // Gris
    }
  }

  /// Obtenir le libellé du statut
  String getStatusLabel() {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'validee':
        return 'Validée';
      case 'rejetee':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }
}

/// ========================================
/// DTOs (Data Transfer Objects)
/// ========================================

/// DTO pour créer une transaction (Société uniquement)
/// Conforme au backend NestJS: CreateTransactionPartenaritDto
class CreateTransactionPartenaritDto {
  final int pagePartenaritId; // page_partenariat_id dans le backend
  final String produit; // Nom du produit/service
  final int quantite; // Quantité (nombre entier)
  final double prixUnitaire; // Prix unitaire (nombre décimal)
  final String dateDebut; // Date de début (ISO string)
  final String dateFin; // Date de fin (ISO string)
  final String? periodeLabel; // Label de la période (ex: "Janvier à Mars 2023")
  final String? unite; // Unité de mesure (ex: "Kg", "Litres")
  final String? categorie; // Catégorie du produit
  final String? statut; // Statut: 'en_attente' | 'validee' | 'rejetee'
  final Map<String, dynamic>? metadata; // Métadonnées additionnelles

  CreateTransactionPartenaritDto({
    required this.pagePartenaritId,
    required this.produit,
    required this.quantite,
    required this.prixUnitaire,
    required this.dateDebut,
    required this.dateFin,
    this.periodeLabel,
    this.unite,
    this.categorie,
    this.statut,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'page_partenariat_id': pagePartenaritId,
      'produit': produit,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'date_debut': dateDebut,
      'date_fin': dateFin,
    };

    if (periodeLabel != null) map['periode_label'] = periodeLabel;
    if (unite != null) map['unite'] = unite;
    if (categorie != null) map['categorie'] = categorie;
    if (statut != null) map['statut'] = statut;
    if (metadata != null) map['metadata'] = metadata;

    return map;
  }
}

/// DTO pour modifier une transaction (Société uniquement)
/// Conforme au backend NestJS: UpdateTransactionPartenaritDto
class UpdateTransactionPartenaritDto {
  final String? produit; // Nom du produit/service
  final int? quantite; // Quantité (nombre entier)
  final double? prixUnitaire; // Prix unitaire (nombre décimal)
  final String? dateDebut; // Date de début (ISO string)
  final String? dateFin; // Date de fin (ISO string)
  final String? periodeLabel; // Label de la période
  final String? unite; // Unité de mesure
  final String? categorie; // Catégorie du produit
  final String? statut; // Statut: 'en_attente' | 'validee' | 'rejetee'
  final Map<String, dynamic>? metadata; // Métadonnées additionnelles

  UpdateTransactionPartenaritDto({
    this.produit,
    this.quantite,
    this.prixUnitaire,
    this.dateDebut,
    this.dateFin,
    this.periodeLabel,
    this.unite,
    this.categorie,
    this.statut,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (produit != null) map['produit'] = produit;
    if (quantite != null) map['quantite'] = quantite;
    if (prixUnitaire != null) map['prix_unitaire'] = prixUnitaire;
    if (dateDebut != null) map['date_debut'] = dateDebut;
    if (dateFin != null) map['date_fin'] = dateFin;
    if (periodeLabel != null) map['periode_label'] = periodeLabel;
    if (unite != null) map['unite'] = unite;
    if (categorie != null) map['categorie'] = categorie;
    if (statut != null) map['statut'] = statut;
    if (metadata != null) map['metadata'] = metadata;

    return map;
  }
}

/// DTO pour valider une transaction (User uniquement)
/// Conforme au backend NestJS: ValidateTransactionDto
class ValidateTransactionDto {
  final String? commentaire; // Commentaire optionnel lors de la validation

  ValidateTransactionDto({this.commentaire});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (commentaire != null) map['commentaire'] = commentaire;

    return map;
  }
}
