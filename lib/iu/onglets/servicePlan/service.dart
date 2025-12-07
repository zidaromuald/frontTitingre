import 'package:flutter/material.dart';
import 'package:gestauth_clean/iu/onglets/recherche/global_search_page.dart';
import 'package:gestauth_clean/services/suivre/suivre_auth_service.dart';
import 'package:gestauth_clean/services/groupe/groupe_service.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/iu/onglets/recherche/user_profile_page.dart';
import 'package:gestauth_clean/iu/onglets/recherche/societe_profile_page.dart';
import 'package:gestauth_clean/groupe/groupe_detail_page.dart';

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

  /// Charger les sociétés que je suis
  Future<void> _loadSuivieSocietes() async {
    setState(() => _isLoadingSocietes = true);

    try {
      // Récupérer les relations de suivi
      final suivis = await SuivreAuthService.getMyFollowing(
        type: EntityType.societe,
      );

      // Charger les détails des sociétés
      List<SocieteModel> societes = [];
      for (var suivi in suivis) {
        try {
          final societe = await SocieteAuthService.getSocieteProfile(suivi.followedId);
          societes.add(societe);
        } catch (e) {
          // Ignorer les erreurs individuelles
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
          child: Text(
            "Sociétés suivies (${_suivieSocietes.length})",
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

  // Item société
  Widget _buildSocieteItem(SocieteModel societe) {
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
        title: Text(
          societe.nom,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          societe.secteurActivite ?? 'Secteur non spécifié',
          style: const TextStyle(fontSize: 12, color: mattermostDarkGray),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SocieteProfilePage(societeId: societe.id),
            ),
          );
        },
      ),
    );
  }
}
