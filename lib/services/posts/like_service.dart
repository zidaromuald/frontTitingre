import 'dart:convert';
import '../api_service.dart';

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle de like
class LikeModel {
  final int id;
  final int postId;
  final DateTime createdAt;

  // Informations sur l'auteur du like
  final int? authorId;
  final String? authorType; // 'User' ou 'Societe'
  final Map<String, dynamic>? author; // Données complètes de l'auteur

  LikeModel({
    required this.id,
    required this.postId,
    required this.createdAt,
    this.authorId,
    this.authorType,
    this.author,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'],
      postId: json['post_id'],
      createdAt: DateTime.parse(json['created_at']),
      authorId: json['author']?['id'],
      authorType: json['author']?['type'],
      author: json['author'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Méthodes helper
  String getAuthorName() {
    if (author == null) return 'Utilisateur';
    if (authorType == 'User') {
      return '${author!['prenom']} ${author!['nom']}';
    } else {
      return author!['nom_societe'] ?? author!['nom'] ?? 'Société';
    }
  }
}

// ============================================================================
// SERVICE LIKES
// ============================================================================

/// Service pour gérer les likes des posts
class LikeService {
  // ==========================================================================
  // ACTIONS LIKE/UNLIKE
  // ==========================================================================

  /// Liker un post
  /// POST /likes/post/:postId
  /// Nécessite authentification
  static Future<LikeModel> likePost(int postId) async {
    final response = await ApiService.post('/likes/post/$postId', {});

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return LikeModel.fromJson(jsonResponse['like']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors du like');
    }
  }

  /// Retirer son like d'un post
  /// DELETE /likes/post/:postId
  /// Nécessite authentification
  static Future<bool> unlikePost(int postId) async {
    final response = await ApiService.delete('/likes/post/$postId');

    if (response.statusCode == 200 || response.statusCode == 204) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['success'] ?? true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors du unlike');
    }
  }

  /// Toggle like (like si pas liké, unlike si déjà liké)
  /// Combine checkLike + likePost/unlikePost
  static Future<bool> toggleLike(int postId) async {
    final hasLiked = await checkLike(postId);

    if (hasLiked) {
      await unlikePost(postId);
      return false; // Post unliké
    } else {
      await likePost(postId);
      return true; // Post liké
    }
  }

  // ==========================================================================
  // VÉRIFICATION ET RÉCUPÉRATION
  // ==========================================================================

  /// Vérifier si j'ai liké un post
  /// GET /likes/post/:postId/check
  /// Nécessite authentification
  static Future<bool> checkLike(int postId) async {
    final response = await ApiService.get('/likes/post/$postId/check');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['hasLiked'] ?? false;
    } else {
      return false;
    }
  }

  /// Compter les likes d'un post
  static Future<int> countPostLikes(int postId) async {
    final likes = await getPostLikes(postId);
    return likes.length;
  }

  /// Récupérer tous les likes d'un post avec leurs auteurs
  /// GET /likes/post/:postId
  static Future<List<LikeModel>> getPostLikes(int postId) async {
    final response = await ApiService.get('/likes/post/$postId');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> likesData = jsonResponse['likes'];
      return likesData.map((json) => LikeModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des likes');
    }
  }

  /// Récupérer les posts que j'ai likés
  /// GET /likes/my-liked-posts
  /// Nécessite authentification
  static Future<List<Map<String, dynamic>>> getMyLikedPosts() async {
    final response = await ApiService.get('/likes/my-liked-posts');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['posts'];
      return postsData.map((json) => json as Map<String, dynamic>).toList();
    } else {
      throw Exception('Erreur de récupération des posts likés');
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Récupérer la liste des IDs des posts que j'ai likés
  /*static Future<List<int>> getMyLikedPostIds() async {
    try {
      final likedPosts = await getMyLikedPosts();
      return likedPosts.map<int>((post) => post['id'] as int).toList();
    } catch (e) {
      return [];
    }
  }

  /// Vérifier si j'ai liké plusieurs posts à la fois
  /// Utile pour afficher l'état des likes dans une liste
  static Future<Map<int, bool>> checkMultipleLikes(
    List<int> postIds,
  ) async {
    final Map<int, bool> likeStatus = {};

    try {
      final likedPostIds = await getMyLikedPostIds();

      for (final postId in postIds) {
        likeStatus[postId] = likedPostIds.contains(postId);
      }
    } catch (e) {
      // En cas d'erreur, tous les posts sont considérés comme non likés
      for (final postId in postIds) {
        likeStatus[postId] = false;
      }
    }

    return likeStatus;
  }*/
}
