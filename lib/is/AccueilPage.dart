import 'package:flutter/material.dart';
import '../services/AuthUS/societe_auth_service.dart';
import '../services/posts/post_service.dart';
import '../widgets/editable_societe_avatar.dart';
import '../iu/onglets/postInfo/post.dart';
import '../iu/onglets/postInfo/post_details_page.dart';
import '../iu/onglets/postInfo/post_search_page.dart';
import 'onglets/paramInfo/parametre.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  String? _currentLogoUrl;
  List<PostModel> _posts = [];
  bool _isLoadingPosts = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSocieteLogo();
    _loadPosts();
  }

  Future<void> _loadSocieteLogo() async {
    try {
      final societe = await SocieteAuthService.getMyProfile();
      setState(() {
        _currentLogoUrl = societe.profile?.logo;
      });
    } catch (e) {
      // La société n'est peut-être pas connectée
      print('Erreur de chargement du logo: $e');
    }
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

  Widget buildPersonalGroupsContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 150, 147, 147),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mes Groupes Créés",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildGroupCard("Équipe Vente", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Support Client", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Développement", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Marketing", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("RH", Icons.person_2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildJoinedGroupsContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 150, 147, 147),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Groupes Rejoints",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildGroupCard("Tech Community", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Business Network", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Innovation Hub", Icons.person_2),
                  const SizedBox(width: 15),
                  _buildGroupCard("Startup Groupe", Icons.person_2),
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
          width: 70,
          height: 70,
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
          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            groupName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
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

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A5BA0), // Bleu foncé IS
        elevation: 4,
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER FIXE (non scrollable)
            SizedBox(
              height: 170,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // fond courbe
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _HeaderWaveClipper(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF3A5BA0), // bleu foncé
                              Color(0xFF9DB4D6), // bleu clair
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Avatar + Nom en haut à gauche
                  Positioned(
                    top: 10,
                    left: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EditableSocieteAvatar(
                          size: 70,
                          currentLogoUrl: _currentLogoUrl,
                          onLogoUpdated: (newUrl) {
                            setState(() {
                              _currentLogoUrl = newUrl;
                            });
                          },
                        ),
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
                  // Boutons carrés en haut à droite
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
                            // TODO: Navigate to groups page
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
            // CONTENU SCROLLABLE
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // CONTAINERS GROUPES (Personnel + Rejoints)
                    buildPersonalGroupsContainer(),
                    const SizedBox(height: 8),
                    buildJoinedGroupsContainer(),

                    // Ligne de séparation
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(
                        thickness: 2,
                        color: Color(0xFFE0E0E0),
                        indent: 8,
                        endIndent: 8,
                      ),
                    ),

                    // BARRE d'info (4 cartes arrondies)
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
              )
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
    return InkWell(
      onTap: () async {
        await Navigator.push(
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
            if (post.hasMedia() && post.mediaUrls!.isNotEmpty)
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withOpacity(.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withOpacity(.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'http://127.0.0.1:8000${post.mediaUrls!.first}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: cs.onSurface.withOpacity(.4),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
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
            if (post.hasMedia() && post.mediaUrls!.isNotEmpty)
              const SizedBox(height: 12),
            Text(
              post.contenu,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: cs.onSurface.withOpacity(.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
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
            )
          ],
        ),
      ),
    ),
    );
  }
}

// ————— Clipper pour la courbe du header —————
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);

    path.quadraticBezierTo(
      size.width * 0.22,
      size.height * 0.65,
      size.width * 0.42,
      size.height * 0.75,
    );
    path.quadraticBezierTo(
      size.width * 0.70,
      size.height * 0.88,
      size.width,
      size.height * 0.73,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
