import 'dart:convert';
import '../api_service.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Visibilité d'un post
enum PostVisibility {
  public('public'),
  friends('friends'),
  private('private'),
  groupe('groupe');

  final String value;
  const PostVisibility(this.value);

  factory PostVisibility.fromString(String value) {
    return PostVisibility.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PostVisibility.public,
    );
  }
}

/// Type d'auteur (User ou Societe)
enum AuthorType {
  user('User'),
  societe('Societe');

  final String value;
  const AuthorType(this.value);

  factory AuthorType.fromString(String value) {
    return AuthorType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AuthorType.user,
    );
  }
}

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle de post
class PostModel {
  final int id;
  final String contenu;
  final PostVisibility visibility;
  final int? groupeId;
  final bool isPinned;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Informations sur l'auteur
  final int authorId;
  final AuthorType authorType;
  final Map<String, dynamic>? author; // Données complètes de l'auteur

  // Relations optionnelles
  final Map<String, dynamic>? groupe;
  final List<String>? mediaUrls;

  PostModel({
    required this.id,
    required this.contenu,
    required this.visibility,
    this.groupeId,
    required this.isPinned,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.createdAt,
    required this.updatedAt,
    required this.authorId,
    required this.authorType,
    this.author,
    this.groupe,
    this.mediaUrls,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      contenu: json['contenu'] ?? '',
      visibility: PostVisibility.fromString(json['visibility'] ?? 'public'),
      groupeId: json['groupe_id'],
      isPinned: json['is_pinned'] ?? false,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorId: json['author_id'],
      authorType: AuthorType.fromString(json['author_type']),
      author: json['author'],
      groupe: json['groupe'],
      mediaUrls: json['media_urls'] != null
          ? List<String>.from(json['media_urls'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contenu': contenu,
      'visibility': visibility.value,
      if (groupeId != null) 'groupe_id': groupeId,
      'is_pinned': isPinned,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'shares_count': sharesCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'author_id': authorId,
      'author_type': authorType.value,
    };
  }

  // Méthodes helper
  bool hasMedia() => mediaUrls != null && mediaUrls!.isNotEmpty;
  bool isFromGroupe() => groupeId != null;
  bool isPublic() => visibility == PostVisibility.public;

  String getAuthorName() {
    if (author == null) return 'Auteur inconnu';
    if (authorType == AuthorType.user) {
      return '${author!['prenom']} ${author!['nom']}';
    } else {
      return author!['nom'] ?? 'Société';
    }
  }

  String? getAuthorPhoto() {
    if (author == null) return null;
    if (authorType == AuthorType.user) {
      final profile = author!['profile'];
      if (profile != null && profile['photo'] != null) {
        return '/storage/${profile['photo']}';
      }
    } else {
      final profile = author!['profile'];
      if (profile != null && profile['logo'] != null) {
        return '/storage/${profile['logo']}';
      }
    }
    return null;
  }
}

/// DTO pour créer un post
class CreatePostDto {
  final String contenu;
  final PostVisibility visibility;
  final int? groupeId;
  final List<String>? mediaUrls;

  CreatePostDto({
    required this.contenu,
    this.visibility = PostVisibility.public,
    this.groupeId,
    this.mediaUrls,
  });

  Map<String, dynamic> toJson() {
    return {
      'contenu': contenu,
      'visibility': visibility.value,
      if (groupeId != null) 'groupe_id': groupeId,
      if (mediaUrls != null && mediaUrls!.isNotEmpty) 'media_urls': mediaUrls,
    };
  }
}

/// DTO pour mettre à jour un post
class UpdatePostDto {
  final String? contenu;
  final PostVisibility? visibility;
  final List<String>? mediaUrls;

  UpdatePostDto({this.contenu, this.visibility, this.mediaUrls});

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (contenu != null) data['contenu'] = contenu;
    if (visibility != null) data['visibility'] = visibility!.value;
    if (mediaUrls != null) data['media_urls'] = mediaUrls;
    return data;
  }
}

/// DTO pour rechercher des posts
class SearchPostDto {
  final String? query; // Recherche dans le contenu
  final int? authorId;
  final AuthorType? authorType;
  final int? groupeId;
  final int? societeId;
  final PostVisibility? visibility;
  final bool? hasMedia;
  final bool? isPinned;
  final DateTime? startDate;
  final DateTime? endDate;

