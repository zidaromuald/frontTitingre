import 'package:flutter/material.dart';
import 'package:gestauth_clean/iu/onglets/paramInfo/parametre.dart';
import 'package:gestauth_clean/iu/onglets/postInfo/post.dart';
import 'package:gestauth_clean/iu/onglets/postInfo/post_details_page.dart';
import 'package:gestauth_clean/iu/onglets/postInfo/post_edit_page.dart';
//import 'package:gestauth_clean/iu/onglets/postInfo/post_search_page.dart';
import 'package:gestauth_clean/iu/onglets/servicePlan/service.dart';
import 'package:gestauth_clean/services/posts/post_service.dart';
import 'package:gestauth_clean/services/affichage/unread_content_service.dart';
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/services/suivre/abonnement_auth_service.dart';
import 'package:gestauth_clean/widgets/r2_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<PostModel> _posts = [];
  bool _isLoadingPosts = false;
  String? _errorMessage;

  // Données dynamiques pour les groupes et sociétés avec contenus non lus
  List<GroupeWithUnreadContent> _groupesWithUnread = [];
  List<SocieteWithUnreadContent> _societesWithUnread = [];
  bool _isLoadingGroupes = false;
  bool _isLoadingSocietes = false;

  // Sociétés dont l'utilisateur est membre (abonné)
  List<AbonnementModel> _mesSocietes = [];
  bool _isLoadingMesSocietes = false;

  // Profil utilisateur
  UserModel? _currentUser;
  bool _isLoadingUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadPosts();
    _loadGroupesWithUnread();
    _loadSocietesWithUnread();
    _loadMesSocietes();
  }

  /// Charger le profil de l'utilisateur connecté
  Future<void> _loadUserProfile() async {
    setState(() => _isLoadingUser = true);

    try {
      final user = await UserAuthService.getMyProfile();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
      debugPrint('Erreur chargement profil utilisateur: $e');
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoadingPosts = true;
      _errorMessage = null;
    });

    try {
      final posts = await PostService.getPersonalizedFeed(limit: 20, offset: 0);
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

  /// Charger les sociétés avec du contenu non lu
  Future<void> _loadSocietesWithUnread() async {
    setState(() => _isLoadingSocietes = true);

    try {
      final societes =
          await UnreadContentService.getMySocietesWithUnreadContent();

      if (mounted) {
        setState(() {
          _societesWithUnread = societes;
          _isLoadingSocietes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSocietes = false);
      }
    }
  }

  /// Charger les sociétés dont l'utilisateur est membre (abonnements actifs)
  Future<void> _loadMesSocietes() async {
    setState(() => _isLoadingMesSocietes = true);

    try {
      final abonnements = await AbonnementAuthService.getMySubscriptions(
        statut: AbonnementStatut.actif,
      );

      if (mounted) {
        setState(() {
          _mesSocietes = abonnements;
          _isLoadingMesSocietes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMesSocietes = false);
      }
      debugPrint('Erreur chargement mes sociétés: $e');
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
          color: const Color.fromARGB(180, 220, 220, 220),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF5ac18e)),
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
        color: const Color.fromARGB(180, 220, 220, 220),
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
                "Nouveaux Messages (Groupes)",
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
            height: 85,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _groupesWithUnread.map((groupe) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
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

  /// Container dynamique pour les sociétés avec contenus non lus
  Widget buildSocietesWithUnreadContainer() {
    // Si chargement en cours
    if (_isLoadingSocietes) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(180, 220, 220, 220),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF5ac18e)),
        ),
      );
    }

    // Si aucune société avec contenu non lu
    if (_societesWithUnread.isEmpty) {
      return const SizedBox.shrink(); // Ne rien afficher
    }

    // Afficher les sociétés avec contenus non lus
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(180, 220, 220, 220),
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
                "Nouveaux Messages (Sociétés)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_societesWithUnread.length}',
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
            height: 110,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _societesWithUnread.map((societe) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: _buildDynamicSocieteCard(societe),
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
        // TODO: Naviguer vers la page du groupe
        print('Navigation vers groupe: ${groupe.nom}');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5ac18e),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
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
                    ? const Icon(Icons.group, color: Colors.white, size: 20)
                    : null,
              ),
              // Badge de compteur de non-lus
              if (groupe.totalUnread > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      groupe.totalUnread > 99 ? '99+' : '${groupe.totalUnread}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
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

  /// Widget pour afficher une card de société dynamique avec badge de non-lus
  Widget _buildDynamicSocieteCard(SocieteWithUnreadContent societe) {
    return GestureDetector(
      onTap: () {
        // TODO: Naviguer vers la conversation avec la société
        print('Navigation vers société: ${societe.nom}');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3A5BA0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: societe.logo != null
                      ? DecorationImage(
                          image: NetworkImage(societe.logo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: societe.logo == null
                    ? const Icon(Icons.business, color: Colors.white, size: 25)
                    : null,
              ),
              // Badge de compteur de non-lus
              if (societe.unreadMessagesCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      societe.unreadMessagesCount > 99
                          ? '99+'
                          : '${societe.unreadMessagesCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
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
              societe.nom,
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

  /// Container dynamique pour les sociétés dont l'utilisateur est membre
  Widget buildSocieteContainer() {
    // Si chargement en cours
    if (_isLoadingMesSocietes) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color.fromARGB(180, 220, 220, 220),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF5ac18e)),
        ),
      );
    }

    // Si aucune société
    if (_mesSocietes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color.fromARGB(180, 220, 220, 220),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(Icons.business, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "Aucune société suivie",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Découvrez et abonnez-vous à des sociétés",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Afficher les sociétés
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mes Sociétés",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5ac18e),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_mesSocietes.length}',
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
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _mesSocietes.map((abonnement) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildSocieteCard(abonnement),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour afficher une card de société membre
  Widget _buildSocieteCard(AbonnementModel abonnement) {
    final societeData = abonnement.societe;

    // Si la société est nulle, ne rien afficher
    if (societeData == null) return const SizedBox.shrink();

    // Extraire les données de la société
    final nom = societeData['nom'] as String? ?? 'Société';
    final profile = societeData['profile'] as Map<String, dynamic>?;
    final logo = profile?['logo'] as String?;

    return GestureDetector(
      onTap: () {
        // TODO: Naviguer vers la page de la société
        final societeId = societeData['id'] as int?;
        print('Navigation vers société: $nom (ID: $societeId)');
      },
      child: Container(
        height: 100,
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey[300],
          image: logo != null
              ? DecorationImage(image: NetworkImage(logo), fit: BoxFit.cover)
              : null,
        ),
        child: Stack(
          children: [
            // Si pas de logo, afficher une icône par défaut
            if (logo == null)
              Center(
                child: Icon(Icons.business, size: 32, color: Colors.grey[500]),
              ),
            // Overlay avec le nom de la société
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
                  ).withAlpha((255 * 0.7).toInt()),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                alignment: Alignment.center,
                child: Text(
                  nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
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
                          photoUrl: _currentUser?.photoUrl,
                        ), // Taille fixe au lieu de size.width * 0.18
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isLoadingUser
                                ? const SizedBox(
                                    width: 100,
                                    child: LinearProgressIndicator(
                                      color: Colors.white,
                                      backgroundColor: Colors.white24,
                                    ),
                                  )
                                : Text(
                                    _currentUser != null
                                        ? '${_currentUser!.nom.toUpperCase()} ${_currentUser!.prenom}'
                                        : 'Utilisateur',
                                    style: const TextStyle(
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
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ParametrePage(),
                              ),
                            );
                            // Recharger le profil pour synchroniser l'image mise à jour
                            _loadUserProfile();
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

                    // SECTION GROUPES DYNAMIQUES (avec contenus non lus)
                    buildGroupesWithUnreadContainer(),

                    // SECTION SOCIÉTÉS DYNAMIQUES (avec contenus non lus)
                    buildSocietesWithUnreadContainer(),

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
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size, this.photoUrl});
  final double size;
  final String? photoUrl;

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
      child: CircleAvatar(
        backgroundColor: cs.surfaceContainerHighest,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
        child: photoUrl == null
            ? Icon(Icons.person, size: size * 0.5, color: cs.onSurfaceVariant)
            : null,
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    if (!mounted) return;

    print('🔄 [PostCard-Home] _loadCurrentUser() démarré...');

    // Vérifier le type stocké dans SharedPreferences
    final storedType = await AuthBaseService.getUserType();
    print('🔍 [PostCard-Home] Type stocké: $storedType');

    if (storedType == 'societe') {
      try {
        final societe = await SocieteAuthService.getMyProfile();
        if (mounted) {
          setState(() {
            _currentUserId = societe.id;
            _currentUserType = AuthorType.societe;
          });
          print('✅ [PostCard-Home] SOCIETE id=${societe.id}');
          return;
        }
      } catch (e) {
        print('⚠️ [PostCard-Home] Erreur Societe: $e');
      }
    } else if (storedType == 'user') {
      try {
        final user = await UserAuthService.getMyProfile();
        if (mounted) {
          setState(() {
            _currentUserId = user.id;
            _currentUserType = AuthorType.user;
          });
          print('✅ [PostCard-Home] USER id=${user.id}');
          return;
        }
      } catch (e) {
        print('⚠️ [PostCard-Home] Erreur User: $e');
      }
    }

    print('❌ [PostCard-Home] Impossible de charger l\'utilisateur');
  }

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

  /// Afficher les options du post (voir détails, modifier, supprimer)
  Future<void> _showPostOptions(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    // S'assurer que l'utilisateur est chargé
    if (_currentUserId == null || _currentUserType == null) {
      await _loadCurrentUser();
    }

    // Vérifier si l'utilisateur est l'auteur
    final isOwner = _currentUserId != null &&
        _currentUserType != null &&
        _currentUserId == widget.post.authorId &&
        _currentUserType == widget.post.authorType;

    print('🔍 [PostCard-Home] isOwner=$isOwner (userId=$_currentUserId, postAuthorId=${widget.post.authorId})');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            // Option: Voir le post
            ListTile(
              leading: Icon(Icons.visibility, color: cs.primary),
              title: const Text('Voir le post'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailsPage(postId: widget.post.id),
                  ),
                );
              },
            ),
            // Options pour l'auteur uniquement
            if (isOwner) ...[
              Divider(height: 1, color: cs.outlineVariant),
              // Option: Modifier
              ListTile(
                leading: Icon(Icons.edit, color: cs.primary),
                title: const Text('Modifier'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostEditPage(post: widget.post),
                    ),
                  );
                  if (result == true && mounted) {
                    widget.onPostDeleted();
                  }
                },
              ),
              // Option: Supprimer
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePost(context);
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le post'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce post ? Cette action est irréversible.'),
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
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authorName = widget.post.getAuthorName();
    final authorPhoto = widget.post.getAuthorPhoto();
    final hasMedia = widget.post.hasMedia();

    // Card sans InkWell - seul le bouton trois points est cliquable
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
            // En-tête avec avatar et nom
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
                          widget.post.authorType == AuthorType.user
                              ? Icons.person
                              : Icons.business,
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
                        _formatTimestamp(widget.post.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton trois points - SEUL élément cliquable
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

            // Contenu texte
            if (widget.post.contenu.isNotEmpty) ...[
              Text(
                widget.post.contenu,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildMediaWidget(widget.post.mediaUrls!.first, cs),
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
                  // Commentaires (à gauche)
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 20,
                    color: cs.primary.withOpacity(.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.post.commentsCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Like (à droite avec pouce)
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 20,
                    color: cs.primary.withOpacity(.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.post.likesCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Transformer l'URL du média en URL complète si nécessaire
  String _getMediaUrl(String url) {
    // Si l'URL est déjà complète (commence par http), la retourner telle quelle
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Sinon, c'est un chemin relatif - utiliser l'URL de l'API
    return 'https://api.titingre.com/storage/$url';
  }

  /// Détecter si c'est une vidéo basé sur l'extension
  bool _isVideo(String url) {
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.endsWith('.mp4') ||
        lowercaseUrl.endsWith('.mov') ||
        lowercaseUrl.endsWith('.avi') ||
        lowercaseUrl.endsWith('.mkv') ||
        lowercaseUrl.endsWith('.webm');
  }

  /// Détecter si c'est un audio basé sur l'extension
  bool _isAudio(String url) {
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.endsWith('.mp3') ||
        lowercaseUrl.endsWith('.wav') ||
        lowercaseUrl.endsWith('.aac') ||
        lowercaseUrl.endsWith('.m4a') ||
        lowercaseUrl.endsWith('.ogg');
  }

  /// Construire le widget média approprié (image, vidéo ou audio)
  Widget _buildMediaWidget(String url, ColorScheme cs) {
    final fullUrl = _getMediaUrl(url);

    if (_isVideo(url)) {
      // Afficher un placeholder pour les vidéos avec bouton play
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icône de vidéo en arrière-plan
            Icon(Icons.movie, size: 60, color: Colors.white.withOpacity(0.3)),
            // Bouton play au centre
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
            // Badge "Vidéo" en haut à gauche
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Vidéo',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_isAudio(url)) {
      // Afficher un placeholder pour les audios
      return Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audio_file, size: 32, color: cs.primary),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fichier audio',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Appuyez pour écouter',
                  style: TextStyle(
                    color: cs.onPrimaryContainer.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Image normale
      return R2NetworkImage(
        imageUrl: fullUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
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
