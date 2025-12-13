import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/posts/post_service.dart';
import 'package:gestauth_clean/services/posts/like_service.dart';
import 'package:gestauth_clean/services/posts/comment_service.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'post_edit_page.dart';

/// Page de détails d'un post avec options de modification/suppression
class PostDetailsPage extends StatefulWidget {
  final int postId;
  const PostDetailsPage({super.key, required this.postId});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  bool _isLoading = true;
  PostModel? _post;
  String? _errorMessage;
  bool _isCurrentUserAuthor = false;
  bool _isDeleting = false;

  // État des likes
  bool _hasLiked = false;
  bool _isLikeLoading = false;
  int _currentLikesCount = 0;

  // État des commentaires
  List<CommentModel> _comments = [];
  bool _isCommentsLoading = false;
  bool _isAddingComment = false;
  final TextEditingController _commentController = TextEditingController();
  int? _currentUserId;
  String? _currentUserType;
  int _currentCommentsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  Future<void> _loadPostDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger le post
      final post = await PostService.getPost(widget.postId);

      // Vérifier si l'utilisateur actuel est l'auteur et récupérer ses infos
      bool isAuthor = false;
      int? userId;
      String? userType;

      try {
        // Essayer de récupérer l'utilisateur connecté
        try {
          final currentUser = await UserAuthService.getMyProfile();
          userId = currentUser.id;
          userType = 'User';
          isAuthor = post.authorType == AuthorType.user && currentUser.id == post.authorId;
        } catch (e) {
          // Essayer avec société
          try {
            final currentSociete = await SocieteAuthService.getMyProfile();
            userId = currentSociete.id;
            userType = 'Societe';
            isAuthor = post.authorType == AuthorType.societe && currentSociete.id == post.authorId;
          } catch (e) {
            // Non connecté
            isAuthor = false;
          }
        }
      } catch (e) {
        // L'utilisateur n'est pas connecté ou erreur
        isAuthor = false;
      }

