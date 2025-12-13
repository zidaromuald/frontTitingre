import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/posts/post_service.dart';
import 'post_details_page.dart';

/// Page de recherche de posts avec filtres avancés
class PostSearchPage extends StatefulWidget {
  const PostSearchPage({super.key});

  @override
  State<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends State<PostSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PostModel> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  // Filtres
  PostVisibility? _selectedVisibility;
  bool? _hasMedia;
  AuthorType? _selectedAuthorType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty && _selectedVisibility == null && _hasMedia == null && _selectedAuthorType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un terme de recherche ou sélectionner un filtre'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final searchDto = SearchPostDto(
        query: query.isNotEmpty ? query : null,
        visibility: _selectedVisibility,
        hasMedia: _hasMedia,
        authorType: _selectedAuthorType,
      );

      final results = await PostService.searchPosts(searchDto);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedVisibility = null;
      _hasMedia = null;
      _selectedAuthorType = null;
      _searchResults = [];
      _errorMessage = null;
    });
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
        title: const Text('Rechercher des posts'),
        actions: [
          if (_searchController.text.isNotEmpty ||
              _selectedVisibility != null ||
              _hasMedia != null ||
              _selectedAuthorType != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Effacer les filtres',
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant),
              ),
            ),
            child: Column(
              children: [
                // Champ de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans les posts...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: cs.surface,
                  ),
                  onSubmitted: (_) => _performSearch(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Filtres
                ExpansionTile(
                  title: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Filtres',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      if (_selectedVisibility != null || _hasMedia != null || _selectedAuthorType != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            [
                              if (_selectedVisibility != null) '1',
                              if (_hasMedia != null) '1',
                              if (_selectedAuthorType != null) '1',
                            ].length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filtre visibilité
                          const Text(
                            'Visibilité',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('Tous'),
                                selected: _selectedVisibility == null,
                                onSelected: (selected) {
                                  setState(() => _selectedVisibility = null);
                                },
                              ),
                              FilterChip(
                                label: const Text('Public'),
                                selected: _selectedVisibility == PostVisibility.public,
                                onSelected: (selected) {
                                  setState(() => _selectedVisibility =
                                      selected ? PostVisibility.public : null);
                                },
                              ),
                              FilterChip(
                                label: const Text('Amis'),
                                selected: _selectedVisibility == PostVisibility.friends,
                                onSelected: (selected) {
                                  setState(() => _selectedVisibility =
                                      selected ? PostVisibility.friends : null);
                                },
                              ),
                              FilterChip(
                                label: const Text('Groupe'),
                                selected: _selectedVisibility == PostVisibility.groupe,
                                onSelected: (selected) {
                                  setState(() => _selectedVisibility =
                                      selected ? PostVisibility.groupe : null);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Filtre média
                          const Text(
                            'Contenu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('Tous'),
                                selected: _hasMedia == null,
                                onSelected: (selected) {
                                  setState(() => _hasMedia = null);
                                },
                              ),
                              FilterChip(
                                label: const Text('Avec média'),
                                selected: _hasMedia == true,
                                onSelected: (selected) {
                                  setState(() => _hasMedia = selected ? true : null);
                                },
                              ),
                              FilterChip(
                                label: const Text('Texte seul'),
                                selected: _hasMedia == false,
                                onSelected: (selected) {
                                  setState(() => _hasMedia = selected ? false : null);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Filtre type d'auteur
                          const Text(
                            'Type d\'auteur',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('Tous'),
                                selected: _selectedAuthorType == null,
                                onSelected: (selected) {
                                  setState(() => _selectedAuthorType = null);
                                },
                              ),
                              FilterChip(
                                label: const Text('Utilisateurs'),
                                selected: _selectedAuthorType == AuthorType.user,
                                onSelected: (selected) {
                                  setState(() => _selectedAuthorType =
                                      selected ? AuthorType.user : null);
                                },
                              ),
                              FilterChip(
                                label: const Text('Sociétés'),
                                selected: _selectedAuthorType == AuthorType.societe,
                                onSelected: (selected) {
                                  setState(() => _selectedAuthorType =
                                      selected ? AuthorType.societe : null);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bouton de recherche
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _performSearch,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isSearching ? 'Recherche...' : 'Rechercher'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Résultats
          Expanded(
            child: _buildResults(cs),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ColorScheme cs) {
    if (_isSearching) {
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
                onPressed: _performSearch,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Aucun résultat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez de modifier vos critères de recherche',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < _searchResults.length - 1 ? 12 : 0),
          child: _SearchResultCard(post: post, formatTimestamp: _formatTimestamp),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final PostModel post;
  final String Function(DateTime) formatTimestamp;

  const _SearchResultCard({
    required this.post,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailsPage(postId: post.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec auteur
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: post.getAuthorPhoto() != null
                        ? NetworkImage('http://127.0.0.1:8000${post.getAuthorPhoto()}')
                        : null,
                    child: post.getAuthorPhoto() == null
                        ? Icon(
                            post.authorType == AuthorType.societe
                                ? Icons.business
                                : Icons.person,
                            size: 18,
                            color: cs.onPrimaryContainer,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.getAuthorName(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          formatTimestamp(post.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de visibilité
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getVisibilityLabel(post.visibility),
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Contenu
              Text(
                post.contenu,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: cs.onSurface.withOpacity(.8),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Badge média si présent
              if (post.hasMedia()) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.image, size: 16, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${post.mediaUrls!.length} média(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Statistiques
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 16, color: cs.onSurface.withOpacity(.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.6)),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline, size: 16, color: cs.onSurface.withOpacity(.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.6)),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.share_outlined, size: 16, color: cs.onSurface.withOpacity(.6)),
                  const SizedBox(width: 4),
                  Text(
                    '${post.sharesCount}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
