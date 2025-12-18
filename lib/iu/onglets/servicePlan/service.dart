import 'package:flutter/material.dart';
import 'package:gestauth_clean/iu/onglets/recherche/global_search_page.dart';
import 'package:gestauth_clean/services/suivre/suivre_auth_service.dart';
import 'package:gestauth_clean/services/suivre/abonnement_auth_service.dart' as abonnement_service;
import 'package:gestauth_clean/services/groupe/groupe_service.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/iu/onglets/recherche/user_profile_page.dart';
import 'package:gestauth_clean/iu/onglets/recherche/societe_profile_page.dart';
import 'package:gestauth_clean/groupe/groupe_detail_page.dart';
import 'package:gestauth_clean/services/messagerie/conversation_service.dart';
import 'package:gestauth_clean/messagerie/conversation_detail_page.dart';
import 'package:gestauth_clean/iu/onglets/servicePlan/transaction.dart';

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

  // Données dynamiques chargées depuis le backend
  List<UserModel> _suivieUsers = [];
  List<GroupeModel> _mesGroupes = [];
  List<SocieteModel> _suivieSocietes = [];
  List<abonnement_service.AbonnementModel> _mesAbonnements = [];
  Set<int> _societeIdsAbonnees = {}; // IDs des sociétés avec abonnement premium

  // États de chargement
  bool _isLoadingSuivie = false;
  bool _isLoadingCanaux = false;
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
        await _loadSuivieUsers();
        break;
      case "canaux":
        await _loadMesGroupes();
        break;
      case "societe":
        await _loadSuivieSocietes();
        break;
    }
  }

  /// Charger les users que je suis
  Future<void> _loadSuivieUsers() async {
    setState(() => _isLoadingSuivie = true);

    try {
      // Récupérer les relations de suivi
      final suivis = await SuivreAuthService.getMyFollowing(
        type: EntityType.user,
      );

      // Charger les détails des users
      List<UserModel> users = [];
      for (var suivi in suivis) {
        try {
          final user = await UserAuthService.getUserProfile(suivi.followedId);
          users.add(user);
        } catch (e) {
          // Ignorer les erreurs individuelles
          debugPrint('Erreur chargement user ${suivi.followedId}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _suivieUsers = users;
          _isLoadingSuivie = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSuivie = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Charger mes groupes
  Future<void> _loadMesGroupes() async {
    setState(() => _isLoadingCanaux = true);

    try {
      final groupes = await GroupeAuthService.getMyGroupes();

      if (mounted) {
        setState(() {
          _mesGroupes = groupes;
          _isLoadingCanaux = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCanaux = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Charger les sociétés que je suis ET mes abonnements premium
  Future<void> _loadSuivieSocietes() async {
    setState(() => _isLoadingSocietes = true);

    try {
      // 1. Récupérer les abonnements actifs (premium)
      List<abonnement_service.AbonnementModel> abonnements = [];
      Set<int> societeIdsAbonnees = {};
      try {
        abonnements = await abonnement_service.AbonnementAuthService.getActiveSubscriptions();
        societeIdsAbonnees = abonnements.map((a) => a.societeId).toSet();
      } catch (e) {
        debugPrint('Erreur chargement abonnements: $e');
      }

      // 2. Récupérer les relations de suivi gratuit
      final suivis = await SuivreAuthService.getMyFollowing(
        type: EntityType.societe,
      );

      // 3. Combiner les IDs des sociétés (suivies + abonnées)
      Set<int> allSocieteIds = {...suivis.map((s) => s.followedId), ...societeIdsAbonnees};

      // 4. Charger les détails des sociétés
      List<SocieteModel> societes = [];
      for (var societeId in allSocieteIds) {
        try {
          final societe = await SocieteAuthService.getSocieteProfile(societeId);
          societes.add(societe);
        } catch (e) {
          debugPrint('Erreur chargement société $societeId: $e');
        }
      }

      if (mounted) {
        setState(() {
          _suivieSocietes = societes;
          _mesAbonnements = abonnements;
          _societeIdsAbonnees = societeIdsAbonnees;
          _isLoadingSocietes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSocietes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        return _buildSuivieList();
      case "canaux":
        return _buildCanauxList();
      case "societe":
        return _buildSocietesList();
      default:
        return const Center(child: Text("Contenu non disponible"));
    }
  }

  // Liste des users que je suis (onglet Suivie)
  Widget _buildSuivieList() {
    if (_isLoadingSuivie) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suivieUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Aucun utilisateur suivi',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Recherchez des utilisateurs à suivre',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Utilisateurs suivis (${_suivieUsers.length})",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: mattermostDarkBlue,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSuivieUsers,
            child: ListView.builder(
              itemCount: _suivieUsers.length,
              itemBuilder: (context, index) {
                final user = _suivieUsers[index];
                return _buildUserItem(user);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Item user
  Widget _buildUserItem(UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mattermostBlue,
          radius: 24,
          backgroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null
              ? Text(
                  user.nom.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.nom,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          user.email ?? '',
          style: const TextStyle(fontSize: 12, color: mattermostDarkGray),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(userId: user.id),
            ),
          );
        },
      ),
    );
  }

  // Liste des groupes (canaux)
  Widget _buildCanauxList() {
    if (_isLoadingCanaux) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mesGroupes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Aucun groupe rejoint',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rejoignez des groupes pour collaborer',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Mes groupes (${_mesGroupes.length})",
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
            child: ListView.builder(
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

  // Item groupe
  Widget _buildGroupeItem(GroupeModel groupe) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: mattermostBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.group, color: mattermostBlue, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                groupe.nom,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              groupe.type == GroupeType.public ? Icons.public : Icons.lock,
              size: 14,
              color: mattermostDarkGray,
            ),
          ],
        ),
        subtitle: Text(
          groupe.description ?? 'Pas de description',
          style: const TextStyle(fontSize: 12, color: mattermostDarkGray),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${groupe.membresCount ?? 0} membres',
          style: const TextStyle(fontSize: 11, color: mattermostDarkGray),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupeDetailPage(groupeId: groupe.id),
            ),
          );
        },
      ),
    );
  }

  // Liste des sociétés
  Widget _buildSocietesList() {
    if (_isLoadingSocietes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suivieSocietes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Aucune société suivie',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Suivez des sociétés pour rester informé',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
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
                  "Sociétés (${_suivieSocietes.length})",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: mattermostDarkBlue,
                  ),
                ),
              ),
              if (_mesAbonnements.isNotEmpty)
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
                        '${_mesAbonnements.length} Premium',
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
            onRefresh: _loadSuivieSocietes,
            child: ListView.builder(
              itemCount: _suivieSocietes.length,
              itemBuilder: (context, index) {
                final societe = _suivieSocietes[index];
                return _buildSocieteItem(societe);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Afficher les options pour une société (Profil ou Conversation)
  void _showSocieteOptionsDialog(SocieteModel societe) {
    final bool isPremium = _societeIdsAbonnees.contains(societe.id);

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
            // Header avec logo et nom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: mattermostBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: societe.profile?.logo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              societe.profile!.logo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.business,
                                    color: Colors.white, size: 30);
                              },
                            ),
                          )
                        : const Icon(Icons.business, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          societe.nom,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (societe.secteurActivite != null)
                          Text(
                            societe.secteurActivite!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: mattermostDarkGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xffFFA500),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 20),
            // Option: Voir le profil
            ListTile(
              leading: const Icon(Icons.business_outlined, color: mattermostBlue),
              title: const Text('Voir le profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SocieteProfilePage(societeId: societe.id),
                  ),
                );
              },
            ),
            // Option: Envoyer un message (seulement si abonné premium)
            if (isPremium)
              ListTile(
                leading: const Icon(Icons.message_outlined, color: mattermostGreen),
                title: const Text('Envoyer un message'),
                subtitle: const Text(
                  'Disponible avec abonnement premium',
                  style: TextStyle(fontSize: 11, color: Color(0xffFFA500)),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _startConversationWithSociete(societe);
                },
              )
            else
              ListTile(
                leading: Icon(Icons.message_outlined, color: Colors.grey[400]),
                title: const Text(
                  'Envoyer un message',
                  style: TextStyle(color: Colors.grey),
                ),
                subtitle: const Text(
                  'Nécessite un abonnement premium',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                enabled: false,
              ),
            // Option: Transaction/Partenariat (seulement si abonné premium)
            if (isPremium)
              ListTile(
                leading: const Icon(Icons.handshake, color: Color(0xffFFA500)),
                title: const Text('Transaction / Partenariat'),
                subtitle: const Text(
                  'Consulter transactions et partenariat',
                  style: TextStyle(fontSize: 11, color: Color(0xffFFA500)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToTransactionPageForSociete(societe);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Démarrer une conversation avec une société (User → Société)
  Future<void> _startConversationWithSociete(SocieteModel societe) async {
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
          participantId: societe.id,
          participantType: 'Societe',
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
              participantName: societe.nom,
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

  /// Naviguer vers la page Transaction/Partenariat pour une société
  void _navigateToTransactionPageForSociete(SocieteModel societe) {
    // Naviguer vers la page de détails du partenariat
    // Note: pagePartenaritId doit être récupéré depuis le backend
    // Pour l'instant, on utilise l'ID de la société comme placeholder
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartenaireDetailsPage(
          pagePartenaritId: societe.id, // TODO: Récupérer le vrai ID de page partenariat
          partenaireName: societe.nom,
          themeColor: mattermostBlue,
        ),
      ),
    );
  }

  // Item société
  Widget _buildSocieteItem(SocieteModel societe) {
    final bool isPremium = _societeIdsAbonnees.contains(societe.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: isPremium
          ? BoxDecoration(
              border: Border.all(
                color: const Color(0xffFFA500).withOpacity(0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mattermostBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: societe.profile?.logo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        societe.profile!.logo!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.business,
                              color: Colors.white, size: 20);
                        },
                      ),
                    )
                  : const Icon(Icons.business, color: Colors.white, size: 20),
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
                societe.nom,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
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
        subtitle: Text(
          societe.secteurActivite ?? 'Secteur non spécifié',
          style: const TextStyle(fontSize: 12, color: mattermostDarkGray),
        ),
        onTap: () => _showSocieteOptionsDialog(societe),
      ),
    );
  }
}
