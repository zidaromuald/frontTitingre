import 'package:flutter/material.dart';
import '../services/AuthUS/auth_base_service.dart';
import '../services/AuthUS/societe_auth_service.dart';
import '../services/AuthUS/user_auth_service.dart';
import '../services/posts/post_service.dart';
import '../services/posts/like_service.dart';
import '../services/posts/comment_service.dart';
import '../services/affichage/unread_content_service.dart';
import '../services/suivre/suivre_auth_service.dart';
import '../services/groupe/groupe_service.dart';
import '../widgets/r2_network_image.dart';
import '../iu/onglets/postInfo/post.dart';
import '../iu/onglets/postInfo/post_details_page.dart';
import '../iu/onglets/postInfo/post_edit_page.dart';
//import '../iu/onglets/postInfo/post_search_page.dart';
import 'onglets/paramInfo/parametre.dart';
import 'onglets/paramInfo/profil.dart';
import 'onglets/servicePlan/service.dart' as service_societe;
import '../groupe/groupe_detail_page.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/voice_recorder_widget.dart';

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

  // Données dynamiques pour les groupes avec contenus non lus
  List<GroupeWithUnreadContent> _groupesWithUnread = [];
  bool _isLoadingGroupes = false;

  // Statistiques dynamiques
  int _abonnesCount = 0;
  int _suivisCount = 0;
  int _groupesCount = 0;
  bool _isLoadingStats = false;

  // Profil société
  SocieteModel? _currentSociete;
  bool _isLoadingSociete = false;

  @override
  void initState() {
    super.initState();
    _loadSocieteProfile();
    _loadPosts();
    _loadGroupesWithUnread();
    _loadStatistics();
  }

  /// Charger les statistiques de la société (abonnés, suivis, groupes)
  Future<void> _loadStatistics() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);

    try {
      // Récupérer le profil de la société pour avoir son ID
      final societe = await SocieteAuthService.getMyProfile();
      print('📊 [Stats] Societe chargée: id=${societe.id}');

      // Charger tout en parallèle : groupes, followers, following
      int abonnes = 0;
      int suivis = 0;
      List<GroupeModel> groupes = [];

      final results = await Future.wait([
        // 1. Groupes
        GroupeAuthService.getMyGroupes().then<Object>((g) => g).catchError((e) {
          print('⚠️ [Stats] Erreur chargement groupes: $e');
          return <GroupeModel>[];
        }),
        // 2. Followers (abonnés) - comptage direct via la liste
        SuivreAuthService.getFollowers(
          entityId: societe.id,
          entityType: EntityType.societe,
        ).then<Object>((f) => f).catchError((e) {
          print('⚠️ [Stats] Erreur chargement followers: $e');
          return <Map<String, dynamic>>[];
        }),
        // 3. Following (suivis) - comptage direct via la liste
        SuivreAuthService.getMyFollowing().then<Object>((f) => f).catchError((
          e,
        ) {
          print('⚠️ [Stats] Erreur chargement following: $e');
          return <SuivreModel>[];
        }),
      ]);

      groupes = results[0] as List<GroupeModel>;
      final followers = results[1] as List<Map<String, dynamic>>;
      final following = results[2] as List<SuivreModel>;
      abonnes = followers.length;
      suivis = following.length;

      print(
        '📊 [Stats] Followers: $abonnes, Following: $suivis, Groupes: ${groupes.length}',
      );

      // Si les comptages directs sont à 0, essayer l'endpoint stats en dernier recours
      if (abonnes == 0 && suivis == 0) {
        try {
          final statsResult = await SuivreAuthService.getSocieteStats(
            societe.id,
          );
          print('📊 [Stats] Stats endpoint result: $statsResult');

          // Essayer toutes les clés possibles pour les abonnés
          for (final key in [
            'abonnes_count',
            'followers_count',
            'abonnes',
            'followers',
            'subscribersCount',
          ]) {
            final val = statsResult[key];
            if (val != null && val is int && val > 0) {
              abonnes = val;
              break;
            }
          }
          // Essayer toutes les clés possibles pour les suivis
          for (final key in [
            'suivis_count',
            'following_count',
            'suivis',
            'following',
            'followingCount',
          ]) {
            final val = statsResult[key];
            if (val != null && val is int && val > 0) {
              suivis = val;
              break;
            }
          }
        } catch (e) {
          print('⚠️ [Stats] Endpoint stats aussi en erreur: $e');
        }
      }

      print(
        '📊 [Stats] Final: abonnes=$abonnes, suivis=$suivis, groupes=${groupes.length}',
      );

      if (mounted) {
        setState(() {
          _abonnesCount = abonnes;
          _suivisCount = suivis;
          _groupesCount = groupes.length;
          _isLoadingStats = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ [Stats] Erreur chargement statistiques: $e');
      print('❌ [Stats] StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _abonnesCount = 0;
          _suivisCount = 0;
          _groupesCount = 0;
          _isLoadingStats = false;
        });
      }
    }
  }

  /// Formater un nombre pour l'affichage (ex: 1000 → 1k, 1500000 → 1.5M)
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      final k = number / 1000;
      // Si c'est un nombre entier de k, ne pas afficher de décimale
      if (k == k.toInt()) {
        return '${k.toInt()}k';
      }
      return '${k.toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  /// Charger le profil complet de la société (nom, logo, etc.)
  Future<void> _loadSocieteProfile() async {
    if (!mounted) return;
    setState(() => _isLoadingSociete = true);

    try {
      print('👤 [Profile] Chargement du profil société...');
      final societe = await SocieteAuthService.getMyProfile();
      print('👤 [Profile] Profil chargé: ${societe.nom}, id=${societe.id}');

      if (mounted) {
        setState(() {
          _currentSociete = societe;
          _currentLogoUrl = societe.profile?.getLogoUrl();
          _isLoadingSociete = false;
        });
        print('👤 [Profile] État mis à jour');
      }
    } catch (e, stackTrace) {
      print('❌ [Profile] Erreur chargement profil société: $e');
      print('❌ [Profile] StackTrace: $stackTrace');
      if (mounted) {
        setState(() => _isLoadingSociete = false);
      }
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPosts = true;
      _errorMessage = null;
    });

    try {
      print(
        '📝 [Posts] Chargement du feed personnalisé (mes posts + suivis)...',
      );
      // Utiliser getPersonalizedFeed pour voir uniquement ses posts + ceux des personnes suivies
      final posts = await PostService.getPersonalizedFeed(
        limit: 100,
        offset: 0,
      );
      print('📝 [Posts] ${posts.length} posts chargés');

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoadingPosts = false;
        });
        print('📝 [Posts] État mis à jour');
      }
    } catch (e, stackTrace) {
      print('❌ [Posts] Erreur de chargement: $e');
      print('❌ [Posts] StackTrace: $stackTrace');
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

  /// Charger les groupes avec du contenu non lu
  Future<void> _loadGroupesWithUnread() async {
    setState(() => _isLoadingGroupes = true);

    try {
      final groupes =
          await UnreadContentService.getMyGroupesWithUnreadContent();

      if (mounted) {
        setState(() {
          _groupesWithUnread = groupes;
          _isLoadingGroupes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGroupes = false);
      }
    }
  }

  /// Container dynamique pour les groupes avec contenus non lus
  Widget buildGroupesWithUnreadContainer() {
    // Si chargement en cours
    if (_isLoadingGroupes) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 150, 147, 147),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Si aucun groupe avec contenu non lu
    if (_groupesWithUnread.isEmpty) {
      return const SizedBox.shrink(); // Ne rien afficher
    }

    // Afficher les groupes avec contenus non lus
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Nouveaux Messages & Posts",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_groupesWithUnread.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _groupesWithUnread.map((groupe) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _buildDynamicGroupCard(groupe),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour afficher une card de groupe dynamique avec badge de non-lus
  Widget _buildDynamicGroupCard(GroupeWithUnreadContent groupe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupeDetailPage(groupeId: groupe.id),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3A5BA0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: groupe.logo != null
                      ? DecorationImage(
                          image: NetworkImage(groupe.logo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: groupe.logo == null
                    ? const Icon(Icons.group, color: Colors.white, size: 30)
                    : null,
              ),
              // Badge de compteur de non-lus
              if (groupe.totalUnread > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      groupe.totalUnread > 99 ? '99+' : '${groupe.totalUnread}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              groupe.nom,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
          padding: EdgeInsets.only(bottom: index < _posts.length - 1 ? 12 : 0),
          child: _PostCard(post: _posts[index], onPostDeleted: _refreshPosts),
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
                        // Avatar cliquable pour voir le profil (tap simple) ou éditer logo (tap long)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilDetailPage(),
                              ),
                            ).then((_) {
                              // Recharger le profil après retour de la page
                              _loadSocieteProfile();
                            });
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3A5BA0),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: _currentLogoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_currentLogoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _currentLogoUrl == null
                                ? const Icon(
                                    Icons.business,
                                    color: Colors.white,
                                    size: 35,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Nom cliquable pour voir le profil
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilDetailPage(),
                              ),
                            ).then((_) {
                              _loadSocieteProfile();
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isLoadingSociete
                                  ? const SizedBox(
                                      width: 100,
                                      child: LinearProgressIndicator(
                                        color: Colors.white,
                                        backgroundColor: Colors.white24,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _currentSociete != null
                                              ? _currentSociete!.nom
                                                    .toUpperCase()
                                              : 'Société',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white70,
                                          size: 12,
                                        ),
                                      ],
                                    ),
                            ],
                          ),
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
                          icon: Icons.person_2_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const service_societe.ServicePage(),
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
            // CONTENU SCROLLABLE
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // CONTAINER DYNAMIQUE: Groupes avec contenus non lus
                    buildGroupesWithUnreadContainer(),

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

                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                      child: _isLoadingStats
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _InfoChip(
                                  title: 'Abonnés',
                                  value: _formatNumber(_abonnesCount),
                                ),
                                _InfoChip(
                                  title: 'Suivis',
                                  value: _formatNumber(_suivisCount),
                                ),
                                _InfoChip(
                                  title: 'Groupes',
                                  value: _formatNumber(_groupesCount),
                                ),
                              ],
                            ),
                    ),

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

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post, required this.onPostDeleted});
  final PostModel post;
  final VoidCallback onPostDeleted;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  int? _currentUserId;
  AuthorType? _currentUserType;

  // Etat Like
  bool _hasLiked = false;
  int _likesCount = 0;
  bool _isLikeLoading = false;

  // Etat Commentaires
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
    _loadCurrentUser();
    _loadLikeStatus();
  }

  Future<void> _loadCurrentUser() async {
    if (!mounted) return;

    final storedType = await AuthBaseService.getUserType();

    if (storedType == 'societe') {
      try {
        final societe = await SocieteAuthService.getMyProfile();
        if (mounted) {
          setState(() {
            _currentUserId = societe.id;
            _currentUserType = AuthorType.societe;
          });
          return;
        }
      } catch (_) {}
    } else if (storedType == 'user') {
      try {
        final user = await UserAuthService.getMyProfile();
        if (mounted) {
          setState(() {
            _currentUserId = user.id;
            _currentUserType = AuthorType.user;
          });
          return;
        }
      } catch (_) {}
    }
  }

  /// Charger l'etat du like pour ce post
  Future<void> _loadLikeStatus() async {
    try {
      final results = await Future.wait([
        LikeService.checkLike(widget.post.id),
        LikeService.countPostLikes(widget.post.id),
      ]);
      if (mounted) {
        setState(() {
          _hasLiked = results[0] as bool;
          _likesCount = results[1] as int;
        });
      }
    } catch (_) {}
  }

  /// Toggle like directement depuis la carte
  Future<void> _toggleLike() async {
    if (_isLikeLoading) return;
    setState(() => _isLikeLoading = true);

    // Optimistic update
    final previousLiked = _hasLiked;
    final previousCount = _likesCount;
    setState(() {
      _hasLiked = !_hasLiked;
      _likesCount += _hasLiked ? 1 : -1;
    });

    try {
      await LikeService.toggleLike(widget.post.id);
      final exactCount = await LikeService.countPostLikes(widget.post.id);
      if (mounted) {
        setState(() {
          _likesCount = exactCount;
          _isLikeLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasLiked = previousLiked;
          _likesCount = previousCount;
          _isLikeLoading = false;
        });
      }
    }
  }

  /// Ouvrir le bottom sheet des commentaires
  void _showCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsBottomSheet(
        postId: widget.post.id,
        onCommentAdded: () {
          setState(() => _commentsCount++);
        },
      ),
    );
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

  String _getMediaUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://api.titingre.com/storage/$url';
  }

  bool _isVideo(String url) {
    final l = url.toLowerCase();
    return l.endsWith('.mp4') ||
        l.endsWith('.mov') ||
        l.endsWith('.avi') ||
        l.endsWith('.mkv') ||
        l.endsWith('.webm');
  }

  bool _isAudio(String url) {
    final l = url.toLowerCase();
    return l.endsWith('.mp3') ||
        l.endsWith('.wav') ||
        l.endsWith('.aac') ||
        l.endsWith('.m4a') ||
        l.endsWith('.ogg');
  }

  Widget _buildMediaWidget(String url, ColorScheme cs) {
    final fullUrl = _getMediaUrl(url);

    if (_isVideo(url)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: VideoPlayerWidget(
            videoUrl: fullUrl,
            autoPlay: false,
            looping: false,
          ),
        ),
      );
    } else if (_isAudio(url)) {
      return VoiceMessagePlayer(audioUrl: fullUrl);
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: R2NetworkImage(
          imageUrl: fullUrl,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  Future<void> _showPostOptions(BuildContext context) async {
    final parentContext = context;
    final cs = Theme.of(context).colorScheme;

    if (_currentUserId == null || _currentUserType == null) {
      await _loadCurrentUser();
    }

    final isOwner =
        _currentUserId != null &&
        _currentUserType != null &&
        _currentUserId == widget.post.authorId &&
        _currentUserType == widget.post.authorType;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.visibility, color: cs.primary, size: 22),
                  title: const Text(
                    'Voir le post',
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (context) =>
                            PostDetailsPage(postId: widget.post.id),
                      ),
                    ).then((_) => _loadLikeStatus());
                  },
                ),
                if (isOwner) ...[
                  Divider(height: 1, color: cs.outlineVariant),
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(Icons.edit, color: cs.primary, size: 22),
                    title: const Text(
                      'Modifier',
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      final result = await Navigator.push(
                        parentContext,
                        MaterialPageRoute(
                          builder: (context) => PostEditPage(post: widget.post),
                        ),
                      );
                      if (result == true && mounted) widget.onPostDeleted();
                    },
                  ),
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 22,
                    ),
                    title: const Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _confirmDeletePost(parentContext);
                    },
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le post'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce post ? Cette action est irréversible.',
        ),
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

    if (confirmed == true && mounted) {
      try {
        await PostService.deletePost(widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onPostDeleted();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authorPhoto = widget.post.getAuthorPhoto();
    final hasMedia =
        widget.post.hasMedia() && widget.post.mediaUrls!.isNotEmpty;

    return Container(
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
            // En-tete
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: authorPhoto != null
                      ? NetworkImage(authorPhoto)
                      : null,
                  child: authorPhoto == null
                      ? Icon(
                          widget.post.authorType == AuthorType.societe
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
                        widget.post.getAuthorName(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatTimestamp(widget.post.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: cs.onSurface.withOpacity(.7),
                  ),
                  onPressed: () => _showPostOptions(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Media
            if (hasMedia) ...[
              _buildMediaWidget(widget.post.mediaUrls!.first, cs),
              const SizedBox(height: 12),
            ],

            // Contenu texte
            Text(
              widget.post.contenu,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: cs.onSurface.withOpacity(.8),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Ligne de compteurs (style Facebook)
            if (_likesCount > 0 || _commentsCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (_likesCount > 0) ...[
                      Icon(
                        Icons.thumb_up,
                        size: 14,
                        color: _hasLiked
                            ? const Color(0xFF1877F2)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_likesCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (_commentsCount > 0)
                      Text(
                        '$_commentsCount commentaire${_commentsCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),

            // Separateur
            Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
            const SizedBox(height: 4),

            // Boutons d'action style Facebook
            Row(
              children: [
                // Bouton J'aime
                Expanded(
                  child: InkWell(
                    onTap: _toggleLike,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            size: 20,
                            color: _hasLiked
                                ? const Color(0xFF1877F2)
                                : cs.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'J\'aime',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _hasLiked
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _hasLiked
                                  ? const Color(0xFF1877F2)
                                  : cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bouton Commenter
                Expanded(
                  child: InkWell(
                    onTap: () => _showCommentsSheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Commenter',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet pour afficher et ajouter des commentaires (IS)
class _CommentsBottomSheet extends StatefulWidget {
  final int postId;
  final VoidCallback onCommentAdded;

  const _CommentsBottomSheet({
    required this.postId,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isAdding = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await CommentService.getPostComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isAdding) return;

    setState(() => _isAdding = true);

    try {
      await CommentService.createComment(
        CreateCommentDto(postId: widget.postId, contenu: text),
      );
      _controller.clear();
      widget.onCommentAdded();
      await _loadComments();
      if (mounted) setState(() => _isAdding = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.chat_bubble, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Commentaires (${_comments.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun commentaire',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Soyez le premier à commenter !',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: cs.primaryContainer,
                            child: Icon(
                              comment.authorType == 'Societe'
                                  ? Icons.business
                                  : Icons.person,
                              size: 16,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.getAuthorName(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        comment.contenu,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    top: 4,
                                  ),
                                  child: Text(
                                    _formatTime(comment.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: bottomInset > 0 ? bottomInset : 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                    decoration: InputDecoration(
                      hintText: 'Écrire un commentaire...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isAdding
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _addComment,
                        icon: Icon(Icons.send, color: cs.primary),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
              ],
            ),
          ),
        ],
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
