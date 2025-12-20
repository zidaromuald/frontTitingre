import 'package:flutter/material.dart';
import 'package:gestauth_clean/iu/onglets/paramInfo/parametre.dart';
import 'package:gestauth_clean/iu/onglets/postInfo/post.dart';
import 'package:gestauth_clean/iu/onglets/postInfo/post_details_page.dart';
import 'package:gestauth_clean/iu/onglets/postInfo/post_search_page.dart';
import 'package:gestauth_clean/iu/onglets/servicePlan/service.dart';
import 'package:gestauth_clean/services/posts/post_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<PostModel> _posts = [];
  bool _isLoadingPosts = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoadingPosts = true;
      _errorMessage = null;
    });

    try {
      final posts = await PostService.getPublicFeed(limit: 20, offset: 0);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement: $e';
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  Widget buildCerealCard(String imagePath, String title) {
    return Container(
      height: 170,
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  134,
                  128,
                  128,
                ).withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.symmetric(vertical: 5),
              alignment: Alignment.center,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSocieteContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(180, 220, 220, 220),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment
            .start, // Important: permet au container de s'adapter au contenu
        children: [
          const Text(
            "Mes Sociétés",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10), // Espacement contrôlé
          SizedBox(
            height: 150, // Hauteur fixe pour les cartes seulement
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 6),
                  buildCerealCard("images/logo.png", "Tech Corp"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Creative Studio"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Global Inc"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Innovation Lab"),
                  const SizedBox(width: 10),
                  buildCerealCard("images/logo.png", "Digital Agency"),
                  SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGroupeContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(180, 220, 220, 220),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
        children: [
          const Text(
            "Mes Groupes",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildGroupCard("Développeurs", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Designers", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Marketing", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Gaming", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Photo", Icons.person_2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(String groupName, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color.fromARGB(255, 88, 91, 94),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            groupName,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList() {
    if (_isLoadingPosts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.post_add, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Aucun post pour le moment',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Soyez le premier à publier !',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(
        _posts.length,
        (index) => Padding(
          padding: EdgeInsets.only(
            bottom: index < _posts.length - 1 ? 12 : 0,
          ),
          child: _PostCard(post: _posts[index]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    //final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Color(0xFF0B2340), // Vert foncé
        elevation: 4, // ombre du bas
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: Icon(Icons.eco, color: Colors.white, size: 35),
        ),
        title: const Text(
          "Titingre",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PostSearchPage(),
                ),
              );
            },
            tooltip: 'Rechercher des posts',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER FIXE (non scrollable)
            SizedBox(
              height: 170, // Réduit de 230 à 170
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Fond courbe
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _HeaderWaveClipper(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0B2340), Color(0xFF1E4A8C)],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Avatar + nom (CORRIGÉ)
                  Positioned(
                    top: 10,
                    left: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileAvatar(
                          size: 70,
                        ), // Taille fixe au lieu de size.width * 0.18
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ZIDA Jules',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Boutons carrés
                  Positioned(
                    top: 20,
                    right: 16,
                    child: Row(
                      children: [
                        _SquareAction(
                          label: '1',
                          icon: Icons.add_circle_outline,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreerPostPage(),
                              ),
                            );
                            // Si un post a été créé, rafraîchir la liste
                            if (result == true) {
                              _refreshPosts();
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        _SquareAction(
                          label: '2',
                          icon: Icons.group,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ServicePage(), // Enlevé const
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        _SquareAction(
                          label: '3',
                          icon: Icons.settings_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ParametrePage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Divider(
                thickness: 3,
                color: Color(0xFFE0E0E0),
                indent: 8,
                endIndent: 8,
              ),
            ),
            // CONTENU SCROLLABLE SEULEMENT EN DESSOUS
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // SECTION SOCIÉTÉS
                    buildSocieteContainer(),

                    // Ligne de séparation subtile
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(
                        thickness: 2,
                        color: Color(0xFFE0E0E0),
                        indent: 8,
                        endIndent: 8,
                      ),
                    ),

                    // SECTION GROUPES
                    buildGroupeContainer(),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(
                        thickness: 2,
                        color: Color(0xFFE0E0E0),
                        indent: 8,
                        endIndent: 8,
                      ),
                    ),

                    // BARRE D'INFO
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoChip(title: 'Posts', value: '120'),
                          _InfoChip(title: 'Abonnés', value: '2.4k'),
                          _InfoChip(title: 'Suivis', value: '180'),
                          _InfoChip(title: 'Groupes', value: '12'),
                        ],
                      ),
                    ),

                    // LISTE DES POSTS
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: _buildPostsList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ————— Widgets —————
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.onPrimary.withOpacity(.2), Colors.white24],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const CircleAvatar(
        backgroundImage: AssetImage('assets/avatar_placeholder.png'),
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cs.onPrimary.withOpacity(.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              Positioned(
                bottom: 3,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        height: 62,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final PostModel post;

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authorName = post.getAuthorName();
    final authorPhoto = post.getAuthorPhoto();
    final hasMedia = post.hasMedia();

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailsPage(postId: post.id),
          ),
        );
        // Si le post a été supprimé, on pourrait recharger la liste ici
        // Mais comme on est dans un StatelessWidget, on laisse le parent gérer
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
            // En-tête avec avatar et nom
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: authorPhoto != null ? NetworkImage(authorPhoto) : null,
                  child: authorPhoto == null
                      ? Icon(
                          post.authorType == AuthorType.user ? Icons.person : Icons.business,
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
                        authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatTimestamp(post.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, color: cs.onSurface.withOpacity(.7)),
              ],
            ),
            const SizedBox(height: 12),

            // Contenu texte
            if (post.contenu.isNotEmpty) ...[
              Text(
                post.contenu,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: cs.onSurface.withOpacity(.8),
                ),
                maxLines: hasMedia ? 2 : null,
                overflow: hasMedia ? TextOverflow.ellipsis : null,
              ),
              const SizedBox(height: 12),
            ],

            // Média (image ou vidéo)
            if (hasMedia) ...[
              ClipRRec(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.mediaUrls!.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withOpacity(.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant.withOpacity(.3)),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: cs.onSurface.withOpacity(.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Média indisponible',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
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
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Statistiques et actions (cliquer sur la carte pour interagir)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Like
                  Icon(
                    Icons.favorite_border,
                    size: 20,
                    color: cs.primary.withOpacity(.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Commentaires
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 20,
                    color: cs.primary.withOpacity(.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.commentsCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Partages
                  Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: cs.onSurface.withOpacity(.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.sharesCount}',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(.7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Indicateur visuel pour cliquer
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: cs.primary.withOpacity(.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class ClipRRec extends StatelessWidget {
  const ClipRRec({super.key, required this.borderRadius, required this.child});
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: borderRadius, child: child);
  }
}

// ————— Clipper pour la courbe du header —————
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75); // Augmenté de 0.62 à 0.75

    path.quadraticBezierTo(
      size.width * 0.22,
      size.height * 0.65, // Augmenté de 0.52 à 0.65
      size.width * 0.42,
      size.height * 0.75, // Augmenté de 0.62 à 0.75
    );
    path.quadraticBezierTo(
      size.width * 0.70,
      size.height * 0.88, // Augmenté de 0.75 à 0.88
      size.width,
      size.height * 0.73, // Augmenté de 0.6 à 0.73
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
