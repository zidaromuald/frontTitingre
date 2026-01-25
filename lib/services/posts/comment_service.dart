import 'dart:convert';
import '../api_service.dart';

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle de commentaire
class CommentModel {
  final int id;
  final int postId;
  final String contenu;
  final DateTime createdAt;
  final DateTime?
  updatedAt; // Optionnel car pas toujours retourné par le backend

  // Informations sur l'auteur
  final int? authorId;
  final String? authorType; // 'User' ou 'Societe'
  final Map<String, dynamic>? author; // Données complètes de l'auteur

  CommentModel({
    required this.id,
    required this.postId,
    required this.contenu,
    required this.createdAt,
    this.updatedAt,
    this.authorId,
    this.authorType,
    this.author,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // DEBUG: Afficher les données brutes du commentaire
    print('💬 [CommentModel] fromJson - comment id=${json['id']}');
    print('💬 [CommentModel] json keys: ${json.keys.toList()}');
    print('💬 [CommentModel] author présent: ${json['author'] != null}');
    print('💬 [CommentModel] user présent: ${json['user'] != null}');
    if (json['author'] != null) {
      print('💬 [CommentModel] author data: ${json['author']}');
    }
    if (json['user'] != null) {
      print('💬 [CommentModel] user data: ${json['user']}');
    }

    // Gérer plusieurs formats de réponse pour l'auteur
    final authorData = json['author'] ?? json['user'] ?? json['societe'];

    // Extraire l'ID et le type de l'auteur
    int? authorId;
    String? authorType;

    if (authorData != null) {
      authorId = authorData['id'];
      // Le type peut être dans 'type', 'author_type' ou déduit de la présence de certaines clés
      authorType = authorData['type'] ?? authorData['author_type'];
      if (authorType == null) {
        // Déduire le type selon les clés présentes
        if (authorData['nom_societe'] != null ||
            authorData['raison_sociale'] != null) {
          authorType = 'Societe';
        } else {
          authorType = 'User';
        }
      }
    } else {
      // Fallback: utiliser les champs séparés si présents
      authorId = json['author_id'] ?? json['user_id'];
      authorType = json['author_type'] ?? json['user_type'] ?? 'User';
    }

    return CommentModel(
      id: json['id'],
      postId: json['post_id'],
      contenu: json['contenu'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      authorId: authorId,
      authorType: authorType,
      author: authorData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'contenu': contenu,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Méthodes helper
  String getAuthorName() {
    print('💬 [CommentModel] getAuthorName - author: $author, authorType: $authorType');

    if (author == null) {
      print('💬 [CommentModel] author est NULL, retourne "Auteur inconnu"');
      return 'Auteur inconnu';
    }

    print('💬 [CommentModel] author keys: ${author!.keys.toList()}');

    if (authorType == 'User') {
      // Gérer plusieurs formats de réponse pour les utilisateurs
      final prenom = author!['prenom'] ?? author!['first_name'] ?? '';
      final nom = author!['nom'] ?? author!['last_name'] ?? author!['name'] ?? '';

      print('💬 [CommentModel] prenom: "$prenom", nom: "$nom"');

      if (prenom.toString().isEmpty && nom.toString().isEmpty) {
        final fallback = author!['username'] ?? author!['email'] ?? 'Utilisateur';
        print('💬 [CommentModel] prenom/nom vides, fallback: $fallback');
        return fallback;
      }
      final result = '$prenom $nom'.trim();
      print('💬 [CommentModel] Nom final: "$result"');
      return result;
    } else {
      // Gérer plusieurs formats de réponse pour les sociétés
      final result = author!['nom'] ??
          author!['nom_societe'] ??
          author!['name'] ??
          author!['raison_sociale'] ??
          'Société';
      print('💬 [CommentModel] Société nom: $result');
      return result;
    }
  }

  bool isAuthor(int userId, String userType) {
    return authorId == userId && authorType == userType;
  }
}

/// DTO pour créer un commentaire
class CreateCommentDto {
  final int postId;
  final String contenu;

  CreateCommentDto({required this.postId, required this.contenu});

  Map<String, dynamic> toJson() {
    return {'post_id': postId, 'contenu': contenu};
  }
}

/// DTO pour modifier un commentaire
class UpdateCommentDto {
  final String contenu;

  UpdateCommentDto({required this.contenu});

  Map<String, dynamic> toJson() {
    return {'contenu': contenu};
  }
}

// ============================================================================
// SERVICE COMMENTAIRES
// ============================================================================

/// Service pour gérer les commentaires des posts
class CommentService {
  // ==========================================================================
  // CRÉATION ET MODIFICATION
  // ==========================================================================

  /// Créer un commentaire sur un post
  /// POST /commentaires
  /// Nécessite authentification
  static Future<CommentModel> createComment(CreateCommentDto dto) async {
    print('📤 [CommentService] POST /commentaires - DTO: ${dto.toJson()}');
    final response = await ApiService.post('/commentaires', dto.toJson());
    print('📥 [CommentService] Response status: ${response.statusCode}');
    print('📥 [CommentService] Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      final commentData = jsonResponse['commentaire'] ?? jsonResponse['data'];
      print('📥 [CommentService] Comment data: $commentData');

      if (commentData == null) {
        print(
          '❌ [CommentService] Aucune donnée de commentaire dans la réponse',
        );
        throw Exception(
          'Format de réponse invalide: aucune donnée de commentaire',
        );
      }

      return CommentModel.fromJson(commentData);
    } else {
      final error = jsonDecode(response.body);
      print(
        '❌ [CommentService] Erreur création commentaire: ${error['message']}',
      );
      throw Exception(error['message'] ?? 'Erreur de création du commentaire');
    }
  }

  /// Modifier un commentaire
  /// PUT /commentaires/:id
  /// Nécessite authentification (et être l'auteur)
  static Future<CommentModel> updateComment(
    int commentId,
    UpdateCommentDto dto,
  ) async {
    final response = await ApiService.put(
      '/commentaires/$commentId',
      dto.toJson(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return CommentModel.fromJson(jsonResponse['commentaire']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de mise à jour du commentaire',
      );
    }
  }

  /// Supprimer un commentaire
  /// DELETE /commentaires/:id
  /// Nécessite authentification (et être l'auteur)
  static Future<void> deleteComment(int commentId) async {
    final response = await ApiService.delete('/commentaires/$commentId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de suppression du commentaire',
      );
    }
  }

  // ==========================================================================
  // RÉCUPÉRATION DES COMMENTAIRES
  // ==========================================================================

  /// Récupérer tous les commentaires d'un post avec leurs auteurs
  /// GET /commentaires/post/:postId
  static Future<List<CommentModel>> getPostComments(int postId) async {
    // Ajouter include=author pour récupérer les données de l'auteur du commentaire
    final response = await ApiService.get('/commentaires/post/$postId?include=author');

    print('💬 [CommentService] getPostComments response: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> commentsData = jsonResponse['commentaires'];

      // Debug: afficher les données du premier commentaire
      if (commentsData.isNotEmpty) {
        print('💬 [CommentService] Premier commentaire: ${commentsData.first}');
      }

      return commentsData.map((json) => CommentModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des commentaires');
    }
  }

  /// Récupérer mes commentaires
  /// GET /commentaires/my-comments
  /// Nécessite authentification
  static Future<List<CommentModel>> getMyComments() async {
    final response = await ApiService.get('/commentaires/my-comments');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> commentsData = jsonResponse['commentaires'];
      return commentsData.map((json) => CommentModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération de mes commentaires');
    }
  }

  /// Récupérer les posts que j'ai commentés
  /// GET /commentaires/my-commented-posts
  /// Nécessite authentification
  static Future<List<Map<String, dynamic>>> getMyCommentedPosts() async {
    final response = await ApiService.get('/commentaires/my-commented-posts');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['posts'];
      return postsData.map((json) => json as Map<String, dynamic>).toList();
    } else {
      throw Exception('Erreur de récupération des posts commentés');
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Compter les commentaires d'un post
  static Future<int> countPostComments(int postId) async {
    final comments = await getPostComments(postId);
    return comments.length;
  }

  /// Vérifier si j'ai commenté un post
  static Future<bool> hasCommented(int postId) async {
    try {
      final myComments = await getMyComments();
      return myComments.any((comment) => comment.postId == postId);
    } catch (e) {
      return false;
    }
  }

  /// Récupérer mon dernier commentaire sur un post
  static Future<CommentModel?> getMyLastCommentOnPost(int postId) async {
    try {
      final myComments = await getMyComments();
      final postComments =
          myComments.where((comment) => comment.postId == postId).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return postComments.isNotEmpty ? postComments.first : null;
    } catch (e) {
      return null;
    }
  }
}
