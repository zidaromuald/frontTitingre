import 'package:flutter/material.dart';
import 'package:gestauth_clean/iu/onglets/paramInfo/parametre.dart';
import 'package:gestauth_clean/iu/onglets/paramInfo/profil.dart';
import 'package:gestauth_clean/iu/onglets/postInfo/post.dart';
import 'package:gestauth_clean/iu/onglets/postInfo/post_details_page.dart';
import 'package:gestauth_clean/iu/onglets/postInfo/post_edit_page.dart';
//import 'package:gestauth_clean/iu/onglets/postInfo/post_search_page.dart';
import 'package:gestauth_clean/iu/onglets/servicePlan/service.dart';
import 'package:gestauth_clean/services/posts/post_service.dart';
import 'package:gestauth_clean/services/posts/like_service.dart';
import 'package:gestauth_clean/services/posts/comment_service.dart';
import 'package:gestauth_clean/services/affichage/unread_content_service.dart';
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/services/suivre/abonnement_auth_service.dart';
import 'package:gestauth_clean/widgets/r2_network_image.dart';
import 'package:gestauth_clean/widgets/video_player_widget.dart';
import 'package:gestauth_clean/widgets/voice_recorder_widget.dart';
import 'package:gestauth_clean/groupe/groupe_detail_page.dart';
import 'package:gestauth_clean/iu/onglets/recherche/societe_profile_page.dart';

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
      debugPrint('📤 [HomePage] Chargement des abonnements...');
      final abonnements = await AbonnementAuthService.getMySubscriptions(
        statut: AbonnementStatut.actif,
        includeSociete: true,
      );
      debugPrint('📥 [HomePage] ${abonnements.length} abonnements récupérés');

      // Enrichir les abonnements sans données de société
      List<AbonnementModel> enrichedAbonnements = [];
      for (var abonnement in abonnements) {
        if (abonnement.societe == null) {
          // Charger les données de la société séparément
          debugPrint('🔄 [HomePage] Chargement société #${abonnement.societeId}...');
          try {
            final societe = await SocieteAuthService.getSocieteProfile(abonnement.societeId);
            // Créer un nouvel AbonnementModel avec les données de la société
            enrichedAbonnements.add(AbonnementModel(
              id: abonnement.id,
              userId: abonnement.userId,
              societeId: abonnement.societeId,
              statut: abonnement.statut,
              dateDebut: abonnement.dateDebut,
              dateFin: abonnement.dateFin,
              planCollaboration: abonnement.planCollaboration,
              permissions: abonnement.permissions,
              createdAt: abonnement.createdAt,
              updatedAt: abonnement.updatedAt,
              user: abonnement.user,
              societe: {
                'id': societe.id,
                'nom': societe.nom,
                'profile': societe.profile != null
                    ? {
                        'logo': societe.profile!.logo,
                        'description': societe.profile!.description,
                      }
                    : null,
              },
            ));
            debugPrint('✅ [HomePage] Société #${abonnement.societeId} enrichie');
          } catch (e) {
            debugPrint('⚠️ [HomePage] Erreur enrichissement société #${abonnement.societeId}: $e');
            enrichedAbonnements.add(abonnement); // Garder sans données
          }
        } else {
          enrichedAbonnements.add(abonnement);
        }
      }

      if (mounted) {
        setState(() {
          _mesSocietes = enrichedAbonnements;
          _isLoadingMesSocietes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMesSocietes = false);
      }
      debugPrint('❌ [HomePage] Erreur chargement mes sociétés: $e');
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
            height: 95,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SocieteProfilePage(societeId: societe.id),
          ),
        );
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
        final societeId = societeData['id'] as int?;
        if (societeId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SocieteProfilePage(societeId: societeId),
            ),
          );
        }
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilDetailPage(),
                              ),
                            ).then((_) {
                              // Recharger le profil après retour de la page
                              _loadUserProfile();
                            });
                          },
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
  const _ProfileAvatar({required this.size, this.photoUrl, this.onTap});
  final double size;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      // Revert on error
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
    final parentContext = context;
    final cs = Theme.of(context).colorScheme;

    if (_currentUserId == null || _currentUserType == null) {
      await _loadCurrentUser();
    }

    final isOwner = _currentUserId != null &&
        _currentUserType != null &&
        _currentUserId == widget.post.authorId &&
        _currentUserType == widget.post.authorType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
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
            ListTile(
              leading: Icon(Icons.visibility, color: cs.primary),
              title: const Text('Voir le post'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                    builder: (context) => PostDetailsPage(postId: widget.post.id),
                  ),
                ).then((_) {
                  // Recharger les likes/commentaires apres retour
                  _loadLikeStatus();
                });
              },
            ),
            if (isOwner) ...[
              Divider(height: 1, color: cs.outlineVariant),
              ListTile(
                leading: Icon(Icons.edit, color: cs.primary),
                title: const Text('Modifier'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final result = await Navigator.push(
                    parentContext,
                    MaterialPageRoute(
                      builder: (context) => PostEditPage(post: widget.post),
                    ),
                  );
                  if (result == true && mounted) {
                    widget.onPostDeleted();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _confirmDeletePost(parentContext);
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
            // En-tete avec avatar et nom
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
                // Bouton trois points pour options (voir post, modifier, supprimer)
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
                maxLines: hasMedia ? 3 : null,
                overflow: hasMedia ? TextOverflow.ellipsis : null,
              ),
              const SizedBox(height: 12),
            ],

            // Media (image ou video)
            if (hasMedia) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildMediaWidget(widget.post.mediaUrls!.first, cs),
              ),
              const SizedBox(height: 12),
            ],

            // Ligne de compteurs (style Facebook: "X J'aime   X commentaires")
            if (_likesCount > 0 || _commentsCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (_likesCount > 0) ...[
                      Icon(
                        Icons.thumb_up,
                        size: 14,
                        color: _hasLiked ? const Color(0xFF1877F2) : Colors.grey,
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

            // Boutons d'action style Facebook (J'aime, Commenter, Partager)
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
                            _hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            size: 20,
                            color: _hasLiked ? const Color(0xFF1877F2) : cs.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'J\'aime',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _hasLiked ? FontWeight.w600 : FontWeight.normal,
                              color: _hasLiked ? const Color(0xFF1877F2) : cs.onSurface.withOpacity(0.6),
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
            ),
          ],
        ),
      ),
    );
  }

  String _getMediaUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://api.titingre.com/storage/$url';
  }

  bool _isVideo(String url) {
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.endsWith('.mp4') ||
        lowercaseUrl.endsWith('.mov') ||
        lowercaseUrl.endsWith('.avi') ||
        lowercaseUrl.endsWith('.mkv') ||
        lowercaseUrl.endsWith('.webm');
  }

  bool _isAudio(String url) {
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.endsWith('.mp3') ||
        lowercaseUrl.endsWith('.wav') ||
        lowercaseUrl.endsWith('.aac') ||
        lowercaseUrl.endsWith('.m4a') ||
        lowercaseUrl.endsWith('.ogg');
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
      return R2NetworkImage(
        imageUrl: fullUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }
}

/// Bottom sheet pour afficher et ajouter des commentaires
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
          // Barre
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Titre
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.chat_bubble, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Commentaires (${_comments.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),

          // Liste des commentaires
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun commentaire',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Soyez le premier à commenter !',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
                                  comment.authorType == 'Societe' ? Icons.business : Icons.person,
                                  size: 16,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Bulle de commentaire
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment.getAuthorName(),
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            comment.contenu,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Heure
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12, top: 4),
                                      child: Text(
                                        _formatTime(comment.createdAt),
                                        style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5)),
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

          // Champ de saisie en bas
          Padding(
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 8,
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
                      hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.4)),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        width: 36, height: 36,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _addComment,
                        icon: Icon(Icons.send, color: cs.primary),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
              ],
            ),
          ),
        ],
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
