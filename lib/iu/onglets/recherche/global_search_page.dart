import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/services/groupe/groupe_service.dart';
import 'user_profile_page.dart';
import 'societe_profile_page.dart';

/// Page de recherche globale pour Users, Groupes et Sociétés
/// Utilise l'autocomplétion en temps réel avec debouncing
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // State
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _debounce;

  // Résultats de recherche
  List<UserModel> _userResults = [];
  List<GroupeModel> _groupeResults = [];
  List<SocieteModel> _societeResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Écoute les changements du champ de recherche avec debouncing
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Attend 500ms après que l'utilisateur arrête de taper
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.length >= 2) {
        // Minimum 2 caractères pour lancer la recherche
        _performSearch(query);
      } else {
        setState(() {
          _userResults = [];
          _groupeResults = [];
          _societeResults = [];
        });
      }
    });
  }

  /// Effectue la recherche dans les 3 catégories
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      // Recherche en parallèle pour optimiser les performances
      final results = await Future.wait([
        UserAuthService.autocomplete(query),
        GroupeAuthService.searchGroupes(query: query, limit: 20),
        SocieteAuthService.autocomplete(query),
      ]);

      if (mounted) {
        setState(() {
          _userResults = results[0] as List<UserModel>;
          _groupeResults = results[1] as List<GroupeModel>;
          _societeResults = results[2] as List<SocieteModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur de recherche: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de recherche: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
        backgroundColor: const Color(0xff5ac18e),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Users (${_userResults.length})',
              icon: const Icon(Icons.person),
            ),
            Tab(
              text: 'Groupes (${_groupeResults.length})',
              icon: const Icon(Icons.group),
            ),
            Tab(
              text: 'Sociétés (${_societeResults.length})',
              icon: const Icon(Icons.business),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),

          // Résultats avec onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserResults(),
                _buildGroupeResults(),
                _buildSocieteResults(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Barre de recherche avec autocomplétion
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Rechercher des utilisateurs, groupes ou sociétés...',
          prefixIcon: const Icon(Icons.search, color: Color(0xff5ac18e)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _userResults = [];
                      _groupeResults = [];
                      _societeResults = [];
                    });
                  },
                )
              : _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xff5ac18e),
                      ),
                    ),
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xff5ac18e)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xff5ac18e), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  /// Affichage des résultats Users
  Widget _buildUserResults() {
    if (_searchQuery.isEmpty) {
      return _buildEmptyState('Tapez au moins 2 caractères pour rechercher');
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userResults.isEmpty) {
      return _buildEmptyState('Aucun utilisateur trouvé pour "$_searchQuery"');
    }

    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return _buildUserCard(user);
      },
    );
  }

  /// Affichage des résultats Groupes
  Widget _buildGroupeResults() {
    if (_searchQuery.isEmpty) {
      return _buildEmptyState('Tapez au moins 2 caractères pour rechercher');
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupeResults.isEmpty) {
      return _buildEmptyState('Aucun groupe trouvé pour "$_searchQuery"');
    }

    return ListView.builder(
      itemCount: _groupeResults.length,
      itemBuilder: (context, index) {
        final groupe = _groupeResults[index];
        return _buildGroupeCard(groupe);
      },
    );
  }

  /// Affichage des résultats Sociétés
  Widget _buildSocieteResults() {
    if (_searchQuery.isEmpty) {
      return _buildEmptyState('Tapez au moins 2 caractères pour rechercher');
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_societeResults.isEmpty) {
      return _buildEmptyState('Aucune société trouvée pour "$_searchQuery"');
    }

    return ListView.builder(
      itemCount: _societeResults.length,
      itemBuilder: (context, index) {
        final societe = _societeResults[index];
        return _buildSocieteCard(societe);
      },
    );
  }

  /// Card pour un User
  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xff5ac18e),
          backgroundImage: user.profile?.photo != null
              ? NetworkImage(user.profile!.getPhotoUrl()!)
              : null,
          child: user.profile?.photo == null
              ? Text(
                  '${user.nom[0]}${user.prenom[0]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          '${user.nom} ${user.prenom}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.email != null)
              Text(
                user.email!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              user.numero,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigation vers le profil de l'utilisateur
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

  /// Card pour un Groupe
  Widget _buildGroupeCard(GroupeModel groupe) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xff5ac18e),
          backgroundImage: groupe.profil?.logo != null
              ? NetworkImage(groupe.profil!.getLogoUrl()!)
              : null,
          child: groupe.profil?.logo == null
              ? const Icon(Icons.group, color: Colors.white)
              : null,
        ),
        title: Text(
          groupe.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupe.description ?? 'Pas de description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '${groupe.type.toString().split('.').last} • ${groupe.categorie.toString().split('.').last}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xff5ac18e),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigation vers le profil du groupe
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupeProfilePage(groupeId: groupe.id),
            ),
          );
        },
      ),
    );
  }

  /// Card pour une Société
  Widget _buildSocieteCard(SocieteModel societe) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xff5ac18e),
          backgroundImage: societe.profile?.logo != null
              ? NetworkImage(societe.logoUrl!)
              : null,
          child: societe.profile?.logo == null
              ? const Icon(Icons.business, color: Colors.white)
              : null,
        ),
        title: Text(
          societe.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (societe.secteurActivite != null)
              Text(
                societe.secteurActivite!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              societe.email,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigation vers le profil de la société
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

  /// État vide
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Page de profil Groupe temporaire (TODO: créer la vraie page)
class GroupeProfilePage extends StatelessWidget {
  final int groupeId;
  const GroupeProfilePage({super.key, required this.groupeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Groupe #$groupeId'),
        backgroundColor: const Color(0xff5ac18e),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Page de profil groupe à implémenter',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Groupe ID: $groupeId',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
