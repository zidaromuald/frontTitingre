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
  final DateTime updatedAt;

  // Informations sur l'auteur
  final int? authorId;
  final String? authorType; // 'User' ou 'Societe'
  final Map<String, dynamic>? author; // Données complètes de l'auteur

  CommentModel({
    required this.id,
    required this.postId,
    required this.contenu,
    required this.createdAt,
    required this.updatedAt,
    this.authorId,
    this.authorType,
    this.author,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      postId: json['post_id'],
      contenu: json['contenu'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorId: json['author']?['id'],
      authorType: json['author']?['type'],
      author: json['author'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'contenu': contenu,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Méthodes helper
  String getAuthorName() {
    if (author == null) return 'Auteur inconnu';
    if (authorType == 'User') {
      return '${author!['prenom']} ${author!['nom']}';
    } else {
      return author!['nom_societe'] ?? author!['nom'] ?? 'Société';
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

  CreateCommentDto({
    required this.postId,
    required this.contenu,
  });

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'contenu': contenu,
    };
  }
}

/// DTO pour modifier un commentaire
class UpdateCommentDto {
  final String contenu;

  UpdateCommentDto({
    required this.contenu,
  });

  Map<String, dynamic> toJson() {
    return {
      'contenu': contenu,
    };
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
    final response = await ApiService.post('/commentaires', dto.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return CommentModel.fromJson(jsonResponse['commentaire']);
    } else {
      final error = jsonDecode(response.body);
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
    final response = await ApiService.get('/commentaires/post/$postId');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> commentsData = jsonResponse['commentaires'];
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
      final postComments = myComments
          .where((comment) => comment.postId == postId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return postComments.isNotEmpty ? postComments.first : null;
    } catch (e) {
      return null;
    }
  }
}
