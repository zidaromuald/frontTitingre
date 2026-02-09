import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Visibilité d'un post
enum PostVisibility {
  public('public'),
  friends('friends'),
  private('private'),
  // Valeurs pour les posts de groupe
  membresOnly('membres_only'),  // Visible par tous les membres du groupe
  adminsOnly('admins_only');    // Visible uniquement par les admins du groupe

  final String value;
  const PostVisibility(this.value);

  factory PostVisibility.fromString(String value) {
    // Gérer l'ancien format 'groupe' pour compatibilité
    if (value == 'groupe') {
      return PostVisibility.membresOnly;
    }
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
    // DEBUG: Afficher les données du post
    print('📦 [PostModel] fromJson - post id=${json['id']}');
    print('📦 [PostModel] groupe_id=${json['groupe_id']}, visibility=${json['visibility']}');

    // DEBUG: Afficher si c'est un post de groupe
    if (json['groupe_id'] != null) {
      print('📦 [PostModel] ⚠️ POST DE GROUPE DÉTECTÉ - groupe_id=${json['groupe_id']}');
    }

    // Gérer plusieurs formats de réponse pour l'auteur
    // Le backend peut retourner: author (objet), user (objet), societe (objet), ou author_name (string)
    Map<String, dynamic>? authorData = json['author'] ?? json['user'] ?? json['societe'];

    // Si pas d'objet author mais author_name est présent, créer un objet author
    if (authorData == null && json['author_name'] != null) {
      authorData = {'name': json['author_name']};
    }

    // DEBUG author
    if (authorData != null) {
      print('📦 [PostModel] author présent: $authorData');
    } else {
      print('📦 [PostModel] ⚠️ author est NULL - author_id=${json['author_id']}, author_type=${json['author_type']}');
    }

    // CORRECTION: Récupérer authorId et authorType depuis author si les champs directs sont null
    // Le backend peut retourner author_id/author_type OU author.id/author.type
    int? authorId = json['author_id'];
    String? authorTypeStr = json['author_type'];

    // Si author_id est null mais author.id existe, utiliser author.id
    if (authorId == null && authorData != null && authorData['id'] != null) {
      authorId = authorData['id'];
      print('📦 [PostModel] ✅ authorId récupéré depuis author.id: $authorId');
    }

    // Si author_type est null mais author.type existe, utiliser author.type
    if (authorTypeStr == null && authorData != null && authorData['type'] != null) {
      authorTypeStr = authorData['type'];
      print('📦 [PostModel] ✅ authorType récupéré depuis author.type: $authorTypeStr');
    }

    print('📦 [PostModel] Final: authorId=$authorId, authorType=$authorTypeStr');

    // S'assurer que authorId n'est pas null (requis par le modèle)
    if (authorId == null) {
      print('❌ [PostModel] ERREUR CRITIQUE: authorId est null pour post ${json['id']}!');
      authorId = 0; // Valeur par défaut pour éviter le crash
    }

    // Combiner tous les médias (images, videos, audios, documents) en une seule liste
    List<String>? mediaUrls;

    // Vérifier d'abord media_urls (ancien format)
    if (json['media_urls'] != null) {
      mediaUrls = List<String>.from(json['media_urls']);
    } else {
      // Nouveau format: combiner images, videos, audios, documents
      final List<String> allMedia = [];

      if (json['images'] != null && json['images'] is List) {
        allMedia.addAll(List<String>.from(json['images']));
      }
      if (json['videos'] != null && json['videos'] is List) {
        allMedia.addAll(List<String>.from(json['videos']));
      }
      if (json['audios'] != null && json['audios'] is List) {
        allMedia.addAll(List<String>.from(json['audios']));
      }
      if (json['documents'] != null && json['documents'] is List) {
        allMedia.addAll(List<String>.from(json['documents']));
      }

      if (allMedia.isNotEmpty) {
        mediaUrls = allMedia;
      }
    }

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
      authorId: authorId, // Garanti non-null après la vérification ci-dessus
      authorType: AuthorType.fromString(authorTypeStr ?? 'User'),
      author: authorData, // Utiliser authorData qui gère plusieurs formats
      groupe: json['groupe'],
      mediaUrls: mediaUrls,
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

  /// Vérifier si l'utilisateur connecté est le propriétaire du post
  bool isOwner(int userId, AuthorType userType) {
    return authorId == userId && authorType == userType;
  }

  String getAuthorName() {
    // Si author est null, afficher un fallback basé sur authorType
    if (author == null) {
      print('⚠️ [PostModel] getAuthorName: author est NULL pour post $id');
      // Fallback: afficher le type d'auteur
      if (authorType == AuthorType.societe) {
        return 'Société #$authorId';
      } else {
        return 'Utilisateur #$authorId';
      }
    }

    if (authorType == AuthorType.user) {
      // Gérer plusieurs formats de réponse pour les utilisateurs
      // IMPORTANT: Convertir explicitement en String pour éviter BindingError sur Flutter Web
      final prenom = (author!['prenom'] ?? author!['first_name'] ?? '').toString();
      final nom = (author!['nom'] ?? author!['last_name'] ?? author!['name'] ?? '').toString();

      if (prenom.isEmpty && nom.isEmpty) {
        return (author!['username'] ?? author!['email'] ?? 'Utilisateur #$authorId').toString();
      }
      return '$prenom $nom'.trim();
    } else {
      // Gérer plusieurs formats de réponse pour les sociétés
      // IMPORTANT: Convertir explicitement en String pour éviter BindingError sur Flutter Web
      return (author!['nom'] ??
             author!['nom_societe'] ??
             author!['name'] ??
             author!['raison_sociale'] ??
             'Société #$authorId').toString();
    }
  }

  String? getAuthorPhoto() {
    if (author == null) return null;
    if (authorType == AuthorType.user) {
      final profile = author!['profile'];
      if (profile != null && profile['photo'] != null) {
        final photo = profile['photo'] as String;
        if (photo.startsWith('http')) return photo;
        return 'https://api.titingre.com/storage/$photo';
      }
    } else {
      final profile = author!['profile'];
      if (profile != null && profile['logo'] != null) {
        final logo = profile['logo'] as String;
        if (logo.startsWith('http')) return logo;
        return 'https://api.titingre.com/storage/$logo';
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
  final List<String>? images;
  final List<String>? audios;
  final List<String>? videos;
  final List<String>? documents;

  CreatePostDto({
    required this.contenu,
    this.visibility = PostVisibility.public,
    this.groupeId,
    this.images,
    this.audios,
    this.videos,
    this.documents,
  });

  Map<String, dynamic> toJson() {
    return {
      'contenu': contenu,
      'visibility': visibility.value,
      if (groupeId != null) 'groupe_id': groupeId,
      if (images != null && images!.isNotEmpty) 'images': images,
      if (audios != null && audios!.isNotEmpty) 'audios': audios,
      if (videos != null && videos!.isNotEmpty) 'videos': videos,
      if (documents != null && documents!.isNotEmpty) 'documents': documents,
    };
  }
}

/// DTO pour mettre à jour un post
class UpdatePostDto {
  final String? contenu;
  final PostVisibility? visibility;
  final List<String>? images;
  final List<String>? audios;
  final List<String>? videos;
  final List<String>? documents;

  UpdatePostDto({
    this.contenu,
    this.visibility,
    this.images,
    this.audios,
    this.videos,
    this.documents,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (contenu != null) data['contenu'] = contenu;
    if (visibility != null) data['visibility'] = visibility!.value;
    if (images != null) data['images'] = images;
    if (audios != null) data['audios'] = audios;
    if (videos != null) data['videos'] = videos;
    if (documents != null) data['documents'] = documents;
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
    // Debug: afficher les données envoyées
    final jsonData = dto.toJson();
    print('📤 [PostService] createPost - DTO: $jsonData');
    print('📤 [PostService] groupe_id dans DTO: ${jsonData['groupe_id']}');
    print('📤 [PostService] visibility dans DTO: ${jsonData['visibility']}');

    // Debug: vérifier l'utilisateur connecté
    try {
      final meResponse = await ApiService.get('/auth/me');
      if (meResponse.statusCode == 200) {
        final meData = jsonDecode(meResponse.body);
        print('👤 [PostService] Utilisateur connecté: ${meData['data'] ?? meData}');
      }
    } catch (e) {
      print('⚠️ [PostService] Impossible de récupérer l\'utilisateur: $e');
    }

    final response = await ApiService.post('/posts', dto.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      final postData = jsonResponse['data'];
      print('📥 [PostService] Post créé avec succès:');
      print('   - id: ${postData['id']}');
      print('   - groupe_id dans réponse: ${postData['groupe_id']}');
      print('   - visibility dans réponse: ${postData['visibility']}');
      return PostModel.fromJson(postData);
    } else {
      final error = jsonDecode(response.body);
      print('❌ [PostService] Erreur création post: ${response.statusCode} - ${response.body}');
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
  /// IMPORTANT: Filtre les posts de groupe côté client
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

    // Ajouter include=author pour récupérer les données complètes de l'auteur
    params['include'] = 'author';

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final response = await ApiService.get('/posts/feed/public?$queryString');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];

      // Debug: afficher les données d'auteur pour le premier post
      if (postsData.isNotEmpty) {
        print('🔍 [PostService] Debug premier post du feed:');
        print('   - id: ${postsData[0]['id']}');
        print('   - author_id: ${postsData[0]['author_id']}');
        print('   - author_type: ${postsData[0]['author_type']}');
        print('   - author: ${postsData[0]['author']}');
        print('   - toutes les clés: ${postsData[0].keys.toList()}');
      }

      // Debug: afficher les données de TOUS les posts avec leur groupe_id
      print('📋 [PostService] Liste complète des posts reçus:');
      for (var post in postsData) {
        final hasGroupeId = post['groupe_id'] != null;
        final visibility = post['visibility'];
        print('   📄 Post ${post['id']}: groupe_id=${post['groupe_id']}, visibility=$visibility ${hasGroupeId ? "⚠️ POST DE GROUPE" : ""}');
      }

      // Convertir en PostModel puis filtrer les posts de groupe
      final allPosts = postsData.map((json) => PostModel.fromJson(json)).toList();
      final publicPosts = allPosts.where((post) => post.groupeId == null).toList();

      print('📊 [PostService] Feed public: ${allPosts.length} posts reçus, ${publicPosts.length} après filtrage des groupes');

      return publicPosts;
    } else {
      throw Exception('Erreur de récupération du feed public');
    }
  }

  // ==========================================================================
  // POSTS PAR AUTEUR/GROUPE
  // ==========================================================================

  /// Récupérer les posts d'un auteur spécifique
  /// GET /posts/author/:type/:id
  /// IMPORTANT: Par défaut, exclut les posts de groupe (includeGroupPosts=false)
  /// [authorData] - Données optionnelles de l'auteur à injecter si le backend ne les retourne pas
  static Future<List<PostModel>> getPostsByAuthor(
    int authorId,
    AuthorType authorType, {
    bool includeGroupPosts = false,
    Map<String, dynamic>? authorData,
  }) async {
    final typeString = authorType.value;
    final params = <String, String>{
      'include': 'author', // Inclure les données de l'auteur (nom, photo, etc.)
    };
    if (includeGroupPosts) {
      params['includeGroupPosts'] = 'true';
    }
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final response = await ApiService.get(
      '/posts/author/$typeString/$authorId?$queryString',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];

      // DEBUG: Afficher les données brutes pour vérifier groupe_id
      print('📋 [PostService] Posts auteur $authorId - données brutes:');
      for (var post in postsData) {
        print('   📄 Post ${post['id']}: groupe_id=${post['groupe_id']}, visibility=${post['visibility']}');
      }

      // CORRECTION: Si le backend ne retourne pas les données d'auteur, les injecter
      // On connaît l'auteur car c'est dans l'URL de la requête
      final postsWithAuthor = postsData.map((json) {
        final postJson = Map<String, dynamic>.from(json);

        // Si author_id est null, injecter l'authorId connu
        if (postJson['author_id'] == null) {
          postJson['author_id'] = authorId;
          print('📦 [PostService] Injection author_id=$authorId pour post ${postJson['id']}');
        }

        // Si author_type est null, injecter l'authorType connu
        if (postJson['author_type'] == null) {
          postJson['author_type'] = typeString;
          print('📦 [PostService] Injection author_type=$typeString pour post ${postJson['id']}');
        }

        // Si author est null et qu'on a des données d'auteur, les injecter
        if (postJson['author'] == null && authorData != null) {
          postJson['author'] = {
            'id': authorId,
            'type': typeString,
            ...authorData,
          };
          print('📦 [PostService] Injection author data pour post ${postJson['id']}');
        } else if (postJson['author'] == null) {
          // Créer un auteur minimal avec juste l'ID et le type
          postJson['author'] = {
            'id': authorId,
            'type': typeString,
          };
        }

        return postJson;
      }).toList();

      final allPosts = postsWithAuthor.map((json) => PostModel.fromJson(json)).toList();

      // Si includeGroupPosts=false, filtrer les posts de groupe côté client (sécurité supplémentaire)
      if (!includeGroupPosts) {
        final nonGroupPosts = allPosts.where((post) => post.groupeId == null).toList();
        final groupPosts = allPosts.where((post) => post.groupeId != null).toList();
        print('📊 [PostService] Posts auteur $authorId: ${allPosts.length} total, ${groupPosts.length} de groupe, ${nonGroupPosts.length} publics');
        if (groupPosts.isNotEmpty) {
          print('🚫 [PostService] Posts de groupe filtrés:');
          for (var post in groupPosts) {
            print('   - Post ${post.id} -> groupe_id=${post.groupeId}');
          }
        }
        return nonGroupPosts;
      }

      return allPosts;
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

  /// Récupérer les posts d'une société
  /// Utilise GET /posts/author/Societe/:societeId (l'endpoint /posts/societe/:id n'existe pas encore)
  static Future<List<PostModel>> getPostsBySociete(int societeId) async {
    print('📤 [PostService] getPostsBySociete($societeId) - utilise getPostsByAuthor');

    // L'endpoint /posts/societe/:id n'existe pas côté backend
    // On utilise /posts/author/Societe/:id qui fonctionne
    return getPostsByAuthor(
      societeId,
      AuthorType.societe,
      includeGroupPosts: false, // Exclure les posts de groupe
    );
  }

  /// Récupérer le feed personnalisé (posts des personnes/sociétés suivies)
  /// GET /posts/feed/my-feed
  /// Nécessite authentification
  /// IMPORTANT: Filtre les posts de groupe côté client
  static Future<List<PostModel>> getMyFeed({
    int limit = 20,
    int offset = 0,
    bool onlyWithMedia = false,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'onlyWithMedia': onlyWithMedia.toString(),
      'include': 'author', // Inclure les données de l'auteur (nom, photo, etc.)
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final response = await ApiService.get('/posts/feed/my-feed?$queryString');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> postsData = jsonResponse['data'];

      // Convertir en PostModel puis filtrer les posts de groupe
      final allPosts = postsData.map((json) => PostModel.fromJson(json)).toList();
      final nonGroupPosts = allPosts.where((post) => post.groupeId == null).toList();

      print('📊 [PostService] MyFeed: ${allPosts.length} posts reçus, ${nonGroupPosts.length} après filtrage des groupes');

      return nonGroupPosts;
    } else {
      throw Exception('Erreur de récupération du feed');
    }
  }

  /// Récupérer le feed personnalisé (mes posts + posts des suivis)
  /// Combine les posts personnels avec le feed des personnes suivies
  /// pour garantir que l'utilisateur voit toujours ses propres posts
  static Future<List<PostModel>> getPersonalizedFeed({
    int limit = 20,
    int offset = 0,
    bool onlyWithMedia = false,
  }) async {
    try {
      // Déterminer le type d'utilisateur depuis le cache local
      final prefs = await SharedPreferences.getInstance();
      final cachedUserType = prefs.getString('user_type');

      print('📤 [PostService] getPersonalizedFeed - cachedUserType: $cachedUserType');

      // Utiliser le bon endpoint selon le type d'utilisateur
      // /auth/me ne fonctionne pas pour les sociétés (retourne 403)
      final String meEndpoint;
      if (cachedUserType == 'societe') {
        meEndpoint = '/societes/me';  // Endpoint spécifique pour les sociétés
      } else {
        meEndpoint = '/users/me';  // Endpoint spécifique pour les users
      }

      final meResponse = await ApiService.get(meEndpoint);
      if (meResponse.statusCode != 200) {
        print('⚠️ [PostService] Endpoint $meEndpoint a échoué (${meResponse.statusCode}), fallback vers getMyFeed');
        // Fallback: utiliser getMyFeed si on ne peut pas récupérer l'utilisateur
        return getMyFeed(limit: limit, offset: offset, onlyWithMedia: onlyWithMedia);
      }

      final meData = jsonDecode(meResponse.body);
      final userData = meData['data'] ?? meData;
      final userId = userData['id'];
      // Déterminer le type depuis le cache ou la réponse
      final userType = cachedUserType == 'societe' ? 'Societe' : (userData['type'] ?? 'User');

      print('📤 [PostService] getPersonalizedFeed - userId: $userId, userType: $userType');

      // Préparer les données d'auteur pour l'injection dans les posts
      // Cela permet d'afficher le nom de l'utilisateur même si le backend ne le retourne pas
      final Map<String, dynamic> authorData = {
        'id': userId,
        'type': userType,
        // Pour un User
        if (userType == 'User') 'nom': userData['nom'] ?? '',
        if (userType == 'User') 'prenom': userData['prenom'] ?? '',
        if (userType == 'User') 'email': userData['email'],
        if (userType == 'User') 'profile': userData['profile'],
        // Pour une Societe
        if (userType == 'Societe') 'nom': userData['nom'] ?? userData['nom_societe'] ?? '',
        if (userType == 'Societe') 'profile': userData['profile'],
      };

      print('📤 [PostService] authorData préparé: $authorData');

      // Charger en parallèle : mes posts + feed des suivis + feed public
      final results = await Future.wait([
        // Mes propres posts (avec données d'auteur injectées)
        getPostsByAuthor(
          userId,
          userType == 'Societe' ? AuthorType.societe : AuthorType.user,
          authorData: authorData,
        ),
        // Feed des personnes que je suis
        getMyFeed(limit: limit, offset: offset, onlyWithMedia: onlyWithMedia),
        // Feed public (pour garantir la visibilité des posts publics des sociétés)
        getPublicFeed(limit: limit, offset: offset, onlyWithMedia: onlyWithMedia),
      ]);

      final myPosts = results[0];
      final followingFeed = results[1];
      final publicFeed = results[2];

      print('📥 [PostService] Mes posts: ${myPosts.length}, Feed suivis: ${followingFeed.length}, Public: ${publicFeed.length}');

      // Combiner et dédupliquer par ID
      final Map<int, PostModel> postsMap = {};

      // Ajouter mes posts en premier
      for (final post in myPosts) {
        postsMap[post.id] = post;
      }

      // Ajouter les posts des suivis (sans écraser mes posts)
      for (final post in followingFeed) {
        if (!postsMap.containsKey(post.id)) {
          postsMap[post.id] = post;
        }
      }

      // Ajouter les posts publics (sans écraser ceux déjà présents)
      for (final post in publicFeed) {
        if (!postsMap.containsKey(post.id)) {
          postsMap[post.id] = post;
        }
      }

      // Trier par date de création (plus récent en premier)
      final combinedPosts = postsMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Appliquer la pagination
      final startIndex = offset;
      final endIndex = (offset + limit).clamp(0, combinedPosts.length);

      if (startIndex >= combinedPosts.length) {
        return [];
      }

      final paginatedPosts = combinedPosts.sublist(startIndex, endIndex);
      print('📥 [PostService] Feed combiné: ${paginatedPosts.length} posts');

      return paginatedPosts;
    } catch (e) {
      print('❌ [PostService] Erreur getPersonalizedFeed: $e');
      // Fallback: utiliser getMyFeed en cas d'erreur
      return getMyFeed(limit: limit, offset: offset, onlyWithMedia: onlyWithMedia);
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