  SearchPostDto({
    this.query,
    this.authorId,
    this.authorType,
    this.groupeId,
    this.societeId,
    this.visibility,
    this.hasMedia,
    this.isPinned,
    this.startDate,
    this.endDate,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (query != null && query!.isNotEmpty) params['q'] = query!;
    if (authorId != null) params['authorId'] = authorId.toString();
    if (authorType != null) params['authorType'] = authorType!.value;
    if (groupeId != null) params['groupeId'] = groupeId.toString();
    if (societeId != null) params['societeId'] = societeId.toString();
    if (visibility != null) params['visibility'] = visibility!.value;
    if (hasMedia != null) params['hasMedia'] = hasMedia.toString();
    if (isPinned != null) params['isPinned'] = isPinned.toString();
    if (startDate != null) {
      params['startDate'] = startDate!.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      params['endDate'] = endDate!.toIso8601String().split('T')[0];
    }
    return params;
  }
}

// ============================================================================
// SERVICE POSTS
// ============================================================================

/// Service pour gérer les posts (publications)
class PostService {
  // ==========================================================================
  // CRÉATION ET MODIFICATION
  // ==========================================================================

  /// Créer un nouveau post
  /// POST /posts
  /// Nécessite authentification
  static Future<PostModel> createPost(CreatePostDto dto) async {
    final response = await ApiService.post('/posts', dto.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return PostModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de création du post');
    }
  }

  /// Récupérer un post par ID
  /// GET /posts/:id
  static Future<PostModel> getPost(int postId) async {
    final response = await ApiService.get('/posts/$postId');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return PostModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Post introuvable');
    }
  }

  /// Mettre à jour un post
  /// PUT /posts/:id
  /// Nécessite authentification (et être l'auteur)
  static Future<PostModel> updatePost(int postId, UpdatePostDto dto) async {
    final response = await ApiService.put('/posts/$postId', dto.toJson());

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return PostModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de mise à jour du post');
    }
  }

  /// Supprimer un post
  /// DELETE /posts/:id
  /// Nécessite authentification (et être l'auteur)
  static Future<void> deletePost(int postId) async {
    final response = await ApiService.delete('/posts/$postId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de suppression du post');
    }
  }

  // ==========================================================================
  // FEEDS
  // ==========================================================================

  /// Récupérer le feed public (tous les posts publics)
  /// GET /posts/feed/public
  static Future<List<PostModel>> getPublicFeed({
    int limit = 20,
    int offset = 0,
    bool onlyWithMedia = false,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'onlyWithMedia': onlyWithMedia.toString(),
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final response = await ApiService.get('/posts/feed/public?$queryString');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => PostModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération du feed public');
    }
  }

  // ==========================================================================
  // POSTS PAR AUTEUR/GROUPE
  // ==========================================================================

  /// Récupérer les posts d'un auteur spécifique
  /// GET /posts/author/:type/:id
  static Future<List<PostModel>> getPostsByAuthor(
    int authorId,
    AuthorType authorType, {
    bool includeGroupPosts = false,
  }) async {
    final typeString = authorType.value;
    final includeParam = includeGroupPosts ? '?includeGroupPosts=true' : '';
    final response = await ApiService.get(
      '/posts/author/$typeString/$authorId$includeParam',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => PostModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des posts de l\'auteur');
    }
  }

  /// Récupérer les posts d'un groupe
  /// GET /posts/groupe/:id
  static Future<List<PostModel>> getPostsByGroupe(
    int groupeId, {
    PostVisibility? visibility,
  }) async {
    final visibilityParam = visibility != null
        ? '?visibility=${visibility.value}'
        : '';
    final response = await ApiService.get(
      '/posts/groupe/$groupeId$visibilityParam',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => PostModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des posts du groupe');
    }
  }

  /// Récupérer le feed personnalisé (posts des personnes/sociétés suivies)
  /// GET /posts/feed/my-feed
  /// Nécessite authentification
  static Future<List<PostModel>> getMyFeed({
    int limit = 20,
    int offset = 0,
    bool onlyWithMedia = false,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'onlyWithMedia': onlyWithMedia.toString(),
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final response = await ApiService.get('/posts/feed/my-feed?$queryString');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => PostModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération du feed');
    }
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================

  /// Partager un post (incrémenter le compteur)
  /// POST /posts/:id/share
  /// À implémenter côté backend NestJS avant d'utiliser
  /* static Future<void> sharePost(int postId) async {
    final response = await ApiService.post('/posts/$postId/share', {});

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de partage du post');
    }
  } */

  // ==========================================================================
  // RECHERCHE
  // ==========================================================================

  /// Rechercher des posts avec des filtres avancés
  /// GET /posts/search/query
  /// Au moins un paramètre de recherche est requis
  static Future<List<PostModel>> searchPosts(SearchPostDto searchDto) async {
    final params = searchDto.toQueryParams();

    if (params.isEmpty) {
      throw Exception('Au moins un critère de recherche est requis');
    }

    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await ApiService.get('/posts/search/query?$queryString');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      // Vérifier si la recherche a réussi
      if (jsonResponse['success'] == false) {
        throw Exception(jsonResponse['message'] ?? 'Erreur de recherche');
      }

      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => PostModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de recherche');
    }
  }
}
