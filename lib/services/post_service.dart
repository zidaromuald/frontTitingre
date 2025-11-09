import 'dart:convert';
import 'api_service.dart';
import 'unified_auth_service.dart';

/// Modèle de Post
class Post {
  final int id;
  final String contenu;
  final int? groupeId;
  final int? societeId;
  final String visibility;
  final List<String>? images;
  final List<String>? videos;
  final List<String>? audios;
  final int postedById;
  final String postedByType;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.contenu,
    this.groupeId,
    this.societeId,
    required this.visibility,
    this.images,
    this.videos,
    this.audios,
    required this.postedById,
    required this.postedByType,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      contenu: json['contenu'],
      groupeId: json['groupe_id'],
      societeId: json['societe_id'],
      visibility: json['visibility'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      videos: json['videos'] != null ? List<String>.from(json['videos']) : null,
      audios: json['audios'] != null ? List<String>.from(json['audios']) : null,
      postedById: json['posted_by_id'],
      postedByType: json['posted_by_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Service pour gérer les Posts
class PostService {
  /// Créer un nouveau post
  ///
  /// Scénarios possibles :
  /// 1. User - Public : groupeId = null, societeId = null, visibility = 'public'
  /// 2. User → Groupe : groupeId = X, societeId = null, visibility = 'groupe'
  /// 3. User → Société : groupeId = null, societeId = X, visibility = 'societe'
  /// 4. Société - Public : groupeId = null, societeId = null, visibility = 'public'
  /// 5. Société → Groupe : groupeId = X, societeId = null, visibility = 'groupe'
  static Future<Post> createPost({
    required String contenu,
    int? groupeId,
    int? societeId,
    String? visibility,
    List<String>? images,
    List<String>? videos,
    List<String>? audios,
  }) async {
    // Validation : pas de groupe ET société en même temps
    if (groupeId != null && societeId != null) {
      throw Exception('Impossible de publier dans un groupe ET une société');
    }

    final data = {
      'contenu': contenu,
      if (groupeId != null) 'groupe_id': groupeId,
      if (societeId != null) 'societe_id': societeId,
      if (visibility != null) 'visibility': visibility,
      if (images != null && images.isNotEmpty) 'images': images,
      if (videos != null && videos.isNotEmpty) 'videos': videos,
      if (audios != null && audios.isNotEmpty) 'audios': audios,
    };

    final response = await ApiService.post('/posts', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return Post.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de création du post');
    }
  }

  /// Récupérer un post par ID
  static Future<Post> getPostById(int id) async {
    final response = await ApiService.get('/posts/$id');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return Post.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Post introuvable');
    }
  }

  /// Récupérer le feed public (tous les posts publics)
  static Future<List<Post>> getPublicFeed({
    int limit = 20,
    int offset = 0,
    bool onlyWithMedia = false,
  }) async {
    final queryParams = '?limit=$limit&offset=$offset&onlyWithMedia=$onlyWithMedia';
    final response = await ApiService.get('/posts/feed/public$queryParams');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération du feed');
    }
  }

  /// Récupérer les posts d'un groupe
  static Future<List<Post>> getPostsByGroupe(int groupeId, {String? visibility}) async {
    final queryParams = visibility != null ? '?visibility=$visibility' : '';
    final response = await ApiService.get('/posts/groupe/$groupeId$queryParams');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des posts du groupe');
    }
  }

  /// Récupérer les posts d'une société
  static Future<List<Post>> getPostsBySociete(int societeId, {String? visibility}) async {
    final queryParams = visibility != null ? '?visibility=$visibility' : '';
    final response = await ApiService.get('/posts/societe/$societeId$queryParams');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des posts de la société');
    }
  }

  /// Récupérer les posts d'un auteur (User ou Société)
  static Future<List<Post>> getPostsByAuthor({
    required int authorId,
    required String authorType, // 'User' ou 'Societe'
    bool includeGroupPosts = false,
  }) async {
    final queryParams = '?includeGroupPosts=$includeGroupPosts';
    final response = await ApiService.get('/posts/author/$authorType/$authorId$queryParams');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des posts de l\'auteur');
    }
  }

  /// Rechercher des posts
  static Future<List<Post>> searchPosts({
    String? query,
    int? authorId,
    String? authorType,
    int? groupeId,
    String? visibility,
    bool? hasMedia,
  }) async {
    final params = <String>[];
    if (query != null) params.add('q=$query');
    if (authorId != null) params.add('authorId=$authorId');
    if (authorType != null) params.add('authorType=$authorType');
    if (groupeId != null) params.add('groupeId=$groupeId');
    if (visibility != null) params.add('visibility=$visibility');
    if (hasMedia != null) params.add('hasMedia=$hasMedia');

    final queryParams = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await ApiService.get('/posts/search/query$queryParams');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de recherche');
    }
  }

  /// Mettre à jour un post
  static Future<Post> updatePost(int id, Map<String, dynamic> updates) async {
    final response = await ApiService.put('/posts/$id', updates);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return Post.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de mise à jour');
    }
  }

  /// Supprimer un post
  static Future<void> deletePost(int id) async {
    final response = await ApiService.delete('/posts/$id');

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erreur de suppression du post');
    }
  }

  /// Épingler/désépingler un post
  static Future<void> togglePin(int id) async {
    final response = await ApiService.put('/posts/$id/pin', {});

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de l\'épinglage');
    }
  }

  /// Partager un post (incrémenter le compteur)
  static Future<void> sharePost(int id) async {
    final response = await ApiService.post('/posts/$id/share', {});

    if (response.statusCode != 200) {
      throw Exception('Erreur lors du partage');
    }
  }

  /// Récupérer les posts tendances
  static Future<List<Post>> getTrendingPosts({int limit = 10}) async {
    final response = await ApiService.get('/posts/trending/top?limit=$limit');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];
      return postsData.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des posts tendances');
    }
  }
}