      if (mounted) {
        setState(() {
          _post = post;
          _isCurrentUserAuthor = isAuthor;
          _currentLikesCount = post.likesCount;
          _currentCommentsCount = post.commentsCount;
          _currentUserId = userId;
          _currentUserType = userType;
          _isLoading = false;
        });

        // Charger l'état du like et les commentaires en parallèle
        _loadLikeStatus();
        _loadComments();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLikeStatus() async {
    try {
      // Charger l'état du like et le nombre exact de likes en parallèle
      final hasLikedFuture = LikeService.checkLike(widget.postId);
      final likesCountFuture = LikeService.countPostLikes(widget.postId);

      final results = await Future.wait([hasLikedFuture, likesCountFuture]);
      final hasLiked = results[0] as bool;
      final exactLikesCount = results[1] as int;

      if (mounted) {
        setState(() {
          _hasLiked = hasLiked;
          _currentLikesCount = exactLikesCount;
        });
      }
    } catch (e) {
      // Si l'utilisateur n'est pas connecté ou erreur, on ignore
      if (mounted) {
        setState(() {
          _hasLiked = false;
          // Garder le compteur du post si on ne peut pas charger le nombre exact
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;

    setState(() => _isLikeLoading = true);

    try {
      final nowLiked = await LikeService.toggleLike(widget.postId);

      // Recharger le nombre exact de likes depuis le serveur
      final exactLikesCount = await LikeService.countPostLikes(widget.postId);

      if (mounted) {
        setState(() {
          _hasLiked = nowLiked;
          _currentLikesCount = exactLikesCount;
          _isLikeLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLikeLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isCommentsLoading = true);

    try {
      // Charger les commentaires et le nombre exact en parallèle
      final commentsFuture = CommentService.getPostComments(widget.postId);
      final commentsCountFuture = CommentService.countPostComments(widget.postId);

      final results = await Future.wait([commentsFuture, commentsCountFuture]);
      final comments = results[0] as List<CommentModel>;
      final exactCommentsCount = results[1] as int;

      if (mounted) {
        setState(() {
          _comments = comments;
          _currentCommentsCount = exactCommentsCount;
          _isCommentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _comments = [];
          _isCommentsLoading = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le commentaire ne peut pas être vide'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isAddingComment = true);

    try {
      final dto = CreateCommentDto(postId: widget.postId, contenu: content);
      await CommentService.createComment(dto);

      _commentController.clear();

      if (mounted) {
        setState(() => _isAddingComment = false);

        // Recharger les commentaires
        _loadComments();

        // Cacher le clavier
        FocusScope.of(context).unfocus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commentaire ajouté'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isAddingComment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le commentaire'),
        content: const Text('Voulez-vous vraiment supprimer ce commentaire ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await CommentService.deleteComment(commentId);
      if (mounted) {
        _loadComments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commentaire supprimé'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _deletePost() async {
    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le post'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce post ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await PostService.deletePost(widget.postId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        // Retourner true pour indiquer que le post a été supprimé
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editPost() async {
    if (_post == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostEditPage(post: _post!),
      ),
    );

    // Si le post a été modifié, recharger les détails
    if (result == true) {
      _loadPostDetails();
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays > 0) {
      return 'Il y a ${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'Il y a ${diff.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Détails du post'),
        actions: _isCurrentUserAuthor && _post != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _isDeleting ? null : _editPost,
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete),
                  onPressed: _isDeleting ? null : _deletePost,
                  tooltip: 'Supprimer',
                ),
              ]
            : null,
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPostDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_post == null) {
      return const Center(
        child: Text('Post introuvable'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec auteur
            _buildAuthorHeader(cs),
            const SizedBox(height: 20),

            // Badge "Votre post" si l'utilisateur est l'auteur
            if (_isCurrentUserAuthor)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Votre post',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isCurrentUserAuthor) const SizedBox(height: 20),

            // Contenu du post
            _buildContent(cs),
            const SizedBox(height: 20),

            // Médias si disponibles
            if (_post!.hasMedia()) _buildMedia(cs),
            if (_post!.hasMedia()) const SizedBox(height: 20),

            // Informations supplémentaires
            _buildMetadata(cs),
            const SizedBox(height: 20),

            // Statistiques
            _buildStats(cs),
            const SizedBox(height: 30),

            // Section commentaires
            _buildCommentsSection(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section
        Row(
          children: [
            Icon(Icons.comment, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Commentaires ($_currentCommentsCount)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Champ pour ajouter un commentaire
        if (_currentUserId != null) ...[
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Écrire un commentaire...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
              suffixIcon: _isAddingComment
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.send, color: cs.primary),
                      onPressed: _addComment,
                      tooltip: 'Envoyer',
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Liste des commentaires
        if (_isCommentsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_comments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: cs.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun commentaire pour le moment',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(
            _comments.length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index < _comments.length - 1 ? 12 : 0),
              child: _buildCommentCard(_comments[index], cs),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentCard(CommentModel comment, ColorScheme cs) {
    final isMyComment = _currentUserId != null &&
        _currentUserType != null &&
        comment.authorId == _currentUserId &&
        comment.authorType == _currentUserType;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMyComment
              ? cs.primary.withOpacity(0.3)
              : cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du commentaire
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primaryContainer,
                child: Icon(
                  comment.authorType == 'Societe' ? Icons.business : Icons.person,
                  size: 18,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.getAuthorName(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (isMyComment) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Vous',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isMyComment)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.red,
                  onPressed: () => _deleteComment(comment.id),
                  tooltip: 'Supprimer',
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Contenu du commentaire
          Text(
            comment.contenu,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface,
              height: 1.4,
            ),
          ),
          // Badge "Modifié" si le commentaire a été modifié
          if (comment.updatedAt != comment.createdAt) ...[
            const SizedBox(height: 6),
            Text(
              'Modifié',
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthorHeader(ColorScheme cs) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: cs.primaryContainer,
          backgroundImage: _post!.getAuthorPhoto() != null
              ? NetworkImage('http://127.0.0.1:8000${_post!.getAuthorPhoto()}')
              : null,
          child: _post!.getAuthorPhoto() == null
              ? Icon(
                  _post!.authorType == AuthorType.societe
                      ? Icons.business
                      : Icons.person,
                  size: 28,
                  color: cs.onPrimaryContainer,
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _post!.getAuthorName(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: cs.onSurface.withOpacity(.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(_post!.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Text(
        _post!.contenu,
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildMedia(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Médias (${_post!.mediaUrls!.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _post!.mediaUrls!.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < _post!.mediaUrls!.length - 1 ? 12 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'http://127.0.0.1:8000${_post!.mediaUrls![index]}',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withOpacity(.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: cs.onSurface.withOpacity(.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Média indisponible',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.visibility,
            'Visibilité',
            _getVisibilityLabel(_post!.visibility),
            cs,
          ),
          if (_post!.isFromGroupe())
            _buildInfoRow(
              Icons.group,
              'Groupe',
              _post!.groupe != null
                  ? _post!.groupe!['nom'] ?? 'Groupe #${_post!.groupeId}'
                  : 'Groupe #${_post!.groupeId}',
              cs,
            ),
          if (_post!.isPinned)
            _buildInfoRow(
              Icons.push_pin,
              'Statut',
              'Épinglé',
              cs,
            ),
          _buildInfoRow(
            Icons.calendar_today,
            'Créé le',
            '${_post!.createdAt.day}/${_post!.createdAt.month}/${_post!.createdAt.year} à ${_post!.createdAt.hour.toString().padLeft(2, '0')}:${_post!.createdAt.minute.toString().padLeft(2, '0')}',
            cs,
          ),
          if (_post!.updatedAt != _post!.createdAt)
            _buildInfoRow(
              Icons.update,
              'Modifié le',
              '${_post!.updatedAt.day}/${_post!.updatedAt.month}/${_post!.updatedAt.year} à ${_post!.updatedAt.hour.toString().padLeft(2, '0')}:${_post!.updatedAt.minute.toString().padLeft(2, '0')}',
              cs,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Bouton Like interactif
          InkWell(
            onTap: _isLikeLoading ? null : _toggleLike,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildLikeButton(cs),
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: cs.outlineVariant,
          ),
          _buildStatItem(
            Icons.chat_bubble,
            _currentCommentsCount.toString(),
            'Commentaires',
            cs,
          ),
          Container(
            height: 40,
            width: 1,
            color: cs.outlineVariant,
          ),
          _buildStatItem(
            Icons.share,
            _post!.sharesCount.toString(),
            'Partages',
            cs,
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton(ColorScheme cs) {
    if (_isLikeLoading) {
      return Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentLikesCount.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'J\'aime',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withOpacity(.7),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Icon(
          _hasLiked ? Icons.favorite : Icons.favorite_border,
          size: 24,
          color: _hasLiked ? Colors.green : cs.primary,
        ),
        const SizedBox(height: 6),
        Text(
          _currentLikesCount.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _hasLiked ? Colors.green : cs.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'J\'aime',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withOpacity(.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label, ColorScheme cs) {
    return Column(
      children: [
        Icon(icon, size: 24, color: cs.primary),
        const SizedBox(height: 6),
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withOpacity(.7),
          ),
        ),
      ],
    );
  }

  String _getVisibilityLabel(PostVisibility visibility) {
    switch (visibility) {
      case PostVisibility.public:
        return 'Public';
      case PostVisibility.friends:
        return 'Amis';
      case PostVisibility.private:
        return 'Privé';
      case PostVisibility.groupe:
        return 'Groupe';
    }
  }
}
