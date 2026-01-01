import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/suivre/suivre_auth_service.dart';
import 'package:gestauth_clean/services/suivre/abonnement_auth_service.dart' as abonnement_service;
import 'package:gestauth_clean/services/groupe/groupe_service.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/services/messagerie/conversation_service.dart';
import 'package:gestauth_clean/iu/onglets/recherche/user_profile_page.dart';
import 'package:gestauth_clean/iu/onglets/recherche/global_search_page.dart';
import 'package:gestauth_clean/iu/onglets/servicePlan/transaction.dart';
import 'package:gestauth_clean/messagerie/conversation_detail_page.dart';
import 'user_transaction_page.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  String selectedTab = "suivie"; // suivie, canaux, societe

  // Couleurs Mattermost
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostDarkBlue = Color(0xFF0B2340);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);
  static const Color mattermostGreen = Color(0xFF28A745);

  // Données dynamiques
  List<UserModel> _followersUsers = [];
  List<abonnement_service.AbonnementModel> _subscribersAbonnements = [];
  Set<int> _subscriberUserIds = {};
  bool _isLoadingUsers = false;

  List<GroupeModel> _mesGroupes = [];
  bool _isLoadingGroupes = false;

  List<SocieteModel> _suivieSocietes = [];
  bool _isLoadingSocietes = false;

  @override
  void initState() {
    super.initState();
    _loadMyRelations();
  }

  /// Charge MES relations selon l'onglet actif
  Future<void> _loadMyRelations() async {
    switch (selectedTab) {
      case "suivie":
        await _loadFollowersAndSubscribers();
        break;
      case "canaux":
        await _loadMesGroupes();
        break;
      case "societe":
        await _loadSuivieSocietes();
        break;
    }
  }

  // Charger les users qui suivent la société (gratuit) + les abonnés premium
  Future<void> _loadFollowersAndSubscribers() async {
    setState(() => _isLoadingUsers = true);

    try {
      // 0. Récupérer l'ID de la société connectée
      final maSociete = await SocieteAuthService.getMe();
      final maSocieteId = maSociete.id;

      // 1. Récupérer les abonnés premium (utilisateurs avec abonnement actif)
      List<abonnement_service.AbonnementModel> abonnements = [];
      Set<int> subscriberUserIds = {};
      try {
        abonnements = await abonnement_service.AbonnementAuthService.getActiveSubscribers();
        subscriberUserIds = abonnements.map((a) => a.userId).toSet();
      } catch (e) {
        debugPrint('Erreur chargement abonnés: $e');
      }

      // 2. Récupérer les followers gratuits (users qui suivent la société)
      List<Map<String, dynamic>> followersData = [];
      try {
        followersData = await SuivreAuthService.getFollowers(
          entityId: maSocieteId,
          entityType: EntityType.societe,
        );
      } catch (e) {
        debugPrint('Erreur chargement followers: $e');
      }

      // 3. Combiner les IDs des users (followers + abonnés)
      Set<int> allUserIds = {
        ...followersData.map((f) => f['user_id'] as int),
        ...subscriberUserIds,
      };

      // 4. Charger les profils de tous les utilisateurs
      List<UserModel> users = [];
      for (var userId in allUserIds) {
        try {
          final user = await UserAuthService.getUserProfile(userId);
          users.add(user);
        } catch (e) {
          debugPrint('Erreur chargement user $userId: $e');
        }
      }

      if (mounted) {
        setState(() {
          _followersUsers = users;
          _subscribersAbonnements = abonnements;
          _subscriberUserIds = subscriberUserIds;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur globale chargement users: $e');
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Charger les groupes CRÉÉS par la société (pas ceux dont elle est membre)
  Future<void> _loadMesGroupes() async {
    setState(() => _isLoadingGroupes = true);

    try {
      // Récupérer l'ID de la société connectée
      final maSociete = await SocieteAuthService.getMe();
      final maSocieteId = maSociete.id;

      // Récupérer tous les groupes
      final tousLesGroupes = await GroupeAuthService.getMyGroupes();

      // Filtrer pour ne garder que les groupes créés par cette société
      final groupesCrees = tousLesGroupes.where((groupe) {
        return groupe.createdByType == 'Societe' && groupe.createdById == maSocieteId;
      }).toList();

      if (mounted) {
        setState(() {
          _mesGroupes = groupesCrees;
          _isLoadingGroupes = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement groupes: $e');
      if (mounted) {
        setState(() => _isLoadingGroupes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Charger les sociétés que cette société suit
  Future<void> _loadSuivieSocietes() async {
    setState(() => _isLoadingSocietes = true);

    try {
      final suivis = await SuivreAuthService.getMyFollowing(
        type: EntityType.societe,
      );

      List<SocieteModel> societes = [];
      for (var suivi in suivis) {
        try {
          final societe = await SocieteAuthService.getSocieteProfile(suivi.followedId);
          societes.add(societe);
        } catch (e) {
          debugPrint('Erreur chargement société ${suivi.followedId}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _suivieSocietes = societes;
          _isLoadingSocietes = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement sociétés suivies: $e');
      if (mounted) {
        setState(() => _isLoadingSocietes = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mattermostGray,
      appBar: AppBar(
        backgroundColor: mattermostBlue,
        elevation: 0,
        title: const Text(
          "Services",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GlobalSearchPage(),
                ),
              );
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Boutons de services en haut (petits, arrondis)
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   color: Colors.white,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //     children: [
          //       _buildServiceButton("Vocal", Icons.mic, () {
          //         _showServiceDialog("Vocal");
          //       }),
          //       _buildServiceButton("Texte", Icons.edit_note, () {
          //         _showServiceDialog("Texte");
          //       }),
          //       _buildServiceButton("Image", Icons.image, () {
          //         _showServiceDialog("Image");
          //       }),
          //       _buildServiceButton("Galerie", Icons.photo_library, () {
          //         _showServiceDialog("Galerie");
          //       }),
          //     ],
          //   ),
          // ),

          // Sélecteur d'onglets (Suivie, Canaux, Société)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabOption("Suivie", "suivie", Icons.people),
                const SizedBox(width: 8),
                _buildTabOption("Canaux", "canaux", Icons.tag),
                const SizedBox(width: 8),
                _buildTabOption("Société", "societe", Icons.business),
              ],
            ),
          ),

          // Contenu selon l'onglet sélectionné
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildTabContent(),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Widget pour les petits boutons de service
  // Widget _buildServiceButton(String label, IconData icon, VoidCallback onTap) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //       decoration: BoxDecoration(
  //         color: mattermostBlue,
  //         borderRadius: BorderRadius.circular(20), // Petit et arrondi
  //         boxShadow: [
  //           BoxShadow(
  //             color: mattermostBlue.withOpacity(0.3),
  //             blurRadius: 4,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(
  //             icon,
  //             color: Colors.white,
  //             size: 16,
  //           ),
  //           const SizedBox(width: 6),
  //           Text(
  //             label,
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 12,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget pour les onglets (Suivie, Canaux, Société)
  Widget _buildTabOption(String label, String value, IconData icon) {
    final isSelected = selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = value);
          _loadMyRelations(); // Charger les données
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? mattermostBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : mattermostDarkBlue,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : mattermostDarkBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Contenu selon l'onglet sélectionné
  Widget _buildTabContent() {
    switch (selectedTab) {
      case "suivie":
        return _buildCollaborateursList();
      case "canaux":
        return _buildCanauxList();
      case "societe":
        return _buildSocietesList();
      default:
        return const Center(child: Text("Contenu non disponible"));
    }
  }

  // Liste des collaborateurs (onglet Suivie)
  Widget _buildCollaborateursList() {
    if (_isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xffFFA500)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Utilisateurs (${_followersUsers.length})",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: mattermostDarkBlue,
                  ),
                ),
              ),
              if (_subscribersAbonnements.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffFFD700), Color(0xffFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${_subscribersAbonnements.length} Premium',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadFollowersAndSubscribers,
            child: _followersUsers.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun utilisateur pour le moment',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: _followersUsers.length,
                    itemBuilder: (context, index) {
                      final user = _followersUsers[index];
                      return _buildUserItem(user);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// Afficher les options pour un utilisateur (Profil ou Conversation)
  void _showUserOptionsDialog(UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec photo et nom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: mattermostBlue,
                    radius: 30,
                    backgroundImage: user.profile?.getPhotoUrl() != null
                        ? NetworkImage(user.profile!.getPhotoUrl()!)
                        : null,
                    child: user.profile?.getPhotoUrl() == null
                        ? Text(
                            '${user.nom[0]}${user.prenom[0]}'.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.nom} ${user.prenom}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (user.email != null)
                          Text(
                            user.email!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: mattermostDarkGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_subscriberUserIds.contains(user.id))
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xffFFA500),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 20),
            // Option: Voir le profil
            ListTile(
              leading: const Icon(Icons.person_outline, color: mattermostBlue),
              title: const Text('Voir le profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(userId: user.id),
                  ),
                );
              },
            ),
            // Option: Envoyer un message
            ListTile(
              leading: const Icon(Icons.message_outlined, color: mattermostGreen),
              title: const Text('Envoyer un message'),
              onTap: () async {
                Navigator.pop(context);
                await _startConversation(user);
              },
            ),
            // Option: Transaction/Partenariat (seulement pour abonnés premium)
            if (_subscriberUserIds.contains(user.id))
              ListTile(
                leading: const Icon(Icons.handshake, color: Color(0xffFFA500)),
                title: const Text('Transaction / Partenariat'),
                subtitle: const Text(
                  'Gérer transactions et partenariat',
                  style: TextStyle(fontSize: 11, color: Color(0xffFFA500)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToTransactionPage(user);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Naviguer vers la page de transaction avec l'utilisateur
  void _navigateToTransactionPage(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserTransactionPage(
          userId: user.id,
          userName: '${user.prenom} ${user.nom}',
          themeColor: mattermostBlue,
        ),
      ),
    );
  }

  /// Démarrer une conversation avec un utilisateur
  Future<void> _startConversation(UserModel user) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Créer ou récupérer la conversation
      final conversation = await ConversationService.createOrGetConversation(
        CreateConversationDto(
          participantId: user.id,
          participantType: 'User',
        ),
      );

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Naviguer vers la page de conversation
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailPage(
              conversationId: conversation.id,
              participantName: '${user.nom} ${user.prenom}',
            ),
          ),
        );
      }
    } catch (e) {
      // Fermer le loader si ouvert
      if (mounted) Navigator.pop(context);

      // Afficher l'erreur
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

  // Item utilisateur avec indication premium
  Widget _buildUserItem(UserModel user) {
    final bool isPremium = _subscriberUserIds.contains(user.id);
    final String initials = '${user.nom[0]}${user.prenom[0]}'.toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: isPremium
          ? BoxDecoration(
              border: Border.all(
                color: const Color(0xffFFA500).withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: mattermostBlue,
              radius: 24,
              backgroundImage: user.profile?.getPhotoUrl() != null
                  ? NetworkImage(user.profile!.getPhotoUrl()!)
                  : null,
              child: user.profile?.getPhotoUrl() == null
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (isPremium)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xffFFA500),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${user.nom} ${user.prenom}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            if (isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffFFD700), Color(0xffFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 10),
                    SizedBox(width: 2),
                    Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.email != null)
              Text(
                user.email!,
                style: const TextStyle(color: mattermostDarkGray, fontSize: 12),
              ),
            if (user.profile?.bio != null) ...[
              const SizedBox(height: 2),
              Text(
                user.profile!.bio!,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        onTap: () => _showUserOptionsDialog(user),
      ),
    );
  }

  // Liste des canaux
  Widget _buildCanauxList() {
    if (_isLoadingGroupes) {
      return const Center(
        child: CircularProgressIndicator(color: mattermostBlue),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Canaux (${_mesGroupes.length})",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: mattermostDarkBlue,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMesGroupes,
            child: _mesGroupes.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun groupe créé',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Créez des groupes pour vos abonnés',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: _mesGroupes.length,
                    itemBuilder: (context, index) {
                      final groupe = _mesGroupes[index];
                      return _buildGroupeItem(groupe);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // Item groupe/canal
  Widget _buildGroupeItem(GroupeModel groupe) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: mattermostBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: groupe.profil?.getLogoUrl() != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    groupe.profil!.getLogoUrl()!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.tag, color: mattermostBlue, size: 20);
                    },
                  ),
                )
              : const Icon(Icons.tag, color: mattermostBlue, size: 20),
        ),
        title: Text(
          groupe.nom,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${groupe.membresCount ?? 0} membres • ${groupe.type.value}",
              style: const TextStyle(color: mattermostDarkGray, fontSize: 12),
            ),
            if (groupe.profil?.description != null) ...[
              const SizedBox(height: 2),
              Text(
                groupe.profil!.description!,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        onTap: () {
          // Navigation vers le groupe
        },
      ),
    );
  }

  // Liste des sociétés
  Widget _buildSocietesList() {
    if (_isLoadingSocietes) {
      return const Center(
        child: CircularProgressIndicator(color: mattermostBlue),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Sociétés (${_suivieSocietes.length})",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: mattermostDarkBlue,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSuivieSocietes,
            child: _suivieSocietes.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucune société suivie',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: _suivieSocietes.length,
                    itemBuilder: (context, index) {
                      final societe = _suivieSocietes[index];
                      return _buildSocieteItemDynamic(societe);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // Item société dynamique
  Widget _buildSocieteItemDynamic(SocieteModel societe) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: mattermostBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: societe.profile?.getLogoUrl() != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    societe.profile!.getLogoUrl()!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.business, color: Colors.white, size: 20);
                    },
                  ),
                )
              : const Icon(Icons.business, color: Colors.white, size: 20),
        ),
        title: Text(
          societe.nom,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              societe.secteurActivite ?? 'Secteur non spécifié',
              style: const TextStyle(color: mattermostDarkGray, fontSize: 12),
            ),
            if (societe.profile?.description != null) ...[
              const SizedBox(height: 2),
              Text(
                societe.profile!.description!,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        onTap: () {
          // Navigation vers le profil de la société
        },
      ),
    );
  }

  // Dialog pour les services
  // void _showServiceDialog(String service) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Service $service"),
  //         content: Text("Vous avez sélectionné le service $service"),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text("Fermer"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               // Logique pour utiliser le service
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: mattermostBlue,
  //             ),
  //             child:
  //                 const Text("Utiliser", style: TextStyle(color: Colors.white)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

}
